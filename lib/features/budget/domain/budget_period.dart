class BudgetDateRange {
  const BudgetDateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && !day.isAfter(end);
  }
}

/// Nilai [dbValue] harus sama dengan isi kolom `budget.period_type`.
enum BudgetPeriod {
  monthly(dbValue: 'monthly', label: 'Setiap Bulan');

  const BudgetPeriod({required this.dbValue, required this.label});

  final String dbValue;
  final String label;

  static BudgetPeriod fromDb(String? value) => values.firstWhere(
    (period) => period.dbValue == value,
    orElse: () => BudgetPeriod.monthly,
  );

  /// Rentang tanggal periode yang memuat [date].
  BudgetDateRange rangeFor(DateTime date) {
    switch (this) {
      case BudgetPeriod.monthly:
        return BudgetDateRange(
          DateTime(date.year, date.month, 1),
          DateTime(date.year, date.month + 1, 0),
        );
    }
  }
}
