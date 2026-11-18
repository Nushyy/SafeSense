
import 'package:flutter_test/flutter_test.dart';
import 'package:safesense/main.dart';

void main() {
  testWidgets('SafeSense bulletin board loads successfully',
      (WidgetTester tester) async {

    // Launch the SafeSense application.
    await tester.pumpWidget(const SafeSenseApp());

    // Verify that the bulletin board screen is displayed.
    expect(find.text('Bulletin Board'), findsOneWidget);

    // Verify that all three location dropdowns are displayed.
    expect(find.text('Province'), findsOneWidget);
    expect(find.text('City / town'), findsOneWidget);
    expect(find.text('Suburb'), findsOneWidget);

    // Verify that the category filter is displayed.
    expect(find.text('All'), findsOneWidget);
  });
}
