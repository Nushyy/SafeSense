import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../services/sos/sos_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';


class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  static const double _size = 190;
  static const Duration _holdDuration = Duration(milliseconds: 600);

  late final AnimationController _pulse;
  late final AnimationController _hold;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _hold = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _sendNow();
      });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _hold.dispose();
    super.dispose();
  }

  void _startHold() {
    HapticFeedback.selectionClick();
    _hold.forward();
  }

  void _cancelHold() {
    if (_hold.status != AnimationStatus.completed) _hold.reverse();
  }

  Future<void> _sendNow() async {
    HapticFeedback.heavyImpact();
    _hold.reset();
    await SosService.instance.sendAlert(trigger: 'button');
    if (!mounted) return;
    context.push('/sos-sent');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: _size + 80,
          height: _size + 80,
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _hold]),
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (final offset in const [0.0, 0.5])
                    _PulseRing(
                      progress: (_pulse.value + offset) % 1.0,
                      size: _size,
                    ),
                  Semantics(
                    button: true,
                    label: 'Emergency SOS. Press and hold for half a second '
                        'to send an alert immediately.',
                    child: GestureDetector(
                      onTapDown: (_) => _startHold(),
                      onTapUp: (_) => _cancelHold(),
                      onTapCancel: _cancelHold,
                      child: Container(
                        width: _size,
                        height: _size,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.danger.withValues(alpha: 0.45),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: _size - 16,
                              height: _size - 16,
                              child: CircularProgressIndicator(
                                value: _hold.value,
                                strokeWidth: 8,
                                color: Colors.white,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 44,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                Text(
                                  'HOLD',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Text(
          'Press and hold for half a second',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }
}

/// One expanding, fading ring behind the button.
class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1 + 0.4 * progress,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.danger.withValues(alpha: 0.3 * (1 - progress)),
        ),
      ),
    );
  }
}