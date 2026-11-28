import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tekber/features/auth/data/auth_repository.dart';
import 'package:tekber/features/auth/domain/auth_state.dart';
import 'package:tekber/features/auth/presentation/auth_page.dart';
import 'package:tekber/features/budget/domain/budget_period.dart';
import 'package:tekber/features/budget/presentation/budget_page.dart';
import 'package:tekber/features/chat/presentation/chat_page.dart';
import 'package:tekber/features/dashboard/presentation/dashboard_page.dart';
import 'package:tekber/features/histori_transaksi/presentation/histori_transaksi_page.dart';
import 'package:tekber/features/home/presentation/home_page.dart';
import 'package:tekber/features/manual_logging/presentation/manual_logging_page.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));
  testWidgets('Beranda membuka fitur dan menyimpan budget demo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardPage), findsOneWidget);

    await tester.tap(find.text('Budget'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetPage), findsOneWidget);

    await tester.tap(find.text('Tambah Budget'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belanja').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '250000');
    await tester.tap(find.byType(DropdownButtonFormField<BudgetPeriod>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Setiap Bulan').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah Kategori Budget').last);
    await tester.pumpAndSettle();
    expect(find.byType(BudgetPage), findsOneWidget);
    expect(find.text('Belanja'), findsOneWidget);

    await tester.tap(find.text('Catat'));
    await tester.pumpAndSettle();
    expect(find.byType(ManualLoggingPage), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '25000');
    await tester.tap(find.text('Tentukan kategori'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Belanja'));
    await tester.pump();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();
    expect(find.byType(BudgetPage), findsOneWidget);

    expect(find.text('10% terpakai'), findsOneWidget);

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '500000');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();
    expect(find.text('5% terpakai'), findsOneWidget);

    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Belanja'), findsWidgets);

    await tester.tap(find.text('Transaksi'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoriTransaksiPage), findsOneWidget);
    expect(find.text('Histori Transaksi'), findsOneWidget);
    expect(find.byType(DashboardPage, skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('AI Chat'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatPage), findsOneWidget);

    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    expect(find.text('Hai Kamu!'), findsOneWidget);
  });

  testWidgets('Pendaftaran Supabase mengikuti sesi dan membuka Beranda', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = _TestAuthRepository();
    addTearDown(auth.states.close);
    await tester.pumpWidget(MaterialApp(home: AuthPage(repository: auth)));

    final register = find.text('Belum punya akun? Daftar', findRichText: true);
    await tester.ensureVisible(register);
    await tester.tap(register);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan nama lengkap'),
      'Raka',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Masukkan email anda'),
      'raka@example.com',
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

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Dashboard Personal'), findsOneWidget);
    expect(find.text('Contoh ringkasan · Mode demo'), findsNothing);

    await tester.tap(find.byIcon(Icons.logout_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Sign In'), findsOneWidget);
  });
}

class _TestAuthRepository extends AuthRepository {
  _TestAuthRepository() : super(_UnusedSupabaseClient());

  final states = StreamController<AppAuthState>.broadcast();

  @override
  AppAuthState get currentState => const AppAuthState(null);

  @override
  Stream<AppAuthState> get changes => states.stream;

  @override
  Future<bool> signUp(String name, String email, String password) async {
    states.add(const AppAuthState('test-user'));
    return true;
  }

  @override
  Future<void> signOut() async {
    states.add(const AppAuthState(null));
  }
}

class _UnusedSupabaseClient extends Fake implements SupabaseClient {}
