import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/BottomNav/bottom_nav_scaffold.dart';
import '../../theme/spacing.dart';

import 'widgets/area_status_card.dart';
import 'widgets/quick_action_row.dart';
import 'widgets/recent_alerts_preview.dart';
import 'widgets/sos_button.dart';
import 'widgets/welcome_header.dart';

/// SafeSense Home Dashboard.
///
/// Combines the personalized welcome header with the existing
/// dashboard components without changing authentication,
/// navigation, or SOS functionality.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String? _getUserName() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata;

    final fullName = metadata?['full_name'];
    if (fullName is String && fullName.trim().isNotEmpty) {
      return fullName.trim();
    }

    final firstName = metadata?['first_name'];
    if (firstName is String && firstName.trim().isNotEmpty) {
      return firstName.trim();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          WelcomeHeader(name: _getUserName()),
          const SizedBox(height: AppSpacing.lg),

          const AreaStatusCard(),
          const SizedBox(height: AppSpacing.lg),

          const SosButton(),
          const SizedBox(height: AppSpacing.lg),

          const QuickActionRow(),
          const SizedBox(height: AppSpacing.lg),

          const RecentAlertsPreview(),
        ],
      ),
    );
  }
}
