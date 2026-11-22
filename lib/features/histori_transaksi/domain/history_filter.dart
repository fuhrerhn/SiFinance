/// Filter histori: rentang tanggal (boleh kosong) dan satu kategori (boleh kosong).
/// Objek ini tidak bisa diubah; setiap perubahan menghasilkan objek baru.
class HistoryFilter {
  const HistoryFilter({this.start, this.end, this.categoryId});

  /// Filter kosong: semua transaksi.
  static const none = HistoryFilter();

  /// Tanggal awal dan akhir, keduanya ikut dihitung (inklusif).
  final DateTime? start;
  final DateTime? end;
  final int? categoryId;

  bool get hasDate => start != null && end != null;
  bool get hasCategory => categoryId != null;
  bool get isActive => hasDate || hasCategory;

  /// Mengganti rentang tanggal. Kirim null untuk menghapusnya.
  HistoryFilter withDateRange(DateTime? start, DateTime? end) => HistoryFilter(
    start: start == null ? null : _dateOnly(start),
    end: end == null ? null : _dateOnly(end),
    categoryId: categoryId,
  );

  /// Mengganti kategori. Kirim null untuk menghapusnya.
  HistoryFilter withCategory(int? categoryId) =>
      HistoryFilter(start: start, end: end, categoryId: categoryId);
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Satu kategori yang bisa dipilih di sheet filter.
class HistoryCategory {
  const HistoryCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.isIncome,
    this.iconName,
    this.colorHex,
  });

  final int id;
  final String name;
  final String slug;

  /// true kalau kategori pemasukan (group_name = 'income').
  final bool isIncome;
  final String? iconName;
  final String? colorHex;
}
