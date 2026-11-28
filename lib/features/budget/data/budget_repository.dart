import '../domain/budget.dart';

abstract interface class BudgetRepository {
  Future<List<Budget>> loadBudgets();
  Future<List<BudgetCategory>> loadCategories();
  Future<void> create(BudgetInput input);
  Future<void> update(String id, BudgetInput input);
}
