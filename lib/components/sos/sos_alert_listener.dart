
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/sos/sos_service.dart';

class SosAlertListener extends StatefulWidget {
  const SosAlertListener({
    super.key,
    required this.child,
    this.onViewLocation,
    this.onActiveChanged,
  });

  final Widget child;

  final void Function(double lat, double lng)? onViewLocation;

  final void Function(List<ActiveSosAlert> active)?
      onActiveChanged;

  @override
  State<SosAlertListener> createState() =>
      _SosAlertListenerState();
}

class _SosAlertListenerState extends State<SosAlertListener> {
  final SosService _sos = SosService.instance;

  final Map<String, ActiveSosAlert> _active = {};
  final Set<String> _shown = {};

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final existing = await _sos.fetchActiveAlerts();

      if (!mounted) return;

      for (final alert in existing) {
        _add(alert);
      }

      await _sos.listen(
        onAlert: _add,
        onResolved: _remove,
      );
    } catch (e) {
      debugPrint('SOS listener error: $e');
    }
  }

  void _add(ActiveSosAlert alert) {
    if (!mounted) return;

    _active[alert.id] = alert;

    widget.onActiveChanged?.call(
      _active.values.toList(),
    );

    if (_shown.add(alert.id)) {
      HapticFeedback.vibrate();
      _showAlertDialog(alert);
    }
  }

  void _remove(String id) {
    if (!mounted) return;

    _active.remove(id);

    widget.onActiveChanged?.call(
      _active.values.toList(),
    );
  }

  Future<void> _callContact(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);

    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('SOS call error: $e');
    }
  }

  void _showAlertDialog(ActiveSosAlert alert) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
              SizedBox(width: 10),
              Text('SOS ALERT'),
            ],
          ),
          content: Text(
            '${alert.senderName ?? "A Trusted Circle member"} '
            'needs help!\n\n'
            'An emergency SOS alert has been activated.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Dismiss'),
            ),
            if (alert.senderPhone != null &&
                alert.senderPhone!.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _callContact(alert.senderPhone!);
                },
                child: const Text('Call'),
              ),
            if (alert.latitude != null &&
                alert.longitude != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();

                  widget.onViewLocation?.call(
                    alert.latitude!,
                    alert.longitude!,
                  );
                },
                child: const Text('View Location'),
              ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _sos.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
