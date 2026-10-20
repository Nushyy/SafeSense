import 'package:flutter/material.dart';
import '../../components/BottomNav/bottom_nav_scaffold.dart';
import '../../theme/spacing.dart';
import 'widgets/area_status_card.dart';
import 'widgets/recent_alerts_preview.dart';
import 'widgets/sos_button.dart';
import 'widgets/sos_status_line.dart';
import 'widgets/welcome_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const String _userName = 'Mabuza';

  @override
  Widget build(BuildContext context) {
    return BottomNavScaffold(
      currentIndex: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight -
                    AppSpacing.lg -
                    AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  WelcomeHeader(name: _userName),
                  SizedBox(height: AppSpacing.md),
                  SosButton(),
                  SosStatusLine(),
                  SizedBox(height: AppSpacing.lg),
                  AreaStatusCard(),
                  SizedBox(height: AppSpacing.lg),
                  RecentAlertsPreview(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}