import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/colors.dart';
import '../Drawer/app_drawer.dart';
import '../Header/header.dart';

/// Wraps every main screen with the Header, Drawer and bottom tab bar.
/// A screen only passes in its own content as [child].
class BottomNavScaffold extends StatelessWidget {
  const BottomNavScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    this.title = 'SafeSense',
  });

  /// Which tab is highlighted: 0 Home, 1 Map, 2 Report, 3 Alerts, 4 Profile.
  final int currentIndex;
  final Widget child;
  final String title;

  static const _tabRoutes = ['/home', '/map', '/report', '/alerts', '/profile'];

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return; // already on this tab
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
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.campaign_outlined),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}