enum TransactionType {
  expense('expense', 'Pengeluaran'),
  income('income', 'Pemasukan');

  const TransactionType(this.value, this.label);

  /// Nilai yang disimpan di kolom `transaksi.type`.
  final String value;

  /// Teks yang tampil di layar.
  final String label;
}

class LogCategory {
  const LogCategory({
    required this.id,
    required this.name,
    required this.type,
    this.iconName,
    this.colorHex,
  });

  final int id;
  final String name;
  final TransactionType type;
  final String? iconName;
  final String? colorHex;
}

class ManualTransaction {
  const ManualTransaction({
    required this.type,
    required this.date,
    required this.amount,
    required this.category,
    this.paymentAccount,
    this.location,
    this.description,
    this.isPersonal = true,
  });

  final TransactionType type;
  final DateTime date;

  /// Nominal dalam rupiah utuh, selalu lebih dari 0.
  final int amount;
  final LogCategory category;
  final String? paymentAccount;
  final String? location;
  final String? description;
  final bool isPersonal;
}
