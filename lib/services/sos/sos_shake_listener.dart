import 'package:flutter/material.dart';
import '../../navigation/app_navigator.dart';
import '../../navigation/root_navigator_key.dart';
import 'shake_detector.dart';
import 'sos_countdown.dart';
import 'sos_service.dart';

/// Wraps the whole app so shaking the phone triggers SOS from any
/// screen. Placed once in main.dart.
class SosShakeListener extends StatefulWidget {
  const SosShakeListener({super.key, required this.child});

  final Widget child;

  @override
  State<SosShakeListener> createState() => _SosShakeListenerState();
}

class _SosShakeListenerState extends State<SosShakeListener> {
  late final ShakeDetector _detector;
  bool _counting = false; // stops a second countdown opening on top

  @override
  void initState() {
    super.initState();
    _detector = ShakeDetector(onTrigger: _handleShake)..start();
  }

  @override
  void dispose() {
    _detector.stop();
    super.dispose();
  }

  Future<void> _handleShake() async {
    // Ignore shakes while a countdown is open or an alert is already live.
    if (_counting || SosService.instance.hasActiveAlert) return;

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    _counting = true;
    final shouldSend = await showSosCountdown(navContext);
    _counting = false;
    if (!shouldSend) return;

    await SosService.instance.sendAlert(trigger: 'shake');
    appRouter.push('/sos-sent');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}