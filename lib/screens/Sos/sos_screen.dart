
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/sos/sos_service.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with SingleTickerProviderStateMixin {
  final SosService sos = SosService.instance;

  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerSos();
      }
    });

  bool sending = false;
  String? error;
  ActiveSosAlert? alert;

  @override
  void initState() {
    super.initState();
    alert = sos.activeAlert;
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _triggerSos() async {
    if (sending || alert != null) return;

    HapticFeedback.heavyImpact();

    setState(() {
      sending = true;
      error = null;
    });

    try {
      final result = await sos.sendAlert(trigger: 'button');

      if (!mounted) return;

      setState(() {
        alert = result;
        sending = false;
      });
    } catch (e) {
      if (!mounted) return;

      _hold.value = 0;

      setState(() {
        sending = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _cancelAlert() async {
    try {
      await sos.cancelAlert(reason: 'User cancelled SOS alert');

      if (!mounted) return;

      setState(() {
        alert = null;
        error = null;
      });

      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Unable to cancel SOS alert: $e';
      });
    }
  }

  Future<void> _launch(String url) async {
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );

      if (!ok && mounted) {
        _snack("Couldn't open that on this device.");
      }
    } catch (_) {
      if (mounted) {
        _snack("Couldn't open that on this device.");
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _holdButton() {
    return Listener(
      onPointerDown: (_) {
        if (!sending && alert == null) {
          HapticFeedback.selectionClick();
          _hold.forward(from: 0);
        }
      },
      onPointerUp: (_) {
        if (_hold.status != AnimationStatus.completed) {
          _hold.reverse();
        }
      },
      onPointerCancel: (_) {
        if (_hold.status != AnimationStatus.completed) {
          _hold.reverse();
        }
      },
      child: AnimatedBuilder(
        animation: _hold,
        builder: (context, _) {
          return SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: _hold.value,
                    strokeWidth: 10,
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.shade800,
                    ),
                  ),
                ),
                Container(
                  width: 196,
                  height: 196,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.45),
                        blurRadius: 30,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: sending
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 54,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _idleView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Emergency SOS',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Press and hold the button for 3 seconds to send your live location to your trusted circle.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 40),
        _holdButton(),
        const SizedBox(height: 30),
        if (error != null)
          Text(
            error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        const SizedBox(height: 20),
        _actionButton(
          Icons.call,
          'Call emergency services (112)',
          () => _launch('tel:112'),
          color: Colors.grey.shade800,
        ),
      ],
    );
  }

  Widget _sentView() {
    return Column(
      children: [
        const SizedBox(height: 30),
        const Icon(
          Icons.warning_amber_rounded,
          color: Colors.red,
          size: 90,
        ),
        const SizedBox(height: 16),
        const Text(
          'SOS Alert Activated',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your SOS alert and GPS location have been saved. '
          'Delivery to your Trusted Circle has not yet been verified.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        _actionButton(
          Icons.call,
          'Call emergency services (112)',
          () => _launch('tel:112'),
        ),
        const SizedBox(height: 12),
        _actionButton(
          Icons.local_police,
          'Call SAPS (10111)',
          () => _launch('tel:10111'),
          color: Colors.indigo,
        ),
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: _cancelAlert,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
          ),
          child: const Text('End SOS Alert'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF2F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('SOS'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 30),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 160,
            ),
            child: alert == null ? _idleView() : _sentView(),
          ),
        ),
      ),
    );
  }
}
