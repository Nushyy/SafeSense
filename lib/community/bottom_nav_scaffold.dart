
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../Drawer/app_drawer.dart';
import '../Header/header.dart';

/// Wraps every main screen with the Header, Drawer and bottom tab bar.
class BottomNavScaffold extends StatelessWidget {
  const BottomNavScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    this.title = 'SafeSense',
  });

  /// Tab indexes:
  /// 0 Home, 1 Map, 2 Report, 3 Community, 4 Alerts, 5 Profile.
  final int currentIndex;
  final Widget child;
  final String title;

  static const List<String> _tabRoutes = [
    '/home',
    '/map',
    '/report',
    '/alerts',
    '/profile',
  ];

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    context.go(_tabRoutes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Header(title: title),
      drawer: const AppDrawer(),
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTabTapped(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.teal,
        unselectedItemColor: AppColors.textSecondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            activeIcon: Icon(Icons.report),
            label: 'Report',
          ),
          
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            activeIcon: Icon(Icons.campaign),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
