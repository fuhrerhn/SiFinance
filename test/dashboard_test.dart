import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tekber/features/auth/data/auth_repository.dart';
import 'package:tekber/features/dashboard/data/dashboard_repository.dart';
import 'package:tekber/features/dashboard/domain/category_spending.dart';
import 'package:tekber/features/dashboard/domain/dashboard_period.dart';
import 'package:tekber/features/dashboard/domain/dashboard_summary.dart';
import 'package:tekber/features/dashboard/presentation/dashboard_controller.dart';

const food = SpendingCategory(id: 1, name: 'Makanan');
const bills = SpendingCategory(id: 2, name: 'Tagihan');

DashboardTransaction spending(
  DateTime date,
  int amount, {
  SpendingCategory category = food,
  bool isExpense = true,
}) => DashboardTransaction(
  date: date,
  amountMinorUnits: amount,
  category: category,
  isExpense: isExpense,
);

DashboardSummary emptySummary(DashboardPeriod period) =>
    DashboardSummary.calculate(
      period: period,
      now: DateTime(2026, 2, 10),
      periodTransactions: [],
      trendTransactions: [],
    );

class _DelayedRepository implements DashboardRepository {
  final requests = <DashboardPeriod, Completer<DashboardSummary>>{};

  @override
  Future<DashboardSummary> load(DashboardPeriod period) =>
      (requests[period] = Completer<DashboardSummary>()).future;
}

void main() {
  test('selected period and six calendar months use independent scopes', () {
    final transactions = [
      spending(DateTime(2025, 8, 31), 10000),
      spending(DateTime(2025, 9, 1), 59975),
      spending(DateTime(2026, 2, 1), 10025),
      spending(DateTime(2026, 2, 28), 30000, category: bills),
      spending(DateTime(2026, 2, 28), 500000, isExpense: false),
      spending(DateTime(2026, 3, 1), 10000),
    ];
    final summary = DashboardSummary.calculate(
      period: DashboardPeriod.thisMonth,
      now: DateTime(2026, 2, 10),
      periodTransactions: transactions,
      trendTransactions: transactions,
    );
    expect(summary.startDate, DateTime(2026, 2, 1));
    expect(summary.endDate, DateTime(2026, 2, 28));
    expect(summary.totalMinorUnits, 40025);
    expect(summary.totalExpense, 400.25);
    expect(summary.categorySpendings.map((entry) => entry.category.name), [
      'Tagihan',
      'Makanan',
    ]);
    expect(
      summary.categorySpendings.first.fraction,
      closeTo(30000 / 40025, 0.00001),
    );
    expect(summary.monthlySpendings.map((month) => month.totalMinorUnits), [
      59975,
      0,
      0,
      0,
      0,
      40025,
    ]);
    expect(summary.monthlySpendings[1].hasData, isFalse);
    expect(summary.averageMonthlyExpense, closeTo(1000 / 6, 0.001));
  });

  test('calendar ranges follow local midnight and include leap day', () {
    final lastBill = DateTime(2024, 2, 29);
    final beforeMidnight = DateTime(2024, 2, 29, 23, 59, 59).toUtc();
    final afterMidnight = DateTime(2024, 3).toUtc();
    expect(
      DashboardPeriod.thisMonth.range(beforeMidnight).contains(lastBill),
      isTrue,
    );
    expect(
      DashboardPeriod.thisMonth.range(afterMidnight).contains(lastBill),
      isFalse,
    );
    expect(
      DashboardPeriod.lastThreeMonths.range(afterMidnight).start,
      DateTime(2024, 1),
    );
    expect(
      DashboardPeriod.lastSixMonths.range(afterMidnight).start,
      DateTime(2023, 10),
    );
    expect(
      DashboardPeriod.thisYear.range(afterMidnight).end,
      DateTime(2024, 12, 31),
    );
    expect(
      DashboardPeriod.allTime.range(afterMidnight).contains(DateTime(2000)),
      isTrue,
    );
  });

  test(
    'previous request cannot replace a newer filter after completing late',
    () async {
      final repository = _DelayedRepository();
      final controller = DashboardController(repository);
      addTearDown(controller.dispose);
      final first = controller.reload();
      final second = controller.selectPeriod(DashboardPeriod.allTime);
      repository.requests[DashboardPeriod.allTime]!.complete(
        emptySummary(DashboardPeriod.allTime),
      );
      await second;
      repository.requests[DashboardPeriod.thisMonth]!.completeError(
        StateError('Late error'),
      );
      await first;

      expect(controller.period, DashboardPeriod.allTime);
      expect(controller.summary?.selectedPeriod, DashboardPeriod.allTime);
      expect(controller.failed, isFalse);
    },
  );

  test('Supabase Auth errors are mapped to user-facing messages', () {
    expect(
      authErrorMessage(
        const AuthException('raw info', code: 'invalid_credentials'),
      ),
      'Email atau kata sandi salah.',
    );
    expect(
      authErrorMessage(
        const AuthException('raw info', code: 'user_already_exists'),
      ),
      'Email sudah terdaftar. Silakan masuk.',
    );
    expect(
      authErrorMessage(const AuthException('raw info', code: 'weak_password')),
      contains('terlalu lemah'),
    );
    expect(
      authErrorMessage(
        const AuthException('raw info', code: 'email_not_confirmed'),
      ),
      'Konfirmasi email sebelum masuk.',
    );
  });
}
