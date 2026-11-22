import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tekber/features/auth/presentation/sign_up_page.dart';

void main() {
  testWidgets('SignUpPage renders according to the Sign Up design', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    await tester.pumpAndSettle();

    expect(find.text('Sign Up'), findsOneWidget);
    expect(
      find.text('Buat akun dan mulai kelola keuanganmu dengan lebih mudah.'),
      findsOneWidget,
    );
    expect(find.text('Masukkan nama lengkap'), findsOneWidget);
    expect(find.text('Masukkan email anda'), findsOneWidget);
    expect(find.text('Masukkan kata sandi anda'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi anda'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
    expect(find.text('Daftar dengan Google'), findsOneWidget);
  });

  testWidgets('SignUpPage validates empty and mismatched inputs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Nama wajib diisi'), findsOneWidget);
    expect(find.text('Email harus berisi @gmail.com'), findsOneWidget);
    expect(find.text('Kata sandi minimal 6 karakter'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi harus sama'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan nama lengkap'),
      'Raka',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan email anda'),
      'raka@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan kata sandi anda'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Konfirmasi kata sandi anda'),
      'password456',
    );
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi harus sama'), findsOneWidget);
  });

  testWidgets('SignUpPage password visibility toggles work', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tampilkan kata sandi'));
    await tester.pump();

    final passwordField = find.widgetWithText(
      TextField,
      'Masukkan kata sandi anda',
    );
    expect(tester.widget<TextField>(passwordField).obscureText, isFalse);

    await tester.tap(find.byTooltip('Tampilkan konfirmasi kata sandi'));
    await tester.pump();

    final confirmationField = find.widgetWithText(
      TextField,
      'Konfirmasi kata sandi anda',
    );
    expect(tester.widget<TextField>(confirmationField).obscureText, isFalse);
  });

  testWidgets('Valid SignUpPage form navigates to HomePage', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SignUpPage()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan nama lengkap'),
      'Raka',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan email anda'),
      'raka@gmail.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan kata sandi anda'),
      'password123',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Konfirmasi kata sandi anda'),
      'password123',
    );

    await tester.ensureVisible(find.text('Daftar'));
    await tester.tap(find.text('Daftar'));
    await tester.pumpAndSettle();

    expect(find.text('Hai Kamu!'), findsOneWidget);
  });
}
