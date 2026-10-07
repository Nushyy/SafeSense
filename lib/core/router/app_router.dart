import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/reporting/screens/report_incident_screen.dart';
import '../../screens/Home/home_screen.dart';
import '../../screens/profile/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      GoRoute(
        path: '/report',
        builder: (context, state) => const ReportIncidentScreen(),
      ),

      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Features that are not integrated yet.
      GoRoute(
        path: '/map',
        builder: (context, state) => const ComingSoonScreen(
          title: 'Map',
        ),
      ),

      GoRoute(
        path: '/alerts',
        builder: (context, state) => const ComingSoonScreen(
          title: 'Community Alerts',
        ),
      ),

      GoRoute(
        path: '/safe-route',
        builder: (context, state) => const ComingSoonScreen(
          title: 'Safe Routes',
        ),
      ),

      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) => const ComingSoonScreen(
          title: 'Emergency Contacts',
        ),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const ComingSoonScreen(
          title: 'Settings',
        ),
      ),

      GoRoute(
        path: '/settings/language',
        builder: (context, state) => const ComingSoonScreen(
          title: 'Language',
        ),
      ),

      GoRoute(
        path: '/help',
        builder: (context, state) => const ComingSoonScreen(
          title: 'Help / SOS Information',
        ),
      ),
    ],
  );
}

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 64,
              ),
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