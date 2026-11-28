import 'package:flutter/foundation.dart';

import '../data/histori_transaksi_repository.dart';
import '../domain/history_day_group.dart';
import '../domain/history_filter.dart';
import '../domain/history_transaction.dart';

class HistoriTransaksiController extends ChangeNotifier {
  HistoriTransaksiController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Jumlah baris per halaman.
  static const pageSize = 30;

  final HistoriTransaksiRepository _repository;
  final DateTime Function() _clock;

  List<HistoryTransaction> _items = const [];
  List<HistoryCategory> _categories = const [];
  HistoryFilter _filter = HistoryFilter.none;

  bool _loading = true;
  bool _failed = false;
  bool _loadingMore = false;
  bool _loadMoreFailed = false;
  bool _hasMore = false;
  bool _categoriesFailed = false;

  // Setiap pemuatan ulang menaikkan angka ini. Hasil dari permintaan lama
  // (misalnya sebelum filter diganti) diabaikan.
  int _requestId = 0;

  List<HistoryTransaction> get items => List.unmodifiable(_items);
  List<HistoryCategory> get categories => List.unmodifiable(_categories);
  HistoryFilter get filter => _filter;
  bool get loading => _loading;
  bool get failed => _failed;
  bool get loadingMore => _loadingMore;
  bool get loadMoreFailed => _loadMoreFailed;
  bool get hasMore => _hasMore;
  bool get categoriesFailed => _categoriesFailed;

  /// Tidak sedang memuat, tidak error, dan tidak ada transaksi.
  bool get isEmpty => !_loading && !_failed && _items.isEmpty;

  /// Transaksi yang sudah dimuat, dikelompokkan per hari.
  List<HistoryDayGroup> get groups => groupByDay(_items);

  /// Tanggal hari ini tanpa jam.
  DateTime get today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// Memuat halaman pertama. Dipakai saat layar dibuka, saat filter berubah,
  /// dan untuk tombol "Coba lagi". Tarik-untuk-muat-ulang memakai
  /// `showLoading: false` supaya daftar lama tetap terlihat selama memuat.
  Future<void> load({bool showLoading = true}) async {
    final requestId = ++_requestId;
    _loadingMore = false;
    _loadMoreFailed = false;
    _failed = false;
    if (showLoading) {
      _loading = true;
      _items = const [];
      _hasMore = false;
    }
    notifyListeners();
    try {
      final page = await _repository.load(_filter, offset: 0, limit: pageSize);
      if (requestId != _requestId) return;
      _items = page;
      _hasMore = page.length >= pageSize;
    } catch (_) {
      if (requestId != _requestId) return;
      _failed = true;
    }
    _loading = false;
    notifyListeners();
  }

  /// Menambah halaman berikutnya ke bawah daftar.
  Future<void> loadMore() async {
    // Pelindung: tombol yang ditekan cepat tidak memuat dua kali.
    if (_loading || _loadingMore || !_hasMore) return;
    final requestId = _requestId;
    _loadingMore = true;
    _loadMoreFailed = false;
    notifyListeners();
    try {
      final page = await _repository.load(
        _filter,
        offset: _items.length,
        limit: pageSize,
      );
      if (requestId != _requestId) return;
      // Transaksi yang sudah ada tidak dimasukkan dua kali.
      final known = _items.map((transaction) => transaction.id).toSet();
      _items = [
        ..._items,
        for (final transaction in page)
          if (!known.contains(transaction.id)) transaction,
      ];
      _hasMore = page.length >= pageSize;
    } catch (_) {
      if (requestId != _requestId) return;
      _loadMoreFailed = true;
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> loadCategories() async {
    try {
      _categories = await _repository.loadCategories();
      _categoriesFailed = false;
    } catch (_) {
      _categoriesFailed = true;
    }
    notifyListeners();
  }

  /// Mengganti rentang tanggal (null untuk menghapus), lalu memuat ulang.
  Future<void> setDateRange(DateTime? start, DateTime? end) {
    _filter = _filter.withDateRange(start, end);
    return load();
  }

  /// Mengganti kategori (null untuk menghapus), lalu memuat ulang.
  Future<void> setCategory(int? categoryId) {
    _filter = _filter.withCategory(categoryId);
    return load();
  }
}
