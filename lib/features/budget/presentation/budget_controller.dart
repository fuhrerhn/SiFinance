import 'package:flutter/foundation.dart';

import '../data/budget_repository.dart';
import '../domain/budget.dart';

class BudgetController extends ChangeNotifier {
  BudgetController(this._repository);

  final BudgetRepository _repository;
  List<Budget> _budgets = const [];
  List<BudgetCategory> _categories = const [];
  bool _isLoading = true;
  bool _failed = false;
  int _request = 0;

  List<Budget> get budgets => _budgets;
  List<BudgetCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get failed => _failed;

  Future<void> reload() async {
    final request = ++_request;
    _isLoading = true;
    _failed = false;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.loadBudgets(),
        _repository.loadCategories(),
      ]);
      if (_request != request) return;
      _budgets = results[0] as List<Budget>;
      _categories = results[1] as List<BudgetCategory>;
    } catch (_) {
      if (_request != request) return;
      _failed = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Error dilempar ulang supaya form bisa menampilkannya.
  Future<void> save({String? id, required BudgetInput input}) async {
    if (id == null) {
      await _repository.create(input);
    } else {
      await _repository.update(id, input);
    }
    await reload();
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }
}
