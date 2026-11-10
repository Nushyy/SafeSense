import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

import '../../services/maps/map_service.dart';
import '../../services/location/location_service.dart';

import '../../components/maps/filter_chip_button.dart';

import '../../components/bottom_sheets/date_filter_sheet.dart';
import '../../components/bottom_sheets/crime_filter_sheet.dart';
import '../../components/bottom_sheets/status_filter_sheet.dart';
import '../../services/location/search_service.dart';

import '../../models/crime_marker_model.dart';
import '../../components/maps/crime_marker.dart';
import '../../components/maps/trusted_circle_marker.dart';
import '../../components/sos/sos_alert_listener.dart';

import 'area_stats_sheet.dart';
import '../sos/sos_screen.dart';

import '../../components/bottom_nav/bottom_nav_scaffold.dart';

import '../../services/location/trusted_circle_service.dart';
import '../../services/sos/sos_service.dart';
import '../../models/trusted_circle_member.dart';

import '../../services/maps/crime_map_service.dart';

class CrimeMapScreen extends StatefulWidget {
  const CrimeMapScreen({super.key});

  @override
  State<CrimeMapScreen> createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen> {
  // Crime alert settings
  static const double alertRadiusMeters = 300;
  static const int alertWindowDays = 30;

  // CONTROLLERS
  final TextEditingController searchController = TextEditingController();
  final MapController mapController = MapController();

  // SERVICES
  final TrustedCircleService trustedService = TrustedCircleService();
  final CrimeMapService crimeMapService = CrimeMapService();
  final SearchService searchService = SearchService();

  Timer? debounce;
  Timer? circleRefreshTimer;
  Timer? crimeAlertTimer;
  StreamSubscription<Position>? positionSub;

  // DATA
  List<TrustedCircleMember> trustedMembers = [];
  List<CrimeMarkerModel> crimeMarkers = [];
  List<dynamic> searchResults = [];
  List<SosAlert> activeSos = [];

  // MAP / LOCATION STATE
  bool mapReady = false;
  bool hasUserLocation = false;
  bool locationAttempted = false;
  bool crimesLoaded = false;
  bool initialViewDone = false;

  LatLng userLocation = MapService.defaultLocation;
  double currentZoom = MapService.defaultZoom;

  // Nearby-crime alerts
  final Set<String> alertedCrimeIds = {};
  String? crimeAlertMessage;
  DateTime lastLocationUpload = DateTime.fromMillisecondsSinceEpoch(0);

  // FILTER VALUES
  String selectedDate = "Last 12 Months";
  String selectedCrime = "All Crime";
  String selectedStatus = "All Status";

  @override
  void initState() {
    super.initState();
    loadLocation();
    loadTrustedMembers();
    loadCrimeMarkers();

    // Keep trusted circle positions fresh
    circleRefreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => loadTrustedMembers(),
    );
  }

  // ---------------------------------------------------------------------
  // MARKER SIZING
  // ---------------------------------------------------------------------

  double markerSizeForZoom(double zoom) {
    return ((zoom - 9) * 5 + 12).clamp(14.0, 46.0);
  }

