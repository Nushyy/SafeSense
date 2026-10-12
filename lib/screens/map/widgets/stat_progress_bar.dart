import 'package:flutter/material.dart';

class StatProgressBar extends StatefulWidget {
  final String title;
  final int count;
  final double percentage;
  final Color color;

  const StatProgressBar({
    super.key,
    required this.title,
    required this.count,
    required this.percentage,
    required this.color,
  });

  @override
  State<StatProgressBar> createState() => _StatProgressBarState();
}

class _StatProgressBarState extends State<StatProgressBar> {
  bool animate = false;

  @override
  void initState() {
    super.initState();

    // Starts the animation after the widget appears
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          animate = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Width available for the coloured progress bar
        final double maxBarWidth = constraints.maxWidth;

        return Padding(
          padding: const EdgeInsets.only(bottom: 18),

          child: Column(
            children: [

              // ---------- Top Row ----------
              Row(
                children: [

                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Text(
                    widget.count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(width: 10),

                  SizedBox(
                    width: 48,
                    child: Text(
                      "${widget.percentage.toStringAsFixed(1)}%",
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ---------- Background Bar ----------
              Stack(
                children: [

                  Container(
                    height: 7,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  // ---------- Animated Progress ----------
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,

                    height: 7,

                    width: animate
                        ? maxBarWidth * (widget.percentage / 100)
                        : 0,

                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}