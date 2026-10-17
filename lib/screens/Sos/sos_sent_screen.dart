import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/sos/sos_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Shown right after an SOS is sent, from either trigger. Primary action
/// is calling 112. Cancelling is a secondary action that asks for
/// confirmation, so a panicked tap can't switch off a real alert.
class SosSentScreen extends StatelessWidget {
  const SosSentScreen({super.key});

  Future<void> _call112(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri(scheme: 'tel', path: '112'));
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the dialer. Please dial 112 manually.'),
        ),
      );
    }
  }

  Future<void> _cancelAlert(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel the alert?'),
        content: const Text(
          'Responders will be told this was a false alarm and that you '
          'are safe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep alert active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes, I'm safe"),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // Grab the messenger first, because we leave this screen next.
    final messenger = ScaffoldMessenger.of(context);
    await SosService.instance.cancelAlert(reason: 'user_marked_safe');
    if (!context.mounted) return;
    context.go('/home');
    messenger.showSnackBar(
      const SnackBar(content: Text('Alert cancelled. Glad you are safe.')),
    );
  }

  void _backToApp(BuildContext context) {
    // The alert stays active. Pressing SOS again reopens this screen.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final sentAt = SosService.instance.activeAlert?.sentAt ?? DateTime.now();
    final time = TimeOfDay.fromDateTime(sentAt).format(context);

    return Scaffold(
      backgroundColor: AppColors.danger,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.danger,
                    size: 56,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'SOS ALERT SENT',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Nearby community responders and police have been notified '
                'of your location.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sent at $time',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              SizedBox(
                height: 64,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () => _call112(context),
                  icon: const Icon(Icons.phone, size: 26),
                  label: const Text(
                    'CALL 112',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: () => _cancelAlert(context),
                  child: const Text("I'm safe, cancel alert"),
                ),
              ),
              TextButton(
                onPressed: () => _backToApp(context),
                child: const Text(
                  'Back to app (alert stays active)',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}