  Marker buildCrimeMarker(CrimeMarkerModel crime, double zoom) {
    final size = markerSizeForZoom(zoom);
    final color = CrimeMarker.getColor(crime.crimeType);
    final showIcon = size >= 22;

    return Marker(
      point: crime.location,
      width: size,
      height: size,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: size < 22 ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: size * 0.2,
              spreadRadius: size * 0.05,
            ),
          ],
        ),
        child: showIcon
            ? Icon(
                CrimeMarker.getIcon(crime.crimeType),
                color: Colors.white,
                size: size * 0.55,
              )
            : null,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // CAMERA
  // ---------------------------------------------------------------------

  void moveToUserLocation() {
    if (mapReady && hasUserLocation) {
      mapController.move(userLocation, 15);
    }
  }

  void setInitialView() {
    if (initialViewDone) return;
    if (!mapReady || !locationAttempted || !crimesLoaded) return;

    initialViewDone = true;

    const distance = Distance();

    final nearby = filteredMarkers.where((c) {
      if (!hasUserLocation) return true;
      return distance.as(LengthUnit.Kilometer, userLocation, c.location) <= 25;
    }).map((c) => c.location).toList();

    final points = <LatLng>[
      if (hasUserLocation) userLocation,
      ...nearby,
    ];

    if (points.isEmpty) return;

    if (points.length == 1) {
      mapController.move(points.first, 15);
      return;
    }

    try {
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.fromLTRB(60, 200, 60, 120),
          maxZoom: 15,
        ),
      );
    } catch (e) {
      print("FIT CAMERA ERROR: $e");
      moveToUserLocation();
    }
  }

  // ---------------------------------------------------------------------
  // LOCATION
  // ---------------------------------------------------------------------

  Future<void> loadLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();

      if (position == null) {
        print("GPS LOCATION: null (permission denied or services off)");
      } else {
        print("GPS LOCATION: ${position.latitude}, ${position.longitude}");

        if (!mounted) return;

        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
          hasUserLocation = true;
        });

        lastLocationUpload = DateTime.now();
        trustedService.updateMyLocation(position.latitude, position.longitude);

        startLocationStream();
      }
    } catch (e) {
      print("LOCATION ERROR: $e");
    }

    locationAttempted = true;
    setInitialView();
    checkNearbyCrimes();
  }

  /// Live GPS: moves the blue dot, checks for nearby crimes,
  /// and keeps this user's position fresh for their circle.
  void startLocationStream() {
    positionSub?.cancel();

    try {
      positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15,
        ),
      ).listen(
        (p) {
          if (!mounted) return;

          setState(() {
            userLocation = LatLng(p.latitude, p.longitude);
            hasUserLocation = true;
          });

          checkNearbyCrimes();

          final now = DateTime.now();
          if (now.difference(lastLocationUpload).inSeconds >= 15) {
            lastLocationUpload = now;
            trustedService.updateMyLocation(p.latitude, p.longitude);
          }
        },
        onError: (e) => print("POSITION STREAM ERROR: $e"),
      );
    } catch (e) {
      print("POSITION STREAM START ERROR: $e");
    }
  }

  // ---------------------------------------------------------------------
  // NEARBY CRIME ALERTS
  // ---------------------------------------------------------------------

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t.toLocal());
    if (d.inDays >= 1) return "${d.inDays} day${d.inDays == 1 ? '' : 's'} ago";
    if (d.inHours >= 1) return "${d.inHours} h ago";
    return "recently";
  }

  void checkNearbyCrimes() {
    if (!hasUserLocation || crimeMarkers.isEmpty) return;

    const distance = Distance();
    final cutoff = DateTime.now().subtract(const Duration(days: alertWindowDays));

    final nearby = <MapEntry<CrimeMarkerModel, double>>[];

    for (final c in crimeMarkers) {
      if (alertedCrimeIds.contains(c.id)) continue;
      if (c.reportedAt.isBefore(cutoff)) continue;
      if (_norm(c.status) == _norm("Offender Dealt With")) continue;

      final meters = distance.as(LengthUnit.Meter, userLocation, c.location);

      if (meters <= alertRadiusMeters) {
        nearby.add(MapEntry(c, meters));
      }
    }

    if (nearby.isEmpty) return;

    nearby.sort((a, b) => a.value.compareTo(b.value));

    for (final e in nearby) {
      alertedCrimeIds.add(e.key.id);
    }

    final closest = nearby.first;

    final message = nearby.length == 1
        ? "${closest.key.crimeType} reported ${_ago(closest.key.reportedAt)}, about ${closest.value.round()} m from you. Stay alert and be safe."
        : "${nearby.length} recent incidents near you. Closest: ${closest.key.crimeType}, ${closest.value.round()} m away. Stay alert and be safe.";

    showCrimeAlert(message);
  }

  void showCrimeAlert(String message) {
    HapticFeedback.mediumImpact();

    crimeAlertTimer?.cancel();

    setState(() {
      crimeAlertMessage = message;
    });

    crimeAlertTimer = Timer(const Duration(seconds: 12), dismissCrimeAlert);
  }

  void dismissCrimeAlert() {
    crimeAlertTimer?.cancel();

    if (!mounted) return;

    setState(() {
      crimeAlertMessage = null;
    });
  }

  // ---------------------------------------------------------------------
  // DATA LOADING
  // ---------------------------------------------------------------------

  Future<void> loadTrustedMembers() async {
    try {
      final members = await trustedService.getTrustedMembers();

      if (!mounted) return;

      setState(() {
        trustedMembers = members;
      });
    } catch (e) {
      print("TRUSTED MEMBERS ERROR: $e");
    }
  }

  Future<void> loadCrimeMarkers() async {
    try {
      final markers = await crimeMapService.getCrimeMarkers();

      print("CRIME MARKERS COUNT: ${markers.length}");

      if (!mounted) return;

      setState(() {
        crimeMarkers = markers;
      });
    } catch (e) {
      print("CRIME MARKERS ERROR: $e");
    }

    crimesLoaded = true;
    setInitialView();
    checkNearbyCrimes();
  }

  // ---------------------------------------------------------------------
  // SEARCH
  // ---------------------------------------------------------------------

  Future<void> searchLocation(String query) async {
    if (query.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        searchResults = [];
      });
      return;
    }

    try {
      final results = await searchService.searchPlaces(query);

      if (!mounted) return;

      setState(() {
        searchResults = results;
      });
    } catch (e) {
      print("SEARCH ERROR: $e");
    }
  }

  void selectPlace(dynamic place) {
    final lat = double.parse(place["lat"].toString());
    final lon = double.parse(place["lon"].toString());

    if (mapReady) {
      mapController.move(LatLng(lat, lon), 15);
    }

    setState(() {
      searchResults = [];
      searchController.text = place["display_name"];
    });
  }

  // ---------------------------------------------------------------------
  // FILTERING
  // ---------------------------------------------------------------------

  String _norm(String? value) => (value ?? "").trim().toLowerCase();

  List<CrimeMarkerModel> get filteredMarkers {
    final now = DateTime.now();

    return crimeMarkers.where((crime) {
      if (selectedCrime != "All Crime" &&
          _norm(crime.crimeType) != _norm(selectedCrime)) {
        return false;
      }

      if (selectedStatus != "All Status" &&
          _norm(crime.status) != _norm(selectedStatus)) {
        return false;
      }

      final reported = crime.reportedAt.toLocal();

      switch (selectedDate) {
        case "Current Month":
          return reported.month == now.month && reported.year == now.year;

        case "Previous Month":
          final previousMonth = DateTime(now.year, now.month - 1);
          return reported.month == previousMonth.month &&
              reported.year == previousMonth.year;

        case "Last 12 Months":
          return reported.isAfter(now.subtract(const Duration(days: 365)));

        default:
          return true;
      }
    }).toList();
  }

  // ---------------------------------------------------------------------
  // BUILD HELPERS
  // ---------------------------------------------------------------------

  Widget trustedMemberRow(TrustedCircleMember member) {
    final live = member.location != null;

    return InkWell(
      onTap: live && mapReady
          ? () => mapController.move(member.location!, 16)
          : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: Colors.purple.shade100,
              backgroundImage: member.avatarUrl != null
                  ? NetworkImage(member.avatarUrl!)
                  : null,
              child: member.avatarUrl == null
                  ? const Icon(Icons.person, size: 16, color: Colors.purple)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                // green = sharing live location, grey = not sharing
                color: live ? Colors.green : Colors.grey.shade400,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCrimes = filteredMarkers;

    return SosAlertListener(
      onViewLocation: (lat, lng) {
        if (mapReady) mapController.move(LatLng(lat, lng), 16);
      },
      onActiveChanged: (alerts) {
        if (!mounted) return;
        setState(() {
          activeSos = alerts;
        });
      },
      child: BottomNavScaffold(
        currentIndex: 1,
        child: Stack(
          children: [
            // MAP
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: MapService.defaultLocation,
                initialZoom: MapService.defaultZoom,
                onMapReady: () {
                  mapReady = true;
                  setInitialView();
                },
                onPositionChanged: (camera, hasGesture) {
                  final zoom = camera.zoom;

                  if ((zoom - currentZoom).abs() > 0.05) {
                    setState(() {
                      currentZoom = zoom;
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: "com.safesense.app",
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        -0.8, 0.0, 0.0, 0.0, 235,
                        0.0, -0.8, 0.0, 0.0, 240,
                        0.0, 0.0, -0.8, 0.0, 255,
                        0.0, 0.0, 0.0, 1.0, 0,
                      ]),
                      child: tileWidget,
                    );
                  },
                ),

                MarkerLayer(
                  markers: [
                    // Crime markers (filtered + scaled with zoom)
                    ...visibleCrimes
                        .map((crime) => buildCrimeMarker(crime, currentZoom)),

                    // User location
                    Marker(
                      point: userLocation,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Trusted circle (with profile pictures)
                    ...trustedMembers
                        .where((m) => m.location != null)
                        .map((member) {
                      return Marker(
                        point: member.location!,
                        width: 84,
                        height: 84,
                        child: TrustedCircleMarker(
                          avatarUrl: member.avatarUrl,
                        ),
                      );
                    }),

                    // Active SOS alerts from the circle
                    ...activeSos.map((alert) {
                      return Marker(
                        point: LatLng(alert.latitude, alert.longitude),
                        width: 84,
                        height: 84,
                        child: const TrustedCircleMarker(
                          color: Colors.red,
                          fallbackIcon: Icons.warning_rounded,
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),

            // NEARBY CRIME ALERT BANNER
            if (crimeAlertMessage != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 124,
                left: 14,
                right: 14,
                child: Material(
                  color: const Color(0xFFEA580C),
                  elevation: 6,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            crimeAlertMessage!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: dismissCrimeAlert,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // SEARCH + FILTERS
            Positioned(
              top: 4,
              left: 14,
              right: 14,
              child: SafeArea(
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: "Search suburb or city",
                              prefixIcon: Icon(Icons.search),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(15),
                            ),
                            onChanged: (value) {
                              debounce?.cancel();
                              debounce = Timer(
                                const Duration(milliseconds: 500),
                                () => searchLocation(value),
                              );
                            },
                          ),
                          if (searchResults.isNotEmpty)
                            Container(
                              constraints: const BoxConstraints(
                                maxHeight: 250,
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: searchResults.length,
                                itemBuilder: (context, index) {
                                  final place = searchResults[index];

                                  return ListTile(
                                    leading: const Icon(Icons.location_on),
                                    title: Text(
                                      place["display_name"],
                                      maxLines: 2,
                                    ),
                                    onTap: () {
                                      selectPlace(place);
                                    },
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 11),

                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Date
                          FilterChipButton(
                            label: selectedDate,
                            icon: Icons.calendar_month,
                            onTap: () async {
                              final String? result =
                                  await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.white,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                ),
                                builder: (_) => DateFilterSheet(
                                  selectedDate: selectedDate,
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  selectedDate = result;
                                });
                              }
                            },
                          ),

                          const SizedBox(width: 5),

                          // Crime
                          FilterChipButton(
                            label: selectedCrime,
                            icon: Icons.local_police,
                            onTap: () async {
                              final String? result =
                                  await showModalBottomSheet<String>(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                ),
                                builder: (_) => CrimeFilterSheet(
                                  selectedCrime: selectedCrime,
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  selectedCrime = result;
                                });
                              }
                            },
                          ),

                          const SizedBox(width: 5),

                          // Status
                          FilterChipButton(
                            label: selectedStatus,
                            icon: Icons.flag_outlined,
                            onTap: () async {
                              final String? result =
                                  await showModalBottomSheet<String>(
                                context: context,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(28),
                                  ),
                                ),
                                builder: (_) => StatusFilterSheet(
                                  selectedStatus: selectedStatus,
                                ),
                              );

                              if (result != null) {
                                setState(() {
                                  selectedStatus = result;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // TRUSTED CIRCLE BOX (names + avatars)
            Positioned(
              bottom: 15,
              left: 16,
              child: Container(
                width: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    )
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Trusted Circle",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (trustedMembers.isEmpty)
                          const Text(
                            "No members yet",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ...trustedMembers.map(trustedMemberRow),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // SOS BUTTON
            Positioned(
              right: 20,
              bottom: 175,
              child: FloatingActionButton(
                heroTag: "sos",
                backgroundColor: Colors.red,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SosScreen()),
                  );
                },
                child: const Text(
                  "SOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),

            // STATS BUTTON
            Positioned(
              right: 20,
              bottom: 15,
              child: FloatingActionButton(
                heroTag: "stats",
                backgroundColor: const Color.fromARGB(255, 24, 77, 212),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AreaStatsSheet(),
                  );
                },
                child: const Icon(
                  Icons.bar_chart,
                  color: Colors.white,
                ),
              ),
            ),

            // MY LOCATION BUTTON
            Positioned(
              right: 20,
              bottom: 95,
              child: FloatingActionButton(
                heroTag: "location",
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    searchController.clear();
                    searchResults = [];
                  });

                  if (hasUserLocation) {
                    moveToUserLocation();
                  } else {
                    loadLocation();
                  }
                },
                child: const Icon(
                  Icons.my_location,
                  color: Color.fromARGB(255, 65, 105, 203),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    circleRefreshTimer?.cancel();
    crimeAlertTimer?.cancel();
    positionSub?.cancel();
    searchController.dispose();
    mapController.dispose();
    super.dispose();
  }
}