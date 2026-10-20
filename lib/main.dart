import 'package:flutter/material.dart';
import 'theme/app_colors.dart';
import 'community/bulletin_board_screen.dart';

void main() {
  runApp(const SafeSenseApp());
}

class SafeSenseApp extends StatelessWidget {
  const SafeSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeSense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryBlue),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const BulletinBoardScreen(),
    );
  }
}