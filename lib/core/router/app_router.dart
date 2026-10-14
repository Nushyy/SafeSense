import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Community
import '../../community/bulletin_board_screen.dart';

// Authentication
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';

// Crime Reporting
import '../../features/reporting/screens/report_incident_screen.dart';
import '../../features/reporting/screens/my_reports_screen.dart';

// Home
import '../../screens/Home/home_screen.dart';

// Map
import '../../screens/map/crime_map_screen.dart';

// Profile
import '../../screens/profile/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      // Authentication
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Home Dashboard
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),

      // Crime Reporting
      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportIncidentScreen(),
      ),

      // My Reports
      GoRoute(
        path: '/my-reports',
        builder: (context, state) => const MyReportsScreen(),
      ),

      // User Profile
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Crime Map
      GoRoute(
        path: '/map',
        builder: (context, state) => const CrimeMapScreen(),
      ),

      // Community Bulletin Board
      GoRoute(
        path: '/alerts',
        builder: (context, state) => const BulletinBoardScreen(),
      ),

      // Safe Routes
      GoRoute(
        path: '/safe-route',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Safe Routes'),
      ),

      // Emergency Contacts
      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Emergency Contacts'),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const ComingSoonScreen(title: 'Settings'),
      ),

      // Language Settings
      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const ComingSoonScreen(title: 'Language'),
      ),

      // Help
      GoRoute(
        path: '/help',
        builder: (context, state) =>
            const ComingSoonScreen(title: 'Help / SOS Information'),
      ),
    ],
  );
}

// Placeholder for features awaiting integration
class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction_outlined, size: 64),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'This feature is currently being integrated.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
