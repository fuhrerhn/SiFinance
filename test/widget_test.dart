import 'package:flutter_test/flutter_test.dart';
import 'package:tekber/app.dart';


void main() {
  testWidgets('Chat-only mode opens AI Chat', (WidgetTester tester) async {
    await tester.pumpWidget(const SiFinanceApp(chatOnly: true));
    await tester.pumpAndSettle();
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('Halo, ada yang bisa saya bantu?'), findsOneWidget);
  });
}
