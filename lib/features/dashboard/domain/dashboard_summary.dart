import 'category_spending.dart';
import 'dashboard_period.dart';
import 'monthly_spending.dart';

class DashboardTransaction {
  const DashboardTransaction({
    required this.date,
    required this.amountMinorUnits,
    required this.category,
    required this.isExpense,
  });

  final DateTime date;
  final int amountMinorUnits;
  final SpendingCategory category;
  final bool isExpense;
}

class DashboardSummary {
  const DashboardSummary._({
    required this.selectedPeriod,
    required this.range,
    required this.totalMinorUnits,
    required this.monthlySpendings,
    required this.categorySpendings,
  });

  factory DashboardSummary.calculate({
    required DashboardPeriod period,
    required DateTime now,
    required Iterable<DashboardTransaction> periodTransactions,
    required Iterable<DashboardTransaction> trendTransactions,
  }) {
    final range = period.range(now);
    final trend = DashboardPeriod.lastSixMonths.range(now);
    final firstMonth = trend.start!;
    final months = List.generate(
      6,
      (index) => DateTime(firstMonth.year, firstMonth.month + index),
    );
    final totalsByMonth = {for (final month in months) month: 0};
    final categories = <int, SpendingCategory>{};
    final totalsByCategory = <int, int>{};
    var total = 0;
    for (final transaction in periodTransactions) {
      if (!transaction.isExpense || !range.contains(transaction.date)) continue;
      final category = transaction.category;
      categories[category.id] = category;
      totalsByCategory.update(
        category.id,
        (value) => value + transaction.amountMinorUnits,
        ifAbsent: () => transaction.amountMinorUnits,
      );
      total += transaction.amountMinorUnits;
    }
    for (final transaction in trendTransactions) {
      if (!transaction.isExpense || !trend.contains(transaction.date)) continue;
      final month = DateTime(transaction.date.year, transaction.date.month);
      totalsByMonth.update(
        month,
        (value) => value + transaction.amountMinorUnits,
      );
    }
    final categorySpendings =
        [
          for (final entry in totalsByCategory.entries)
            CategorySpending(
              category: categories[entry.key]!,
              totalMinorUnits: entry.value,
              fraction: entry.value / total,
            ),
        ]..sort((a, b) {
          final byAmount = b.totalMinorUnits.compareTo(a.totalMinorUnits);
          return byAmount != 0
              ? byAmount
              : a.category.id.compareTo(b.category.id);
        });

    return DashboardSummary._(
      selectedPeriod: period,
      range: range,
      totalMinorUnits: total,
      monthlySpendings: List.unmodifiable([
        for (final month in months)
          MonthlySpending(month, totalsByMonth[month]!),
      ]),
      categorySpendings: List.unmodifiable(categorySpendings),
    );
  }

  final DashboardPeriod selectedPeriod;
  final DashboardDateRange range;
  final int totalMinorUnits;
  final List<MonthlySpending> monthlySpendings;
  final List<CategorySpending> categorySpendings;

  DateTime? get startDate => range.start;
  DateTime? get endDate => range.end;
  double get totalExpense => totalMinorUnits / 100;
  double get averageMonthlyExpense =>
      monthlySpendings.fold(
        0,
        (int sum, month) => sum + month.totalMinorUnits,
      ) /
      (monthlySpendings.length * 100);
}
