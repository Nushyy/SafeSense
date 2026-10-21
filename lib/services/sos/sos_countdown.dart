
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<bool> showSosCountdown(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _SosCountdownDialog(),
  );

  return result ?? false;
}

class _SosCountdownDialog extends StatefulWidget {
  const _SosCountdownDialog();

  @override
  State<_SosCountdownDialog> createState() =>
      _SosCountdownDialogState();
}

class _SosCountdownDialogState
    extends State<_SosCountdownDialog> {
  static const int _countdownSeconds = 2;

  Timer? _timer;
  int _secondsRemaining = _countdownSeconds;

  @override
  void initState() {
    super.initState();

    HapticFeedback.heavyImpact();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_secondsRemaining <= 1) {
          timer.cancel();
          Navigator.of(context).pop(true);
          return;
        }

        HapticFeedback.heavyImpact();

        setState(() {
          _secondsRemaining--;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text('SOS Activation'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Activating SOS in',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              '$_secondsRemaining',
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SOS demonstration only. '
              'No emergency alert will be sent.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Send now'),
          ),
        ],
      ),
    );
  }
}
