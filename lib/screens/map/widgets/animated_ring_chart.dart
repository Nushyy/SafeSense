import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AnimatedRingChart extends StatefulWidget {
  final Map<String, int> statuses;

  const AnimatedRingChart({
    super.key,
    required this.statuses,
  });

  @override
  State<AnimatedRingChart> createState() => _AnimatedRingChartState();
}

class _AnimatedRingChartState extends State<AnimatedRingChart> {
  bool animate = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(milliseconds: 200),
      () {
        if (mounted) {
          setState(() {
            animate = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.statuses.values.fold(
      0,
      (sum, item) => sum + item,
    );

    final entries = widget.statuses.entries.toList();

    return SizedBox(
      height: 240,
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 48,
                startDegreeOffset: -90,
                sections: animate
                    ? entries.map((status) {
                        final percentage =
                            total == 0 ? 0 : status.value / total * 100;

                        return PieChartSectionData(
                          value: status.value.toDouble(),
                          title: "${percentage.toStringAsFixed(0)}%",
                          radius: 45,
                          color: statusColor(status.key),
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }).toList()
                    : [],
              ),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < entries.length; i++) ...[
                      StatusItem(
                        color: statusColor(entries[i].key),
                        title: entries[i].key,
                        cases: "${entries[i].value} cases",
                      ),
                      if (i != entries.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color statusColor(String status) {
    switch (status) {
      case "Still In Progress":
        return Colors.green;

      case "Under Investigation":
        return Colors.purple;

      case "Offender Dealt With":
        return Colors.orange;

      case "No Further Action":
        return Colors.blue;

      default:
        return Colors.grey;
    }
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
                ),
              ),
              Text(
                cases,
                style: TextStyle(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}