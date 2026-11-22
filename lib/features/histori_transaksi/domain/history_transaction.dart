/// Jenis transaksi di histori.
enum HistoryType { expense, income }

/// Satu transaksi di layar histori.
/// Sengaja tidak bergantung pada Supabase supaya mudah dites.
class HistoryTransaction {
  const HistoryTransaction({
    required this.id,
    required this.type,
    required this.date,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    this.iconName,
    this.colorHex,
    this.description,
    this.location,
    this.paymentAccount,
  });

  final String id;
  final HistoryType type;

  /// Tanggal transaksi (tanpa jam).
  final DateTime date;
  final num amount;
  final int categoryId;
  final String categoryName;
  final String? iconName;
  final String? colorHex;
  final String? description;
  final String? location;
  final String? paymentAccount;

  bool get isExpense => type == HistoryType.expense;
}
