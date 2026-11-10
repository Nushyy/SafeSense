import 'package:flutter/material.dart';

/// Glowing, pulsing marker. Shows the member's profile picture
/// when available, otherwise an icon.
class TrustedCircleMarker extends StatefulWidget {
  final Color color;
  final String? avatarUrl;
  final IconData fallbackIcon;

  const TrustedCircleMarker({
    super.key,
    this.color = Colors.purple,
    this.avatarUrl,
    this.fallbackIcon = Icons.person,
  });

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
    final fallback = Center(
      child: Icon(widget.fallbackIcon, color: Colors.white, size: 20),
    );

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing ring
            Transform.scale(
              scale: 1 + t * 1.0,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity((1 - t) * 0.45),
                ),
              ),
            ),

            // Solid glowing core with avatar
            Container(
              width: 42,
              height: 42,
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
              child: ClipOval(
                child: widget.avatarUrl == null
                    ? fallback
                    : Image.network(
                        widget.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => fallback,
                        loadingBuilder: (context, child, progress) =>
                            progress == null ? child : fallback,
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}