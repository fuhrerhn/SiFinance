import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tekber/core/supabase/supabase_config.dart';
import 'package:tekber/features/auth/data/auth_repository.dart';
import 'package:tekber/features/dashboard/data/supabase_dashboard_repository.dart';
import 'package:tekber/features/dashboard/domain/dashboard_period.dart';

const _password = 'SiFinanceDemo123!';

class _PkceStorage extends GotrueAsyncStorage {
  final _items = <String, String>{};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> setItem({required String key, required String value}) async {
    _items[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    _items.remove(key);
  }
}

void main() {
  const enabled = bool.fromEnvironment('RUN_SUPABASE_INTEGRATION');
  final uri = Uri.tryParse(SupabaseConfig.url);
  final local = const {'127.0.0.1', 'localhost', '::1'}.contains(uri?.host);

  group('local Supabase integration', skip: !enabled, () {
    late SupabaseClient clientA;
    late SupabaseClient clientB;
    late AuthRepository authA;
    late AuthRepository authB;

    setUp(() {
      if (!SupabaseConfig.isConfigured || !local) {
        throw StateError(
          'Use the seeded local Supabase instance for integration tests.',
        );
      }
      clientA = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
        authOptions: AuthClientOptions(pkceAsyncStorage: _PkceStorage()),
      );
      clientB = SupabaseClient(
        SupabaseConfig.url,
        SupabaseConfig.publishableKey,
        authOptions: AuthClientOptions(pkceAsyncStorage: _PkceStorage()),
      );
      addTearDown(clientA.dispose);
      addTearDown(clientB.dispose);
      authA = AuthRepository(clientA);
      authB = AuthRepository(clientB);
    });

    test('seeded users see their own totals and cannot read each other through REST', () async {
      await authA.signIn('demo-a@example.com', _password);
      await authB.signIn('demo-b@example.com', _password);
      final userA = authA.currentState.userId!;
      final userB = authB.currentState.userId!;
      expect(userA, isNot(userB));

      final a = SupabaseDashboardRepository(clientA, userA);
      final b = SupabaseDashboardRepository(clientB, userB);
      final summaryA = await a.load(DashboardPeriod.thisMonth);
      final summaryB = await b.load(DashboardPeriod.thisMonth);
      expect(summaryA.totalExpense, 1250000);
      expect(summaryA.monthlySpendings.map((month) => month.total), [
        670000,
        830000,
        0,
        1320000,
        960000,
        1250000,
      ]);
      expect(summaryA.averageMonthlyExpense, closeTo(5030000 / 6, 0.01));
      expect(summaryA.categorySpendings, hasLength(3));
      expect(
        (await a.load(DashboardPeriod.lastThreeMonths)).totalExpense,
        3530000,
      );
      expect(summaryB.totalExpense, 875000);
      expect(summaryB.categorySpendings.single.category.name, 'Kesehatan');

      // Query the other owner's ID directly so this assertion relies on RLS.
      expect(
        await clientA.from('transactions').select('id').eq('user_id', userB),
        isEmpty,
      );
      expect(
        await clientB.from('transactions').select('id').eq('user_id', userA),
        isEmpty,
      );
      await expectLater(
        clientB
            .from('transactions')
            .update({'description': 'Other account'})
            .eq('user_id', userA)
            .select('id'),
        completion(isEmpty),
      );
    });

    test(
      'registration creates a profile, restores a session, and signs out',
      () async {
        final email =
            'integration-${DateTime.now().microsecondsSinceEpoch}@example.com';
        final signedIn = await authA.signUp(
          'Pengguna Integrasi',
          email,
          _password,
        );
        expect(signedIn, isTrue);
        final userId = authA.currentState.userId!;
        expect(await clientA.from('profiles').select('full_name').single(), {
          'full_name': 'Pengguna Integrasi',
        });
        final session = clientA.auth.currentSession!;
        await clientB.auth.recoverSession(jsonEncode(session.toJson()));
        expect(authB.currentState.userId, userId);
        expect(
          (await SupabaseDashboardRepository(
            clientB,
            userId,
          ).load(DashboardPeriod.thisMonth)).totalExpense,
          0,
        );
        final signedOut = authA.changes.firstWhere(
          (state) => state.userId == null,
        );
        await authA.signOut();
        await signedOut;
        expect(authA.currentState.userId, isNull);
        await expectLater(
          clientA.from('transactions').select('id'),
          throwsA(isA<PostgrestException>()),
        );
        await authA.signIn(email, _password);
        expect(authA.currentState.userId, userId);
        await authA.signOut();
      },
    );
  });
}
