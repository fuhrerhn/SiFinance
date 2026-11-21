class SpendingCategory {
  const SpendingCategory({required this.id, required this.name, this.colorHex});

  final int id;
  final String name;
  final String? colorHex;
}

class CategorySpending {
  const CategorySpending({
    required this.category,
    required this.totalMinorUnits,
    required this.fraction,
  });

  final SpendingCategory category;
  final int totalMinorUnits;
  final double fraction;

  double get total => totalMinorUnits / 100;
}
