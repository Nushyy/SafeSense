import 'package:go_router/go_router.dart';
import '../screens/Home/home_screen.dart';
import '../screens/Sos/sos_sent_screen.dart';
import '../screens/Splash/splash_screen.dart';
import 'placeholder_screens.dart';
import 'root_navigator_key.dart';

/// The route table for the whole app: which path opens which screen.
/// Only the navigation owner edits this file.
final appRouter = GoRouter(
  // Lets the shake listener show the SOS countdown on top of any screen.
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

    // The 5 bottom-bar tabs. We use context.go for these, which replaces
    // the current screen instead of stacking them.
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/map', builder: (context, state) => const MapScreen()),
    GoRoute(path: '/report', builder: (context, state) => const ReportScreen()),
    GoRoute(path: '/alerts', builder: (context, state) => const AlertsScreen()),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),

    // Extra screens opened from the burger menu. We use context.push for
    // these, so the back button returns to where the user came from.
    GoRoute(
      path: '/safe-route',
      builder: (context, state) => const SafeRouteScreen(),
    ),
    GoRoute(
      path: '/emergency-contacts',
      builder: (context, state) => const EmergencyContactsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
      routes: [
        GoRoute(
          path: 'language',
          builder: (context, state) => const LanguageSettingsScreen(),
        ),
      ],
    ),
    GoRoute(path: '/help', builder: (context, state) => const HelpScreen()),

    // Shown right after an SOS is sent, from the button or from a shake.
    GoRoute(
      path: '/sos-sent',
      builder: (context, state) => const SosSentScreen(),
    ),
  ],
);