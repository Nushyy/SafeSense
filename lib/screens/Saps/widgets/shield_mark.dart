import 'package:flutter/material.dart';

import '../saps_colors.dart';

/// Our own simple shield-and-star mark. It is NOT the SAPS badge.
class ShieldMark extends StatelessWidget {
  const ShieldMark({super.key, this.size = 30});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 30 / 34,
      height: size,
      child: CustomPaint(painter: _ShieldPainter()),
    );
  }
}

class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 30;
    final sy = size.height / 34;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final shield = Path()
      ..moveTo(15 * sx, 2 * sy)
      ..lineTo(27 * sx, 7 * sy)
      ..lineTo(27 * sx, 17 * sy)
      ..cubicTo(27 * sx, 25 * sy, 21 * sx, 30 * sy, 15 * sx, 32 * sy)
      ..cubicTo(9 * sx, 30 * sy, 3 * sx, 25 * sy, 3 * sx, 17 * sy)
      ..lineTo(3 * sx, 7 * sy)
      ..close();
    canvas.drawPath(shield, Paint()..color = SapsColors.blue);
    canvas.drawPath(
      shield,
      Paint()
        ..color = SapsColors.gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * sx,
    );

    final pts = <Offset>[
      p(15, 9), p(17.2, 14), p(22.5, 14.4), p(18.5, 17.8), p(19.8, 23),
      p(15, 20.2), p(10.2, 23), p(11.5, 17.8), p(7.5, 14.4), p(12.8, 14),
    ];
    final star = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final o in pts.skip(1)) {
      star.lineTo(o.dx, o.dy);
    }
    star.close();
    canvas.drawPath(star, Paint()..color = SapsColors.gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
