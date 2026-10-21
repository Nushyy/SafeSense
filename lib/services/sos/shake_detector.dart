
import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  ShakeDetector({
    required this.onTrigger,
    this.threshold = 20,
    this.requiredShakes = 1,
    this.window = const Duration(seconds: 1),
  });

  final void Function() onTrigger;
  final double threshold;
  final int requiredShakes;
  final Duration window;

  StreamSubscription<UserAccelerometerEvent>? _subscription;

  final List<DateTime> _shakes = [];
  DateTime? _lastShake;

  void start() {
    _subscription ??= userAccelerometerEventStream().listen(
      _onEvent,
      onError: (_) {},
    );
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _shakes.clear();
    _lastShake = null;
  }

  void _onEvent(UserAccelerometerEvent event) {
    final magnitude = sqrt(
      event.x * event.x +
          event.y * event.y +
          event.z * event.z,
    );

    if (magnitude < threshold) return;

    final now = DateTime.now();

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
      _shakes.clear();
      _lastShake = null;
      onTrigger();
    }
  }
}
