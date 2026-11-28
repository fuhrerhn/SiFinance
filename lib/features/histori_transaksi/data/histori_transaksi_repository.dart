import '../domain/history_filter.dart';
import '../domain/history_transaction.dart';

abstract interface class HistoriTransaksiRepository {
  /// Mengambil satu halaman transaksi, urut dari yang terbaru.
  /// [offset] adalah jumlah baris yang dilewati, [limit] jumlah maksimal baris.
  Future<List<HistoryTransaction>> load(
    HistoryFilter filter, {
    required int offset,
    required int limit,
  });

  /// Kategori aktif untuk pilihan di sheet filter.
  Future<List<HistoryCategory>> loadCategories();
}
