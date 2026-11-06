import 'package:flutter_test/flutter_test.dart';
import 'package:coterie/main.dart';

void main() {
  testWidgets('Coterie museum ticket loading screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const CoterieApp());
    expect(find.text('Coterie'), findsOneWidget);
  });
}
