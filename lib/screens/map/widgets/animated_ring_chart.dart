import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnimatedRingChart extends StatefulWidget {
  const AnimatedRingChart({super.key});

  @override
  State<AnimatedRingChart> createState() => _AnimatedRingChartState();
}

class _AnimatedRingChartState extends State<AnimatedRingChart> {
  bool animate = false;

  @override
  void initState() {
    super.initState();

    // Starts drawing the chart after the widget loads
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          animate = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,

      child: Row(
        children: [

          /// ---------------- Doughnut Chart ----------------
          Expanded(
            flex: 5,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 48,
                startDegreeOffset: -90,

                pieTouchData: PieTouchData(
                  enabled: false,
                ),

                sections: animate
                    ? [

                        PieChartSectionData(
                          value: 56,
                          color: Colors.blue,
                          radius: 45,
                          title: "56%",
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        PieChartSectionData(
                          value: 32,
                          color: Colors.green,
                          radius: 45,
                          title: "32%",
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),

                        PieChartSectionData(
                          value: 12,
                          color: Colors.orange,
                          radius: 45,
                          title: "12%",
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ]
                    : [],
              ),

              duration: const Duration(milliseconds: 900),

              curve: Curves.easeOutCubic,
            ),
          ),

          const SizedBox(width: 18),

          /// ---------------- Legend ----------------
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [

                StatusItem(
                  color: Colors.blue,
                  title: "No Further Action",
                  cases: "312 cases",
                ),

                SizedBox(height: 18),

                StatusItem(
                  color: Colors.green,
                  title: "Still In Progress",
                  cases: "178 cases",
                ),

                SizedBox(height: 18),

                StatusItem(
                  color: Colors.orange,
                  title: "Offender Dealt With",
                  cases: "67 cases",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatusItem extends StatelessWidget {
  final Color color;
  final String title;
  final String cases;

  const StatusItem({
    super.key,
    required this.color,
    required this.title,
    required this.cases,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [

        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),

              Text(
                cases,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}