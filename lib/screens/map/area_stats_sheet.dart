import 'package:flutter/material.dart';

import '../../services/stats/stats_service.dart';
import '../../models/area_stats.dart';

import 'widgets/stats_header.dart';
import 'widgets/animated_ring_chart.dart';
import 'widgets/status_breakdown_card.dart';
import 'widgets/top_crimes_card.dart';
import 'widgets/all_crimes_card.dart';

class AreaStatsSheet extends StatefulWidget {

  const AreaStatsSheet({super.key});


  @override
  State<AreaStatsSheet> createState() => _AreaStatsSheetState();

}



class _AreaStatsSheetState extends State<AreaStatsSheet> {


  final StatsService statsService = StatsService();


  AreaStats? stats;



  @override
  void initState() {

    super.initState();

    loadStats();

  }



  Future<void> loadStats() async {


    final result =
        await statsService.getAreaStats();


    if (!mounted) return;


    setState(() {

      stats = result;

    });


  }



  @override
  Widget build(BuildContext context) {


    if (stats == null) {

      return const SafeArea(

        child: Center(

          child: CircularProgressIndicator(),

        ),

      );

    }



    return SafeArea(

      child: Container(

        height: MediaQuery.of(context).size.height * .90,


        decoration: const BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.vertical(

            top: Radius.circular(30),

          ),

        ),



        child: SingleChildScrollView(

          physics: const BouncingScrollPhysics(),


          child: Padding(

            padding: const EdgeInsets.only(bottom: 30),



            child: Column(

              children: [



                const SizedBox(height: 12),



                // Drag handle

                Container(

                  width: 42,

                  height: 5,

                  decoration: BoxDecoration(

                    color: Colors.grey.shade300,

                    borderRadius:
                        BorderRadius.circular(20),

                  ),

                ),



                const SizedBox(height: 18),



                const Text(

                  "Area Statistics",

                  style: TextStyle(

                    fontSize: 28,

                    fontWeight: FontWeight.w700,

                    color: Colors.black,

                  ),

                ),



                const SizedBox(height: 6),



                const Text(

                  "Crime insights for your selected area",

                  style: TextStyle(

                    fontSize: 15,

                    color: Colors.grey,

                  ),

                ),



                const SizedBox(height: 25),



                StatsHeader(
                  totalIncidents: stats!.totalIncidents,
                  period: "All Time",
                ),



                const SizedBox(height: 18),



                TopCrimesCard(

                  crimes: stats!.topCrimes,

                ),



                const SizedBox(height: 18),



                AnimatedRingChart(
                  statuses: stats!.statusBreakdown,
                ),



                const SizedBox(height: 25),



                StatusBreakdownCard(

                  statuses: stats!.statusBreakdown,

                ),



                const SizedBox(height: 20),



                AllCrimesCard(

                  crimes: stats!.allCrimeTotals,

                ),



                const SizedBox(height: 40),


              ],

            ),

          ),

        ),

      ),

    );


  }


}