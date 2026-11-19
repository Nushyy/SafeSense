import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:safesense/features/auth/screens/login_screen.dart';
import 'package:safesense/community/bulletin_board_screen.dart';

void main() {
  testWidgets('SafeSense login screen loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Community Bulletin Board loads successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: BulletinBoardScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Bulletin Board'), findsOneWidget);
    expect(find.text('Province'), findsOneWidget);
    expect(find.text('City / town'), findsOneWidget);
    expect(find.text('Suburb'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });
}
