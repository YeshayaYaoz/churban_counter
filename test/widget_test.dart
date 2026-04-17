import 'package:flutter_test/flutter_test.dart';
import 'package:churban_counter/main.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const ChurbanCounterApp());
    // Verify the app renders
    expect(find.text('זכר לחורבן'), findsOneWidget);
  });
}
