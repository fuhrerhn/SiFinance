class MonthlySpending {
  const MonthlySpending(this.month, this.totalMinorUnits);

  final DateTime month;
  final int totalMinorUnits;

  double get total => totalMinorUnits / 100;
  bool get hasData => totalMinorUnits != 0;
}
