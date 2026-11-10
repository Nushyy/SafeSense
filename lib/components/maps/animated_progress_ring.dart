import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedProgressRing extends StatefulWidget {
  final double percentage;

  const AnimatedProgressRing({
    super.key,
    required this.percentage,
  });

  @override
  State<AnimatedProgressRing> createState() =>
      _AnimatedProgressRingState();
}

class _AnimatedProgressRingState
    extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {

  late AnimationController controller;

  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    animation = Tween<double>(
      begin: 0,
      end: widget.percentage,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutCubic,
      ),
    );

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {

        return CustomPaint(
          painter: RingPainter(animation.value),
          child: SizedBox(
            width: 170,
            height: 170,
            child: Center(
              child: Text(
                "${(animation.value * 100).round()}%",
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class RingPainter extends CustomPainter {

  final double value;

  RingPainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {

    final center = Offset(
      size.width/2,
      size.height/2,
    );

    final radius = size.width/2;

    final background = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 18
      ..style = PaintingStyle.stroke;

    final foreground = Paint()
      ..color = const Color(0xff2563EB)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(
      center,
      radius-10,
      background,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius-10,
      ),
      -pi/2,
      value*2*pi,
      false,
      foreground,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}