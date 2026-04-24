import 'package:flutter_test/flutter_test.dart';
import 'package:near_run/main.dart';

void main() {
  testWidgets('App boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Splash renders the brand and tagline.
    expect(find.text('NearRun'), findsOneWidget);
    expect(find.text('Run anywhere. No signal needed.'), findsOneWidget);
  });
}
