import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekber/features/onboarding/presentation/onboarding_page.dart';
import 'package:tekber/features/splash/presentation/splash_page.dart';

void main() {
  testWidgets('Onboarding screen displays 1:1 elements correctly', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingPage(initialPage: 3),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Kelola Uang Lebih Cerdas'), findsOneWidget);

    // Verify Description
    expect(
      find.text(
        'Pantau pemasukan, pengeluaran, dan target keuanganmu dalam satu aplikasi yang simpel dan mudah digunakan.',
      ),
      findsOneWidget,
    );

    // Verify Buttons
    expect(find.text('Kembali'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);

    // Verify Page Indicator (4 dots exist)
    final animatedContainers = find.byType(AnimatedContainer);
    expect(animatedContainers, findsNWidgets(4));

    // Verify active dot width is 20 and inactive is 6
    final containerWidgets = tester.widgetList<AnimatedContainer>(
      animatedContainers,
    );
    final dotWidths = containerWidgets.map((c) => c.constraints?.maxWidth).toList();
    expect(dotWidths, [6.0, 6.0, 6.0, 20.0]);
  });

  testWidgets('Kembali and Lanjut buttons work in Onboarding', (
    WidgetTester tester,
  ) async {
    bool finished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingPage(
          initialPage: 3,
          onFinished: () {
            finished = true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Kembali -> moves to page 2 (Transparansi Finansial)
    await tester.tap(find.text('Kembali'));
    await tester.pumpAndSettle();
    expect(find.text('Transparansi Finansial'), findsOneWidget);

    // Tap Lanjut -> moves back to page 3 (Kelola Uang Lebih Cerdas)
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Kelola Uang Lebih Cerdas'), findsOneWidget);

    // Tap Lanjut on final page -> calls onFinished
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(finished, isTrue);
  });

  testWidgets('Splash screen displays logo and navigates to Onboarding', (
    WidgetTester tester,
  ) async {
    bool splashFinished = false;

    await tester.pumpWidget(
      MaterialApp(
        home: SplashPage(
          duration: const Duration(milliseconds: 500),
          onFinished: () {
            splashFinished = true;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('SiFinance'), findsOneWidget);

    // Wait for splash duration
    await tester.pump(const Duration(milliseconds: 600));
    expect(splashFinished, isTrue);
  });
}
