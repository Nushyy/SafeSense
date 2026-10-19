import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

/// Detects a deliberate shake: [requiredShakes] hard movements within
/// [window]. Requiring several shakes stops false triggers from walking,
/// bumps in a taxi, or dropping the phone.
class ShakeDetector {
  ShakeDetector({
    required this.onTrigger,
    this.threshold = 20, // m/s^2. Lower = easier to trigger.
    this.requiredShakes = 3,
    this.window = const Duration(seconds: 2),
  });

  final void Function() onTrigger;
  final double threshold;
  final int requiredShakes;
  final Duration window;

  StreamSubscription<UserAccelerometerEvent>? _subscription;
  final List<DateTime> _shakes = [];
  DateTime? _lastShake;

  void start() {
    // userAccelerometer excludes gravity, so a phone lying still reads ~0.
    // onError keeps the app alive on devices with no sensor (like Chrome).
    _subscription ??= userAccelerometerEventStream().listen(
      _onEvent,
      onError: (_) {},
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void _onEvent(UserAccelerometerEvent event) {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (magnitude < threshold) return;

    final now = DateTime.now();

    // One swing produces many sensor readings, so count it only once.
    if (_lastShake != null &&
        now.difference(_lastShake!) < const Duration(milliseconds: 250)) {
      return;
    }
    _lastShake = now;

    _shakes.add(now);
    _shakes.removeWhere((time) => now.difference(time) > window);

    if (_shakes.length >= requiredShakes) {
      _shakes.clear();
      onTrigger();
    }
  }
}