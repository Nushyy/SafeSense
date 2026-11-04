
import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  ShakeDetector({
    required this.onTrigger,
    this.threshold = 20,
    this.requiredShakes = 1,
    this.window = const Duration(seconds: 1),
    this.cooldown = const Duration(seconds: 3),
  });

  final void Function() onTrigger;
  final double threshold;
  final int requiredShakes;
  final Duration window;
  final Duration cooldown;

  StreamSubscription<UserAccelerometerEvent>? _subscription;

  final List<DateTime> _shakes = [];

  DateTime? _lastShake;
  DateTime? _lastTrigger;

  void start() {
    _subscription ??= userAccelerometerEventStream().listen(
      _onEvent,
      onError: (error) {
        // Some platforms do not expose accelerometer data.
        // Shake activation will remain unavailable there.
      },
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;

    _shakes.clear();
    _lastShake = null;
    _lastTrigger = null;
  }

  void _onEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x +
          event.y * event.y +
          event.z * event.z,
    );

    final now = DateTime.now();

    // Prevent repeated activation from the same shaking motion.
    if (_lastTrigger != null &&
        now.difference(_lastTrigger!) < cooldown) {
      return;
    }

    if (magnitude < threshold) {
      return;
    }

    // Avoid counting several accelerometer samples
    // from one movement as separate shakes.
    if (_lastShake != null &&
        now.difference(_lastShake!) <
            const Duration(milliseconds: 250)) {
      return;
    }

    _lastShake = now;
    _shakes.add(now);

    _shakes.removeWhere(
      (time) => now.difference(time) > window,
    );

    if (_shakes.length >= requiredShakes) {
      _lastTrigger = now;
      _shakes.clear();

      onTrigger();
    }
  }
}
