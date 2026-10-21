import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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

import 'area_stats_sheet.dart';

import '../../components/bottom_nav/bottom_nav_scaffold.dart';

import '../../services/location/trusted_circle_service.dart';
import '../../models/trusted_circle_member.dart';

import '../../services/maps/crime_map_service.dart';
import '../../components/maps/trusted_circle_marker.dart';

class CrimeMapScreen extends StatefulWidget {
  const CrimeMapScreen({super.key});

  @override
  State<CrimeMapScreen> createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen> {
  // CONTROLLERS
  final TextEditingController searchController = TextEditingController();
  final MapController mapController = MapController();

  // SERVICES
  final TrustedCircleService trustedService = TrustedCircleService();
  final CrimeMapService crimeMapService = CrimeMapService();
  final SearchService searchService = SearchService();

  Timer? debounce;

  // DATA
  List<TrustedCircleMember> trustedMembers = [];
  List<CrimeMarkerModel> crimeMarkers = [];
  List<dynamic> searchResults = [];

  // MAP / LOCATION STATE
  bool mapReady = false;
  bool hasUserLocation = false;
  bool locationAttempted = false;
  bool crimesLoaded = false;
  bool initialViewDone = false;

  LatLng userLocation = MapService.defaultLocation;

  // Current zoom, used to scale the crime markers
  double currentZoom = MapService.defaultZoom;

  // FILTER VALUES
  String selectedDate = "Current Month";
  String selectedCrime = "All Crime";
  String selectedStatus = "All Status";

  @override
  void initState() {
    super.initState();
    loadLocation();
    loadTrustedMembers();
    loadCrimeMarkers();
  }

  // ---------------------------------------------------------------------
  // MARKER SIZING
  // ---------------------------------------------------------------------

  /// Marker diameter for a given zoom level.
  /// Tweak these numbers to taste:
  ///   zoom 9  ->  ~14px (tiny dot)
  ///   zoom 12 ->  ~27px
  ///   zoom 15 ->  ~42px
  ///   zoom 16+ -> 46px (max)
  double markerSizeForZoom(double zoom) {
    return ((zoom - 9) * 5 + 12).clamp(14.0, 46.0);
  }

  Marker buildCrimeMarker(CrimeMarkerModel crime, double zoom) {
    final size = markerSizeForZoom(zoom);
    final color = CrimeMarker.getColor(crime.crimeType);

    // Too small for an icon to be readable: show a plain dot
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

  /// Runs once, as soon as the map, the GPS attempt and the crime data
  /// are all ready. Frames the user AND nearby crimes.
  void setInitialView() {
    if (initialViewDone) return;
    if (!mapReady || !locationAttempted || !crimesLoaded) return;

    initialViewDone = true;

    const distance = Distance();

    // Only include crimes within 25 km of the user so one far-away
    // report doesn't zoom the map out to the whole country.
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

        trustedService.updateMyLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      print("LOCATION ERROR: $e");
    }

    locationAttempted = true;
    setInitialView();
  }

  // ---------------------------------------------------------------------
  // DATA LOADING
  // ---------------------------------------------------------------------

  Future<void> loadTrustedMembers() async {
    try {
      final members = await trustedService.getTrustedMembers();

      print("TRUSTED MEMBERS COUNT: ${members.length}");

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

  Widget trustedMember(String name, Color colour) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: colour,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleCrimes = filteredMarkers;

    return BottomNavScaffold(
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

              // Fires on every pan / zoom. We only rebuild when the zoom
              // actually changes, so panning stays smooth.
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

                  // Trusted circle
                  ...trustedMembers.map((member) {
                    return Marker(
                      point: member.location,
                      width: 64,
                      height: 64,
                      child: const TrustedCircleMarker(),
                    );
                  }),
                ],
              ),
            ],
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

          // TRUSTED CIRCLE
          Positioned(
            bottom: 15,
            left: 16,
            child: Container(
              width: 150,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Trusted Circle",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...trustedMembers.map((member) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: trustedMember(
                        member.name,
                        Colors.purple,
                      ),
                    );
                  }),
                ],
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
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    mapController.dispose();
    super.dispose();
  }
}