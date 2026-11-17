
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Community
import '../../community/bulletin_board_screen.dart';

// Authentication
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';

// Administrator Dashboard
import '../../features/admin/screens/admin_dashboard_screen.dart';

// SAPS Dashboard
import '../../screens/Saps/saps_gate.dart';

// Crime Reporting
import '../../features/reporting/screens/report_incident_screen.dart';
import '../../features/reporting/screens/my_reports_screen.dart';

// Home
import '../../screens/Home/home_screen.dart';

// Splash Screen
import '../../screens/Splash/splash_screen.dart';

// SOS
import '../../navigation/root_navigator_key.dart';
import '../../screens/Sos/sos_sent_screen.dart';

// Map
import '../../screens/map/crime_map_screen.dart';

// Profile
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/notifications_screen.dart';
import '../../screens/profile/notification_inbox_screen.dart';
import '../../screens/profile/about_safesense_screen.dart';

// ---------------------------------------------------------
// SAFESENSE ROUTE AUTHORIZATION
// ---------------------------------------------------------

Future<String?> safesenseRouteGuard(
  BuildContext context,
  GoRouterState state,
) async {
  final supabase = Supabase.instance.client;
  final path = state.uri.path;
  final user = supabase.auth.currentUser;

  // Routes accessible without authentication.
  const publicRoutes = {
    '/splash',
    '/login',
    '/register',
    '/forgot-password',
    '/reset-password',
  };

  // Unauthenticated users cannot access protected routes.
  if (user == null) {
    return publicRoutes.contains(path) ? null : '/login';
  }

  // Preserve the splash screen.
  if (path == '/splash') {
    return null;
  }

  // Allow password recovery even with an existing session.
  if (path == '/forgot-password' ||
      path == '/reset-password') {
    return null;
  }

  try {
    // STEP 1: Verify Administrator privileges.
    final isAdmin =
        await supabase.rpc('is_safesense_admin') == true;

    if (isAdmin) {
      return path == '/admin' ? null : '/admin';
    }

    // STEP 2: Retrieve the authenticated user's profile.
    final profile = await supabase
        .from('profiles')
        .select('role_id, approval_status')
        .eq('id', user.id)
        .maybeSingle();

    // STEP 3: Restrict accounts without profiles.
    if (profile == null) {
      return path == '/account-status'
          ? null
          : '/account-status';
    }

    final roleId = profile['role_id'] as int?;
    final approvalStatus =
        profile['approval_status'] as String?;

    // STEP 4: Restrict pending and rejected accounts.
    if (approvalStatus != 'approved') {
      return path == '/account-status'
          ? null
          : '/account-status';
    }

    // STEP 5: Approved Citizen access.
    if (roleId == 1) {
      const citizenRoutes = {
        '/home',
        '/report',
        '/my-reports',
        '/profile',
        '/notifications',
        '/notification-inbox',
        '/about',
        '/map',
        '/alerts',
        '/safe-route',
        '/emergency-contacts',
        '/settings',
        '/settings/language',
        '/help',
        '/sos-sent',
      };

      if (citizenRoutes.contains(path)) {
        return null;
      }

      return '/home';
    }

    // STEP 6: SAPS Officer access.
    if (roleId == 6) {
      final officer = await supabase
          .from('saps_officers')
          .select('verification_status')
          .eq('user_id', user.id)
          .maybeSingle();

      // Only verified SAPS officers may enter the
      // SAPS Dashboard route.
      if (officer != null &&
          officer['verification_status'] == 'verified') {
        return path == '/saps' ? null : '/saps';
      }

      return path == '/account-status'
          ? null
          : '/account-status';
    }

    // STEP 7: Restrict unsupported roles.
    return path == '/account-status'
        ? null
        : '/account-status';
  } catch (error) {
    debugPrint(
      'SafeSense route authorization error: $error',
    );

    // Fail closed when authorization cannot be verified.
    return path == '/account-status'
        ? null
        : '/account-status';
  }
}

// ---------------------------------------------------------
// SAFESENSE APPLICATION ROUTER
// ---------------------------------------------------------

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',

    // Centralized authentication and authorization.
    redirect: safesenseRouteGuard,

    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Login
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Registration
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Forgot Password
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) =>
            const ForgotPasswordScreen(),
      ),

      // Reset Password
      GoRoute(
        path: '/reset-password',
        builder: (context, state) =>
            const ResetPasswordScreen(),
      ),

      // Community Home Dashboard
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Administrator Dashboard
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const AdminDashboardScreen(),
      ),

      // SAPS Official Dashboard
      //
      // Uses the demonstration services initialized
      // in main.dart.
      //
      // Mock cases are not real citizen reports.
      GoRoute(
        path: '/saps',
        builder: (context, state) =>
            const SapsGate(),
      ),

      // Account Approval Status
      GoRoute(
        path: '/account-status',
        builder: (context, state) =>
            const ComingSoonScreen(
          title: 'Account Awaiting Approval',
        ),
      ),

      // SOS Prototype
      GoRoute(
        path: '/sos-sent',
        builder: (context, state) => const SosSentScreen(),
      ),

      // Crime Reporting
      GoRoute(
        path: '/report',
        builder: (context, state) =>
            const ReportIncidentScreen(),
      ),

      // My Reports
      GoRoute(
        path: '/my-reports',
        builder: (context, state) =>
            const MyReportsScreen(),
      ),

      // User Profile
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Notification Preferences
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const NotificationsScreen(),
      ),

      // Notification Inbox
      GoRoute(
        path: '/notification-inbox',
        builder: (context, state) =>
            const NotificationInboxScreen(),
      ),

      // About SafeSense
      GoRoute(
        path: '/about',
        builder: (context, state) =>
            const AboutSafeSenseScreen(),
      ),

      // Crime Map
      GoRoute(
        path: '/map',
        builder: (context, state) =>
            const CrimeMapScreen(),
      ),

      // Community Bulletin Board
      GoRoute(
        path: '/alerts',
        builder: (context, state) =>
            const BulletinBoardScreen(),
      ),

      // Safe Routes
      GoRoute(
        path: '/safe-route',
        builder: (context, state) =>
            const ComingSoonScreen(
          title: 'Safe Routes',
        ),
      ),

      // Emergency Contacts
      GoRoute(
        path: '/emergency-contacts',
        builder: (context, state) =>
            const ComingSoonScreen(
          title: 'Emergency Contacts',
        ),
      ),

      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const ComingSoonScreen(
          title: 'Settings',
        ),
      ),

      // Language Settings
      GoRoute(
        path: '/settings/language',
        builder: (context, state) =>
            const ComingSoonScreen(
          title: 'Language',
        ),
      ),

      // Help
      GoRoute(
        path: '/help',
        builder: (context, state) =>
            const ComingSoonScreen(
          title: 'Help / SOS Information',
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------
// TEMPORARY SCREENS FOR FEATURES UNDER DEVELOPMENT
// ---------------------------------------------------------

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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                '$title is coming soon.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
