import 'package:flutter/material.dart';
import '../../components/BottomNav/bottom_nav_scaffold.dart';
import '../../theme/spacing.dart';
import 'widgets/area_status_card.dart';  
import 'widgets/quick_action_row.dart';
import 'widgets/recent_alerts_preview.dart';
import 'widgets/sos_button.dart';

/// The Home tab: map card, SOS button, quick actions, recent alerts.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 0,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: const [
          AreaStatusCard(),  
          SizedBox(height: AppSpacing.lg),
          SosButton(),
          SizedBox(height: AppSpacing.lg),
          QuickActionRow(),
          SizedBox(height: AppSpacing.lg),
          RecentAlertsPreview(),
        ],
      ),
    );
  }
}