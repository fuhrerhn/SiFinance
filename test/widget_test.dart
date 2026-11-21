import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekber/app.dart';
import 'package:tekber/features/chat/presentation/chat_page.dart';

void main() {
  testWidgets('Application opens AI Chat', (WidgetTester tester) async {
    await tester.pumpWidget(const SiFinanceApp());
    await tester.pumpAndSettle();
    expect(find.text('AI Chat'), findsOneWidget);
    expect(find.text('Halo, ada yang bisa saya bantu?'), findsOneWidget);
  });

  testWidgets('Voice Logging returns to the open chatbot on a compact screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const SiFinanceApp());
    final chat = tester.state(find.byType(ChatPage));
    await tester.tap(find.byTooltip('Buka Voice Logging'));
    await tester.pumpAndSettle();

    expect(find.text('AI Voice Logging'), findsOneWidget);
    expect(find.byTooltip('Mulai rekaman'), findsOneWidget);
    await tester.tap(find.byTooltip('Buka AI Chat'));
    await tester.pumpAndSettle();

    expect(tester.state(find.byType(ChatPage)), same(chat));
    expect(find.text('AI Voice Logging'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
