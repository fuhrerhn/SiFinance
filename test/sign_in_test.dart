import 'package:flutter_test/flutter_test.dart';
import 'package:tekber/app.dart';

void main() {
  testWidgets('SignInPage renders within SiFinanceApp without localization errors',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const SiFinanceApp(startScreen: AppStartScreen.signIn),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Masuk akun dan mulai kelola keuanganmu dengan lebih mudah.'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });

  testWidgets('SignInPage validates inputs and functions properly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const SiFinanceApp(startScreen: AppStartScreen.signIn),
    );
    await tester.pumpAndSettle();

    // Click Masuk without input
    final masukFinder = find.text('Masuk');
    await tester.ensureVisible(masukFinder);
    await tester.tap(masukFinder);
    await tester.pumpAndSettle();

    expect(find.text('Email harus berisi @gmail.com'), findsOneWidget);
  });
}
