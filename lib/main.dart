import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/app_navigator.dart';
import 'providers/theme_provider.dart';
import 'services/sos/sos_shake_listener.dart';
import 'theme/theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SafeSenseApp(),
    ),
  );
}

class SafeSenseApp extends StatelessWidget {
  const SafeSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp.router(
      title: 'SafeSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeProvider.mode,
      routerConfig: appRouter,
      // The shake listener wraps every screen, so a shake triggers SOS
      // from anywhere in the app.
      builder: (context, child) =>
          SosShakeListener(child: child ?? const SizedBox.shrink()),
    );
  }
}