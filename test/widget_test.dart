import 'package:flutter_test/flutter_test.dart';
import 'package:near_run/main.dart';

void main() {
  testWidgets('App boots to home', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Brand shows on the home app bar.
    expect(find.text('NearRun'), findsOneWidget);
    // Bottom nav renders all three tabs.
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('HISTORY'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
  });
}
