import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dart:math' as math;

import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Security-themed splash: radar rings pulse around the real SafeSense
/// shield while a status bar reads "SECURITY SYSTEM INITIALIZING...",
/// then the wordmark, feature row, tagline and Continue button fade in.
/// Decorative corner lines, a dot pattern, and a glowing pin give it a
/// "security tech" feel without affecting the core animation logic.
///
/// TODO(auth-owner): once the real login screen is ready, change the
/// Continue button's destination below from '/home' to '/login'.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final statusProgress = const Interval(
            0.0,
            0.45,
            curve: Curves.easeOut,
          ).transform(t);
          final ringsIn = const Interval(
            0.1,
            0.4,
            curve: Curves.easeOut,
          ).transform(t);
          final wordmarkIn = const Interval(
            0.5,
            0.65,
            curve: Curves.easeOut,
          ).transform(t);
          final rowIn = const Interval(
            0.6,
            0.75,
            curve: Curves.easeOut,
          ).transform(t);
          final taglineIn = const Interval(
            0.7,
            0.82,
            curve: Curves.easeOut,
          ).transform(t);
          final buttonIn = const Interval(
            0.85,
            1.0,
            curve: Curves.easeOut,
          ).transform(t);
          final decorIn = const Interval(
            0.0,
            0.5,
            curve: Curves.easeOut,
          ).transform(t);

          return Stack(
            children: [
              // --- Decoration layer (behind everything) ---
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: decorIn,
                    child: CustomPaint(painter: _CornerLinesPainter()),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 160,
                child: Opacity(
                  opacity: decorIn,
                  child: CustomPaint(
                    size: const Size(70, 70),
                    painter: _DotGridPainter(),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 120,
                child: Opacity(
                  opacity: decorIn,
                  child: _GlowingPin(pulse: t),
                ),
              ),

              // --- Main content ---
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      // Status row
                      Opacity(
                        opacity: statusProgress > 0 ? 1 : 0,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Transform.rotate(
                                  angle: t * 6.283185,
                                  child: const Icon(
                                    Icons.radar,
                                    size: 14,
                                    color: AppColors.teal,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  statusProgress < 1
                                      ? 'SECURITY SYSTEM INITIALIZING...'
                                      : 'SECURITY SYSTEM VERIFIED',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: SizedBox(
                                height: 3,
                                width: 220,
                                child: LinearProgressIndicator(
                                  value: statusProgress,
                                  backgroundColor: AppColors.border,
                                  valueColor: const AlwaysStoppedAnimation(
                                    AppColors.teal,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Rings + real logo mark
                      SizedBox(
                        width: 260,
                        height: 260,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: ringsIn,
                              child: CustomPaint(
                                size: const Size(260, 260),
                                painter: _RingsPainter(rotation: t * 6.283185),
                              ),
                            ),
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.teal.withValues(
                                      alpha: 0.35 * ringsIn,
                                    ),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            Image.asset(
                              'assets/images/logo_mark.png',
                              width: 100,
                              height: 100,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Wordmark
                      Opacity(
                        opacity: wordmarkIn,
                        child: Transform.translate(
                          offset: Offset(0, (1 - wordmarkIn) * 10),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Safe',
                                  style: TextStyle(color: AppColors.navy),
                                ),
                                TextSpan(
                                  text: 'Sense',
                                  style: TextStyle(color: AppColors.teal),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Feature row: Report | Alert | Protect
                      Opacity(
                        opacity: rowIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            _FeatureChip(
                              icon: Icons.shield_outlined,
                              label: 'Report',
                            ),
                            _Divider(),
                            _FeatureChip(
                              icon: Icons.notifications_outlined,
                              label: 'Alert',
                            ),
                            _Divider(),
                            _FeatureChip(
                              icon: Icons.groups_outlined,
                              label: 'Protect',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // Tagline
                      Opacity(
                        opacity: taglineIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 1,
                              color: AppColors.border,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Text(
                              'STRONGER COMMUNITIES, SAFER TOGETHER.',
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 0.8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              width: 24,
                              height: 1,
                              color: AppColors.border,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(flex: 2),

                      // Continue button, gradient with glow
                      Opacity(
                        opacity: buttonIn,
                        child: Transform.translate(
                          offset: Offset(0, (1 - buttonIn) * 10),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(27),
                                gradient: const LinearGradient(
                                  colors: [AppColors.teal, AppColors.blue],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.teal.withValues(
                                      alpha: 0.4 * buttonIn,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(27),
                                  // TODO(auth-owner): change '/home' to '/login'
                                  // once the real login screen is built.
                                  onTap: buttonIn > 0.95
                                      ? () => context.go('/login')
                                      : null,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Continue',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.sm),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.teal),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 10),
    child: Text('|', style: TextStyle(color: AppColors.border)),
  );
}

/// Concentric dashed radar rings rotating slowly behind the logo.
class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.rotation});
  final double rotation;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    _dashedRing(
      canvas,
      center,
      130,
      10,
      AppColors.teal.withValues(alpha: 0.5),
      rotation,
    );
    _dashedRing(
      canvas,
      center,
      108,
      14,
      AppColors.blue.withValues(alpha: 0.35),
      -rotation * 1.3,
    );
    _dashedRing(
      canvas,
      center,
      86,
      8,
      AppColors.teal.withValues(alpha: 0.25),
      rotation * 0.7,
    );
  }

  void _dashedRing(
    Canvas canvas,
    Offset center,
    double radius,
    int dashCount,
    Color color,
    double rot,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final sweep = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i.isEven) continue;
      final start = i * sweep + rot;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep * 0.6,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

/// Thin diagonal accent lines in the top-left, top-right and
/// bottom-right corners of the screen, like the reference design.
class _CornerLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final strongPaint = Paint()
      ..color = AppColors.teal.withValues(alpha: 0.6)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final mediumPaint = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Top-left corner: layered diagonal strokes
    canvas.drawLine(const Offset(0, 110), const Offset(75, 35), strongPaint);
    canvas.drawLine(const Offset(0, 60), const Offset(40, 20), mediumPaint);
    canvas.drawLine(const Offset(20, 130), const Offset(55, 95), mediumPaint);

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - 80, 35),
      Offset(size.width, 115),
      strongPaint,
    );
    canvas.drawLine(
      Offset(size.width - 35, 15),
      Offset(size.width, 50),
      mediumPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(0, size.height - 130),
      Offset(60, size.height - 70),
      mediumPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width - 15, size.height - 110),
      Offset(size.width - 65, size.height - 60),
      strongPaint,
    );
    canvas.drawLine(
      Offset(size.width - 30, size.height - 160),
      Offset(size.width - 10, size.height - 130),
      mediumPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerLinesPainter oldDelegate) => false;
}

/// A loose grid of small dots, used as texture in the bottom-left corner.
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.teal.withValues(alpha: 0.4);
    const spacing = 11.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1.6, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}

/// A small glowing location pin in the bottom-right, pulsing gently.
class _GlowingPin extends StatelessWidget {
  const _GlowingPin({required this.pulse});
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final glow = 0.5 + 0.35 * math.sin(pulse * 6.283185 * 3);
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.teal.withValues(alpha: glow.clamp(0.3, 0.85)),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Icon(
            Icons.location_on,
            color: AppColors.teal.withValues(alpha: 0.9),
            size: 26,
          ),
        ],
      ),
    );
  }
}
