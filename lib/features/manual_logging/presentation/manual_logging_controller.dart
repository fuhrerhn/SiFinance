import 'package:flutter/foundation.dart';

import '../data/manual_logging_repository.dart';
import '../domain/manual_transaction.dart';

class ManualLoggingController extends ChangeNotifier {
  ManualLoggingController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _date = today;
  }

  final ManualLoggingRepository _repository;
  final DateTime Function() _clock;

  TransactionType _type = TransactionType.expense;
  late DateTime _date;
  int _amount = 0;
  LogCategory? _category;
  List<String> _accounts = ['Tunai', 'Gopay'];
  String? _account = 'Tunai';
  String _location = '';
  String _description = '';
  bool _isPersonal = true;

  List<LogCategory> _categories = const [];
  bool _loadingCategories = true;
  bool _categoriesFailed = false;
  bool _saving = false;
  String? _error;

  TransactionType get type => _type;
  DateTime get date => _date;
  int get amount => _amount;
  LogCategory? get category => _category;
  List<String> get accounts => List.unmodifiable(_accounts);
  String? get account => _account;
  bool get isPersonal => _isPersonal;
  bool get loadingCategories => _loadingCategories;
  bool get categoriesFailed => _categoriesFailed;
  bool get saving => _saving;
  String? get error => _error;

  /// Tanggal hari ini tanpa jam.
  DateTime get today {
    final now = _clock();
    return DateTime(now.year, now.month, now.day);
  }

  /// Kategori yang cocok dengan tipe transaksi yang dipilih.
  List<LogCategory> get categoriesForType =>
      _categories.where((c) => c.type == _type).toList();

  Future<void> loadCategories() async {
    _loadingCategories = true;
    _categoriesFailed = false;
    notifyListeners();
    try {
      _categories = await _repository.loadCategories();
    } catch (_) {
      _categoriesFailed = true;
    }
    _loadingCategories = false;
    notifyListeners();
  }

  void setType(TransactionType type) {
    if (_type == type) return;
    _type = type;
    // Kategori pengeluaran tidak berlaku untuk pemasukan, begitu sebaliknya.
    if (_category?.type != type) _category = null;
    _error = null;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _date = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setAmount(int amount) {
    _amount = amount;
    _error = null;
    notifyListeners();
  }

  void selectCategory(LogCategory category) {
    _category = category;
    _error = null;
    notifyListeners();
  }

  void selectAccount(String? account) {
    _account = account;
    notifyListeners();
  }

  void addAccount(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (!_accounts.contains(clean)) _accounts = [..._accounts, clean];
    _account = clean;
    notifyListeners();
  }

  void setLocation(String value) => _location = value;

  void setDescription(String value) => _description = value;

  void setPersonal(bool value) {
    _isPersonal = value;
    notifyListeners();
  }

  /// Mengembalikan pesan kesalahan, atau null kalau data sudah lengkap.
  String? validate() {
    if (_amount <= 0) return 'Nominal harus lebih dari Rp0.';
    if (_category == null) return 'Pilih kategori dulu.';
    return null;
  }

  /// Menyimpan transaksi. Mengembalikan true kalau berhasil.
  Future<bool> save() async {
    if (_saving) return false;
    final problem = validate();
    if (problem != null) {
      _error = problem;
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.save(
        ManualTransaction(
          type: _type,
          date: _date,
          amount: _amount,
          category: _category!,
          paymentAccount: _account,
          location: _clean(_location),
          description: _clean(_description),
          isPersonal: _isPersonal,
        ),
      );
      _saving = false;
      notifyListeners();
      return true;
    } catch (_) {
      _saving = false;
      _error = 'Gagal menyimpan transaksi. Coba lagi.';
      notifyListeners();
      return false;
    }
  }

  /// Dipakai tombol "Tambah Lagi": tipe, tanggal, dan akun tetap, sisanya kosong.
  void resetForNext() {
    _amount = 0;
    _category = null;
    _location = '';
    _description = '';
    _error = null;
    notifyListeners();
  }

  static String? _clean(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}
