import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/generated/database.g.dart';
import '../domain/budget.dart';
import '../domain/budget_period.dart';
import 'budget_repository.dart';

class SupabaseBudgetRepository implements BudgetRepository {
  SupabaseBudgetRepository(
    this.client,
    this.userId, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final SupabaseClient client;
  final String userId;
  final DateTime Function() _clock;

  @override
  Future<List<BudgetCategory>> loadCategories() async {
    final rows = await client
        .from(KategoriRow.table)
        .select('id,name,color_hex,icon_name')
        .eq('is_active', true)
        .order('name', ascending: true);
    return [for (final json in rows) _category(json)];
  }

  @override
  Future<List<Budget>> loadBudgets() async {
    final now = _clock();
    final rows = await client
        .from(BudgetRow.table)
        .select(
          'id,category_id,limit_amount,period_type,'
          'kategori(id,name,color_hex,icon_name)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    if (rows.isEmpty) return const [];

    // Budget bulanan dihitung untuk bulan berjalan (berulang tiap bulan).
    final periods = [
      for (final json in rows) BudgetPeriod.fromDb(BudgetRow(json).periodType),
    ];
    final ranges = [for (final period in periods) period.rangeFor(now)];
    final overall = BudgetDateRange(
      ranges.map((r) => r.start).reduce((a, b) => a.isBefore(b) ? a : b),
      ranges.map((r) => r.end).reduce((a, b) => a.isAfter(b) ? a : b),
    );
    final expenses = await _expenses(overall);

    final budgets = <Budget>[];
    for (var i = 0; i < rows.length; i++) {
      final json = rows[i];
      final row = BudgetRow(json);
      final range = ranges[i];
      var spent = 0;
      for (final expense in expenses) {
        if (expense.categoryId == row.categoryId &&
            range.contains(expense.date)) {
          spent += expense.amountMinorUnits;
        }
      }
      budgets.add(
        Budget(
          id: row.id,
          category: _category(json['kategori'] as Map<String, dynamic>),
          limitMinorUnits: _toMinorUnits(row.limitAmount),
          spentMinorUnits: spent,
          period: periods[i],
          range: range,
        ),
      );
    }
    return budgets;
  }

  @override
  Future<void> create(BudgetInput input) async {
    await client
        .from(BudgetRow.table)
        .insert(_payload(input, includeUser: true));
  }

  @override
  Future<void> update(String id, BudgetInput input) async {
    await client
        .from(BudgetRow.table)
        .update({
          ..._payload(input),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', userId);
  }

  Map<String, dynamic> _payload(BudgetInput input, {bool includeUser = false}) {
    final range = input.period.rangeFor(_clock());
    return {
      if (includeUser) 'user_id': userId,
      'category_id': input.categoryId,
      'limit_amount': input.limitMinorUnits / 100,
      'period_type': input.period.dbValue,
      'start_date': _sqlDate(range.start),
      'end_date': _sqlDate(range.end),
    };
  }

  Future<List<_Expense>> _expenses(BudgetDateRange range) async {
    final expenses = <_Expense>[];
    String? cursor;
    while (true) {
      var query = client
          .from(TransaksiRow.table)
          .select('id,type,category_id,transaction_date,amount')
          .eq('user_id', userId)
          .eq('type', 'expense')
          .gte('transaction_date', _sqlDate(range.start))
          .lte('transaction_date', _sqlDate(range.end));
      if (cursor != null) query = query.gt('id', cursor);

      final rows = await query.order('id', ascending: true).limit(500);
      if (rows.isEmpty) return expenses;
      for (final json in rows) {
        final row = TransaksiRow(json);
        expenses.add(
          _Expense(
            categoryId: row.categoryId,
            date: DateTime.parse(row.transactionDate),
            amountMinorUnits: _toMinorUnits(row.amount),
          ),
        );
        cursor = row.id;
      }
    }
  }
}

class _Expense {
  const _Expense({
    required this.categoryId,
    required this.date,
    required this.amountMinorUnits,
  });

  final int categoryId;
  final DateTime date;
  final int amountMinorUnits;
}

BudgetCategory _category(Map<String, dynamic> json) {
  final row = KategoriRow(json);
  return BudgetCategory(
    id: row.id,
    name: row.name,
    colorHex: row.colorHex,
    iconName: json['icon_name'] as String?,
  );
}

int _toMinorUnits(Object? value) => ((value as num) * 100).round();

String _sqlDate(DateTime date) => date.toIso8601String().split('T').first;
