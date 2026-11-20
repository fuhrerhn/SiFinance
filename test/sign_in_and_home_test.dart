import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tekber/features/auth/presentation/sign_in_page.dart';
import 'package:tekber/features/onboarding/presentation/onboarding_page.dart';

void main() {
  testWidgets('Onboarding Lanjut navigates to SignInPage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingPage(initialPage: 3),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Lanjut on last page
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    // Expect to find Sign In screen
    expect(find.text('Sign In'), findsOneWidget);
    expect(
      find.text('Masuk akun dan mulai kelola keuanganmu dengan lebih mudah.'),
      findsOneWidget,
    );
    expect(find.text('Masukkan email anda'), findsOneWidget);
    expect(find.text('Masukkan kata sandi anda'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
  });

  testWidgets('Password visibility toggle works via Eye Icon', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignInPage(),
      ),
    );
    await tester.pumpAndSettle();

    final passwordFieldFinder = find.widgetWithText(
      TextField,
      'Masukkan kata sandi anda',
    );
    expect(passwordFieldFinder, findsOneWidget);

    TextField passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isTrue);

    // Tap Eye Icon
    final eyeIconFinder = find.byTooltip('Tampilkan kata sandi');
    expect(eyeIconFinder, findsOneWidget);
    await tester.tap(eyeIconFinder);
    await tester.pumpAndSettle();

    // Now password should NOT be obscured
    passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isFalse);

    // Tap Eye Icon again
    final hideEyeIconFinder = find.byTooltip('Sembunyikan kata sandi');
    expect(hideEyeIconFinder, findsOneWidget);
    await tester.tap(hideEyeIconFinder);
    await tester.pumpAndSettle();

    // Now password should be obscured again
    passwordField = tester.widget<TextField>(passwordFieldFinder);
    expect(passwordField.obscureText, isTrue);
  });

  testWidgets('Validation errors trigger when invalid inputs provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignInPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter invalid email (e.g. kaka.com) like in Sign In(3).png
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan email anda'),
      'kaka.com',
    );

    // Enter short/invalid password
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan kata sandi anda'),
      '123',
    );

    // Tap Masuk button
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verify error messages match Sign In(3).png
    expect(find.text('Email harus berisi @gmail.com'), findsOneWidget);
    expect(find.text('Kata sandi yang anda masukkan salah'), findsOneWidget);
  });

  testWidgets('Valid credentials navigate to HomePage and elements render 1:1', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: SignInPage(),
      ),
    );
    await tester.pumpAndSettle();

    // Enter valid email and password
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan email anda'),
      'kaka@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan kata sandi anda'),
      'password123',
    );

    // Tap Masuk
    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();

    // Verify HomePage renders
    expect(find.text('Hai Kamu!'), findsOneWidget);
    expect(find.text('Sudah siap kelola keuangan hari ini?'), findsOneWidget);
    expect(find.text('Sisa Keuangan'), findsOneWidget);
    expect(find.text('Rp1.000.000,00'), findsOneWidget);
    expect(find.text('Pemasukan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);

    // Verify Budget Saya
    expect(find.text('Budget Saya'), findsOneWidget);
    expect(find.text('Belanja'), findsOneWidget);
    expect(find.text('Rp750.000'), findsOneWidget);
    expect(find.text('75% terpakai'), findsOneWidget);
    expect(find.text('Sisa Rp250.000'), findsOneWidget);

    // Verify Transaksi Terakhir
    expect(find.text('Transaksi Terakhir'), findsOneWidget);
    expect(find.text('Transportasi'), findsOneWidget);
    expect(find.text('-Rp 25.000'), findsOneWidget);
    expect(find.text('Kesehatan'), findsOneWidget);
    expect(find.text('-Rp 45.000'), findsOneWidget);
    expect(find.text('Makanan & Minuman'), findsOneWidget);
    expect(find.text('-Rp 100.000'), findsOneWidget);

    // Verify Bottom Navigation items
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Catat'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
    expect(find.text('Transaksi'), findsOneWidget);

    // Verify Logout returns to SignInPage
    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Masuk dengan Google navigates directly to HomePage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SignInPage(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();

    expect(find.text('Hai Kamu!'), findsOneWidget);
    expect(find.text('Rp1.000.000,00'), findsOneWidget);
  });
}
