import 'package:flutter_test/flutter_test.dart';

import 'package:mycampus_mobile_app/main.dart';

void main() {
  testWidgets('Welcome screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyCampusApp());

    // Verify that welcome screen shows the app title.
    expect(find.text('MyCampus'), findsOneWidget);
    expect(find.text('Your College Community Hub'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Tap the 'Get Started' button and trigger a frame.
    await tester.tap(find.text('Get Started'));
    await tester.pump();

    // Verify that a snack bar is shown.
    expect(find.text('Welcome to MyCampus! More features coming soon.'),
        findsOneWidget);
  });
}
