import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/generated/database.g.dart';
import '../domain/category_spending.dart';
import '../domain/dashboard_period.dart';
import '../domain/dashboard_summary.dart';
import 'dashboard_repository.dart';

class SupabaseDashboardRepository implements DashboardRepository {
  SupabaseDashboardRepository(
    this.client,
    this.userId, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SupabaseClient client;
  final String userId;
  final DateTime Function() _clock;

  @override
  Future<DashboardSummary> load(DashboardPeriod period) async {
    final now = _clock();
    final trend = _expenses(DashboardPeriod.lastSixMonths.range(now));
    final results = await Future.wait([
      period == DashboardPeriod.lastSixMonths
          ? trend
          : _expenses(period.range(now)),
      trend,
    ]);
    return DashboardSummary.calculate(
      period: period,
      now: now,
      periodTransactions: results.first,
      trendTransactions: results.last,
    );
  }

  Future<List<DashboardTransaction>> _expenses(DashboardDateRange range) async {
    final transactions = <DashboardTransaction>[];
    String? cursor;
    while (true) {
      var query = client
          .from(TransactionsRow.table)
          .select(
            'id,type,transaction_date,amount,categories(id,name,color_hex)',
          )
          .eq('user_id', userId)
          .eq('type', 'expense');
      if (range.start case final start?) {
        query = query.gte('transaction_date', _sqlDate(start));
      }
      if (range.end case final end?) {
        query = query.lte('transaction_date', _sqlDate(end));
      }
      if (cursor != null) query = query.gt('id', cursor);

      final rows = await query.order('id', ascending: true).limit(500);
      if (rows.isEmpty) return transactions;
      for (final json in rows) {
        final row = TransactionsRow(json);
        final category = CategoriesRow(
          json['categories'] as Map<String, dynamic>,
        );
        // numeric(14,2) fits exactly in integer hundredths after rounding.
        transactions.add(
          DashboardTransaction(
            date: DateTime.parse(row.transactionDate),
            amountMinorUnits: (row.amount * 100).round(),
            category: SpendingCategory(
              id: category.id,
              name: category.name,
              colorHex: category.colorHex,
            ),
            isExpense: row.type == 'expense',
          ),
        );
        cursor = row.id;
      }
    }
  }
}

String _sqlDate(DateTime date) => date.toIso8601String().split('T').first;
