import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
//import 'package:geocoding/geocoding.dart';
import 'dart:async';

import '../../services/maps/map_service.dart';
import '../../services/location/location_service.dart';

//import '../../components/maps/map_search_bar.dart';
import '../../components/maps/filter_chip_button.dart';

import '../../components/bottom_sheets/date_filter_sheet.dart';

import '../../components/bottom_sheets/crime_filter_sheet.dart';
import '../../components/bottom_sheets/status_filter_sheet.dart';
import '../../services/location/search_service.dart';

// (Coming next)
// import '../../components/bottom_sheets/crime_filter_sheet.dart';
// import '../../components/bottom_sheets/status_filter_sheet.dart';
// import '../../components/maps/trusted_circle_card.dart';
// import '../../components/maps/stats_button.dart';

class CrimeMapScreen extends StatefulWidget {
  const CrimeMapScreen({super.key});

  @override
  State<CrimeMapScreen> createState() => _CrimeMapScreenState();
}

class _CrimeMapScreenState extends State<CrimeMapScreen> {
  //MAP CONTROLLER
  final TextEditingController searchController = TextEditingController();

  Timer? debounce;

  final SearchService searchService = SearchService();

  List<dynamic> searchResults = [];

  Future<void> searchLocation(String query) async {

    if(query.isEmpty){

      setState(() {
        searchResults = [];
      });

      return;
    }

    final results =
        await searchService.searchPlaces(query);

    setState(() {
      searchResults = results;
    });

  }

  void selectPlace(dynamic place){

    final lat =
        double.parse(place["lat"]);

    final lon =
        double.parse(place["lon"]);

    mapController.move(
        LatLng(lat, lon),
        15,
    );

    setState(() {

      currentLocation =
          LatLng(lat, lon);

      searchResults = [];

      searchController.text =
          place["display_name"];

    });

  }

  final MapController mapController = MapController();
  //USER LOCATION

  LatLng currentLocation = MapService.defaultLocation;
  //FILTER VALUES
  String selectedDate = "Current Month";
  String selectedCrime = "All Crime";
  String selectedStatus = "All Status";

  @override
  void initState() {
    super.initState();
    loadLocation();
  }

  //GET USER GPS LOCATION
  Future<void> loadLocation() async {
    final position = await LocationService().getCurrentLocation();

    if (position != null) {
      setState(() {
        currentLocation = LatLng(
          position.latitude,
          position.longitude,
        );
      });

      mapController.move(currentLocation, 15);
    }
  }

  //BUILD
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
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [

          //MAP
          FlutterMap(
            mapController: mapController,

            options: MapOptions(
              initialCenter: currentLocation,
              initialZoom: MapService.defaultZoom,
            ),

            children: [
              //OpenStreetMap Tiles
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                tileBuilder: (context, tileWidget, tile) {
                  return ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      // Optimized High-Contrast Dark Blue / Charcoal
                      -0.8,  0.0,  0.0, 0.0,  235,  // Red
                      0.0, -0.8,  0.0, 0.0,  240,  // Green
                      0.0,  0.0, -0.8, 0.0,  255,  // Blue (kept high for dark navy background)
                      0.0,  0.0,  0.0, 1.0,    0,  // Alpha
                    ]),
                    child: tileWidget,
                  );
                },

                userAgentPackageName:
                    "com.safesense.app",
              ),

              // Crime Markers
              // (We'll replace these with Supabase later)
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation,
                    width: 45,
                    height: 45,
                    child: const Icon(
                      Icons.adjust,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ],
              ),
            ],
          ),

          //SEARCH + FILTERS
          Positioned(
            top: 4,
            left: 14,
            right: 14,
            child: SafeArea(
              child: Column(
                children: [
                  //Search Bar
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

                            itemBuilder: (context,index){

                              final place = searchResults[index];

                              return ListTile(

                                leading: const Icon(Icons.location_on),

                                title: Text(
                                  place["display_name"],
                                  maxLines: 2,
                                ),

                                onTap: (){
                                  selectPlace(place);
                                },

                              );

                            },

                          )
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 11),


                  //Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        //Date
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

                        //Crime
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

                        //Status
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

          //TRUSTED CIRCLE
          Positioned(
            bottom: 50,
            left: 16,
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        Colors.black,
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

                  const SizedBox(height: 16),

                  trustedMember("Mom", Colors.green),

                  const SizedBox(height: 10),

                  trustedMember("Dad", Colors.blue),

                  const SizedBox(height: 10),

                  trustedMember("Sarah", Colors.purple),
                ],
              ),
            ),
          ),

          //STATS BUTTON
          Positioned(
            right: 20,
            bottom: 50,
            child: FloatingActionButton(
              heroTag: "stats",
              backgroundColor: const Color.fromARGB(255, 24, 77, 212),
              onPressed: () {

                // Stats Bottom Sheet
                // Coming next

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
            bottom: 115,
            child: FloatingActionButton(
              heroTag: "location",
              backgroundColor: Colors.white,
              onPressed: () {
                mapController.move(
                  currentLocation,
                  15,
                );
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
    super.dispose();
  }
}