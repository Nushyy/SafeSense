import 'package:flutter/material.dart';
import '../../../theme/colors.dart';
import '../../../theme/spacing.dart';

/// The SOS button. Long-press (not tap) to reduce accidental triggers.
class SosButton extends StatelessWidget {
  const SosButton({super.key});

  Future<void> _triggerSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send SOS alert?'),
        content: const Text(
          'This will notify nearby community responders and police of '
          'your current location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO(alerts-owner): replace with a real call to send the alert.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SOS alert sent to nearby responders'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onLongPress: () => _triggerSos(context),
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Text(
              'SOS',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Press and hold to alert nearest community responders and police',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}