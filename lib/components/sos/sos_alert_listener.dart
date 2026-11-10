import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/sos/sos_service.dart';

/// Wrap any screen (under MaterialApp) with this to receive SOS alerts from
/// the trusted circle.
class SosAlertListener extends StatefulWidget {
  final Widget child;

  /// Called when the user taps "View location". If null, opens Google Maps.
  final void Function(double lat, double lng)? onViewLocation;

  /// Called whenever the set of active alerts changes (for drawing markers).
  final void Function(List<SosAlert> active)? onActiveChanged;

  const SosAlertListener({
    super.key,
    required this.child,
    this.onViewLocation,
    this.onActiveChanged,
  });

  @override
  State<SosAlertListener> createState() => _SosAlertListenerState();
}

class _SosAlertListenerState extends State<SosAlertListener> {
  final SosService _sos = SosService.instance;
  final Map<String, SosAlert> _active = {};
  final Set<String> _shown = {};

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final existing = await _sos.fetchActiveAlerts();

      for (final alert in existing) {
        _add(alert);
      }

      _sos.listen(onAlert: _add, onResolved: _remove);
    } catch (e) {
      print("SOS LISTENER ERROR: $e");
    }
  }

  void _add(SosAlert alert) {
    if (!mounted) return;

    _active[alert.id] = alert;
    widget.onActiveChanged?.call(_active.values.toList());

    if (_shown.add(alert.id)) {
      HapticFeedback.vibrate();
      _showAlertDialog(alert);
    }
  }

  void _remove(String id) {
    if (!mounted) return;

    _active.remove(id);
    widget.onActiveChanged?.call(_active.values.toList());
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t.toLocal());
    if (d.inMinutes < 1) return "just now";
    if (d.inHours < 1) return "${d.inMinutes} min ago";
    return "${d.inHours} h ago";
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      print("LAUNCH ERROR: $e");
    }
  }

  void _showAlertDialog(SosAlert alert) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red.shade700, size: 32),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "SOS ALERT",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: Text(
            "${alert.senderName} needs help!\nSent ${_ago(alert.createdAt)}.",
            style: const TextStyle(fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Dismiss"),
            ),
            if (alert.senderPhone != null && alert.senderPhone!.isNotEmpty)
              TextButton.icon(
                onPressed: () => _open('tel:${alert.senderPhone}'),
                icon: const Icon(Icons.call),
                label: const Text("Call"),
              ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              onPressed: () {
                Navigator.pop(ctx);

                if (widget.onViewLocation != null) {
                  widget.onViewLocation!(alert.latitude, alert.longitude);
                } else {
                  _open(
                    'https://www.google.com/maps/search/?api=1&query=${alert.latitude},${alert.longitude}',
                  );
                }
              },
              child: const Text("View location"),
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
  Widget build(BuildContext context) => widget.child;
}