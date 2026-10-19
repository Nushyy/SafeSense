import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../services/sos/sos_service.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// SOS demonstration button.
///
/// Hold for 0.6 seconds to activate a local SOS demo.
/// No emergency notifications are sent to responders.
class SosButton extends StatefulWidget {
  const SosButton({super.key});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  static const double _size = 170;
  static const Duration _holdDuration = Duration(milliseconds: 600);

  late final AnimationController _pulse;
  late final AnimationController _hold;

  bool _activating = false;

  @override
  void initState() {
    super.initState();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _hold = AnimationController(vsync: this, duration: _holdDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _activateDemo();
        }
      });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _hold.dispose();
    super.dispose();
  }

  void _startHold() {
    if (_activating) return;

    HapticFeedback.selectionClick();
    _hold.forward(from: 0);
  }

  void _cancelHold() {
    if (_hold.status != AnimationStatus.completed) {
      _hold.reset();
    }
  }

  Future<void> _activateDemo() async {
    if (_activating) return;

    _activating = true;
    HapticFeedback.heavyImpact();
    _hold.reset();

    try {
      // Creates an in-memory SOS demo alert only.
      await SosService.instance.sendAlert(trigger: 'button');

      if (!mounted) return;

      context.push('/sos-sent');
    } finally {
      _activating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: _size + 70,
          height: _size + 70,
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
                    label:
                        'SOS demonstration. Press and hold for '
                        '0.6 seconds to test the SOS interface. '
                        'No emergency alert will be sent.',
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
                                strokeWidth: 7,
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
                                    fontSize: 40,
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Demo only: hold to test SOS. '
          'No emergency alert will be sent.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// One expanding, fading ring behind the SOS button.
class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: 1 + 0.4 * progress,
      child: Container(
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.danger.withValues(alpha: 0.3 * (1 - progress)),
        ),
      ),
    );
  }
}
