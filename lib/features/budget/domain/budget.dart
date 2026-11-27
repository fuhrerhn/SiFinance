import 'budget_period.dart';

class BudgetCategory {
  const BudgetCategory({
    required this.id,
    required this.name,
    this.colorHex,
    this.iconName,
  });

  final int id;
  final String name;
  final String? colorHex;
  final String? iconName;
}

class Budget {
  const Budget({
    required this.id,
    required this.category,
    required this.limitMinorUnits,
    required this.spentMinorUnits,
    required this.period,
    required this.range,
  });

  final String id;
  final BudgetCategory category;
  final int limitMinorUnits;
  final int spentMinorUnits;
  final BudgetPeriod period;
  final BudgetDateRange range;

  int get remainingMinorUnits => limitMinorUnits - spentMinorUnits;
  bool get isOverBudget => spentMinorUnits > limitMinorUnits;

  /// 0..1 untuk lebar progress bar.
  double get fraction => limitMinorUnits <= 0
      ? 0
      : (spentMinorUnits / limitMinorUnits).clamp(0.0, 1.0);

  /// Persentase asli (bisa > 100 kalau melebihi budget).
  int get percent => limitMinorUnits <= 0
      ? 0
      : (spentMinorUnits * 100 / limitMinorUnits).round();
}

class BudgetInput {
  const BudgetInput({
    required this.categoryId,
    required this.limitMinorUnits,
    required this.period,
  });

  final int categoryId;
  final int limitMinorUnits;
  final BudgetPeriod period;
}
