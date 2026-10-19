import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../navigation/root_navigator_key.dart';
import 'shake_detector.dart';
import 'sos_countdown.dart';
import 'sos_service.dart';

/// Listens for device shakes throughout the SafeSense application.
///
/// The SOS functionality is currently a prototype.
/// No emergency notifications are sent to responders.
class SosShakeListener extends StatefulWidget {
  const SosShakeListener({super.key, required this.child});

  final Widget child;

  @override
  State<SosShakeListener> createState() => _SosShakeListenerState();
}

class _SosShakeListenerState extends State<SosShakeListener> {
  late final ShakeDetector _detector;

  // Prevent multiple SOS countdowns from opening simultaneously.
  bool _counting = false;

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
    // Ignore shakes while a countdown is open or an alert is active.
    if (_counting || SosService.instance.hasActiveAlert) {
      return;
    }

    final navContext = rootNavigatorKey.currentContext;

    if (navContext == null) {
      return;
    }

    _counting = true;

    try {
      // Show the SOS confirmation countdown.
      final shouldSend = await showSosCountdown(navContext);

      // Stop if the user cancels or the widget is disposed.
      if (!mounted || !shouldSend) {
        return;
      }

      // Create a local SOS demo alert.
      await SosService.instance.sendAlert(trigger: 'shake');

      if (!mounted) {
        return;
      }

      // Navigate using SafeSense's existing router.
      AppRouter.router.push('/sos-sent');
    } finally {
      // Always allow another countdown after completion or cancellation.
      _counting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
