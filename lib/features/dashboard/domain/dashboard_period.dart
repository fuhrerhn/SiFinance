enum DashboardPeriod {
  thisMonth('Bulan ini'),
  lastThreeMonths('3 bulan'),
  lastSixMonths('6 bulan'),
  thisYear('Tahun ini'),
  allTime('Semua waktu');

  const DashboardPeriod(this.label);
  final String label;

  DashboardDateRange range(DateTime now) {
    final local = now.toLocal();
    final year = local.year;
    final month = local.month;
    final endOfMonth = DateTime(year, month + 1, 0);
    return switch (this) {
      thisMonth => DashboardDateRange(DateTime(year, month), endOfMonth),
      lastThreeMonths => DashboardDateRange(
        DateTime(year, month - 2),
        endOfMonth,
      ),
      lastSixMonths => DashboardDateRange(
        DateTime(year, month - 5),
        endOfMonth,
      ),
      thisYear => DashboardDateRange(DateTime(year), DateTime(year, 12, 31)),
      allTime => const DashboardDateRange(null, null),
    };
  }
}

class DashboardDateRange {
  const DashboardDateRange(this.start, this.end);

  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime date) {
    final start = this.start;
    final end = this.end;
    return (start == null || !date.isBefore(start)) &&
        (end == null || !date.isAfter(end));
  }
}
