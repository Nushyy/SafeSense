import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/sos/sos_service.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// SOS demonstration confirmation screen.
///
/// The current SOS service creates an in-memory alert only.
/// No emergency notifications are sent to responders.
class SosSentScreen extends StatelessWidget {
  const SosSentScreen({super.key});

  /// Opens the device dialer with South Africa's 112 emergency number.
  Future<void> _call112(BuildContext context) async {
    bool opened = false;

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

  /// Clears the local SOS demonstration alert.
  Future<void> _cancelAlert(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear SOS demo?'),
        content: const Text(
          'This will clear the local demonstration alert. '
          'No emergency responders have been notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep demo active'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear demo'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await SosService.instance.cancelAlert(reason: 'user_marked_safe');

    if (!context.mounted) {
      return;
    }

    context.go('/home');

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('SOS demonstration cleared.')));
  }

  /// Returns to SafeSense without clearing the demo alert.
  void _backToApp(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final activatedAt =
        SosService.instance.activeAlert?.sentAt ?? DateTime.now();

    final time = TimeOfDay.fromDateTime(activatedAt).format(context);

    return Scaffold(
      backgroundColor: AppColors.danger,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // SOS demonstration icon
              const Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.info_outline,
                    color: AppColors.danger,
                    size: 56,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              const Text(
                'SOS DEMO ACTIVATED',
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
                'This is a demonstration only. '
                'No emergency alert has been sent to police '
                'or community responders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 15),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                'Demo activated at $time',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),

              const Spacer(),

              // Emergency calling remains a real phone action.
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
                  child: const Text('Clear SOS demo'),
                ),
              ),

              TextButton(
                onPressed: () => _backToApp(context),
                child: const Text(
                  'Back to app (demo stays active)',
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
