import 'package:flutter/material.dart';

import '../../../models/area_stats.dart';


class TopCrimesCard extends StatelessWidget {

  final List<CrimeStat> crimes;


  const TopCrimesCard({
    super.key,
    required this.crimes,
  });



  @override
  Widget build(BuildContext context) {


    final sorted = List<CrimeStat>.from(crimes)
      ..sort(
        (a, b) => b.count.compareTo(a.count),
      );



    return Container(

      margin: const EdgeInsets.symmetric(horizontal: 20),

      padding: const EdgeInsets.all(18),


      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(24),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(.05),

            blurRadius: 12,

            offset: const Offset(0, 6),

          ),

        ],

      ),



      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,


        children: [


          const Text(

            "Top Crime Categories",

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

            ),

          ),



          const SizedBox(height: 18),



          ...sorted.take(5).map((crime) {


            final maxValue =
                sorted.first.count.toDouble();


            final double progress =
              maxValue == 0
                ? 0.0
                : crime.count / maxValue;



            return Padding(

              padding: const EdgeInsets.only(bottom: 18),


              child: Column(


                crossAxisAlignment:
                    CrossAxisAlignment.start,


                children: [



                  Row(

                    children: [



                      Expanded(

                        child: Text(

                          crime.name,

                          style: const TextStyle(

                            fontWeight:
                                FontWeight.w600,

                          ),

                        ),

                      ),



                      Text(

                        crime.count.toString(),

                        style: const TextStyle(

                          fontWeight:
                              FontWeight.bold,

                        ),

                      ),

                    ],

                  ),



                  const SizedBox(height: 8),



                  ClipRRect(

                    borderRadius:
                        BorderRadius.circular(20),


                    child: LinearProgressIndicator(


                      value: progress,


                      minHeight: 8,


                      backgroundColor:
                          Colors.grey.shade200,


                      valueColor:
                          const AlwaysStoppedAnimation(

                        Color(0xFF172554),

                      ),

                    ),

                  ),


                ],

              ),

            );


          }),

        ],

      ),

    );


  }


}