import 'package:flutter_test/flutter_test.dart';
import 'package:tekber/app.dart';


void main() {
  testWidgets('Application opens AI Chat', (WidgetTester tester) async {
    await tester.pumpWidget(const SiFinanceApp());
    await tester.pumpAndSettle();
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('Halo, ada yang bisa saya bantu?'), findsOneWidget);
  });
}
