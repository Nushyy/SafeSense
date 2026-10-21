import 'package:flutter/material.dart';

/// Solid coloured dot with a soft glow and a pulsing ring.
class TrustedCircleMarker extends StatefulWidget {
  final Color color;

  const TrustedCircleMarker({super.key, this.color = Colors.purple});

  @override
  State<TrustedCircleMarker> createState() => _TrustedCircleMarkerState();
}

class _TrustedCircleMarkerState extends State<TrustedCircleMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value; // 0 -> 1, repeating

        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring: grows and fades out
            Transform.scale(
              scale: 1 + t * 1.1,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity((1 - t) * 0.45),
                ),
              ),
            ),

            // Solid glowing core
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.7),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        );
      },
    );
  }
}