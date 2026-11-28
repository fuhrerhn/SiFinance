import '../budget/data/budget_repository.dart';
import '../budget/domain/budget.dart';
import '../dashboard/data/dashboard_repository.dart';
import '../dashboard/domain/category_spending.dart';
import '../dashboard/domain/dashboard_period.dart';
import '../dashboard/domain/dashboard_summary.dart';
import '../histori_transaksi/data/histori_transaksi_repository.dart';
import '../histori_transaksi/domain/history_filter.dart';
import '../histori_transaksi/domain/history_transaction.dart';
import '../manual_logging/data/manual_logging_repository.dart';
import '../manual_logging/domain/manual_transaction.dart';

class DemoFinance implements DashboardRepository, ManualLoggingRepository {
  static const categories = [
    LogCategory(
      id: 1,
      name: 'Makanan & Minuman',
      type: TransactionType.expense,
    ),
    LogCategory(id: 2, name: 'Transportasi', type: TransactionType.expense),
    LogCategory(id: 3, name: 'Belanja', type: TransactionType.expense),
    LogCategory(id: 4, name: 'Gaji', type: TransactionType.income),
  ];

  final _transactions = <ManualTransaction>[];
  late final BudgetRepository budgets = _DemoBudgetRepository(this);
  late final HistoriTransaksiRepository historyTransactions =
      _DemoHistoriTransaksiRepository(this);

  @override
  Future<List<LogCategory>> loadCategories() async => categories;

  @override
  Future<void> save(ManualTransaction transaction) async {
    _transactions.add(transaction);
  }

  @override
  Future<DashboardSummary> load(DashboardPeriod period) async {
    final transactions = _transactions.map(
      (transaction) => DashboardTransaction(
        date: transaction.date,
        amountMinorUnits: transaction.amount * 100,
        isExpense: transaction.type == TransactionType.expense,
        category: SpendingCategory(
          id: transaction.category.id,
          name: transaction.category.name,
        ),
      ),
    );
    return DashboardSummary.calculate(
      period: period,
      now: DateTime.now(),
      periodTransactions: transactions,
      trendTransactions: transactions,
    );
  }
}

class _DemoBudgetRepository implements BudgetRepository {
  _DemoBudgetRepository(this.finance);

  final DemoFinance finance;
  final _inputs = <String, BudgetInput>{};
  int _nextId = 0;

  @override
  Future<List<BudgetCategory>> loadCategories() async => [
    for (final category in DemoFinance.categories)
      if (category.type == TransactionType.expense)
        BudgetCategory(id: category.id, name: category.name),
  ];

  @override
  Future<List<Budget>> loadBudgets() async {
    final categories = await loadCategories();
    final now = DateTime.now();
    return _inputs.entries.map((entry) {
      final input = entry.value;
      final range = input.period.rangeFor(now);
      final expenses = finance._transactions.where(
        (transaction) =>
            transaction.type == TransactionType.expense &&
            transaction.category.id == input.categoryId &&
            range.contains(transaction.date),
      );
      return Budget(
        id: entry.key,
        category: categories.firstWhere((item) => item.id == input.categoryId),
        limitMinorUnits: input.limitMinorUnits,
        spentMinorUnits: expenses.fold(
          0,
          (sum, item) => sum + item.amount * 100,
        ),
        period: input.period,
        range: range,
      );
    }).toList();
  }

  @override
  Future<void> create(BudgetInput input) async {
    _inputs[(++_nextId).toString()] = input;
  }

  @override
  Future<void> update(String id, BudgetInput input) async {
    if (!_inputs.containsKey(id)) throw StateError('Budget tidak ditemukan.');
    _inputs[id] = input;
  }
}

class _DemoHistoriTransaksiRepository implements HistoriTransaksiRepository {
  _DemoHistoriTransaksiRepository(this.finance);

  final DemoFinance finance;

  @override
  Future<List<HistoryTransaction>> load(
    HistoryFilter filter, {
    required int offset,
    required int limit,
  }) async {
    final rows = finance._transactions.asMap().entries.where((entry) {
      final transaction = entry.value;
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      if (filter.categoryId case final categoryId?) {
        if (transaction.category.id != categoryId) return false;
      }
      if (filter.start case final start?) {
        if (date.isBefore(start)) return false;
      }
      if (filter.end case final end?) {
        if (date.isAfter(end)) return false;
      }
      return true;
    }).toList();
    rows.sort((a, b) {
      final byDate = b.value.date.compareTo(a.value.date);
      return byDate != 0 ? byDate : b.key.compareTo(a.key);
    });
    return [
      for (final entry in rows.skip(offset).take(limit))
        HistoryTransaction(
          id: entry.key.toString(),
          type: entry.value.type == TransactionType.income
              ? HistoryType.income
              : HistoryType.expense,
          date: entry.value.date,
          amount: entry.value.amount,
          categoryId: entry.value.category.id,
          categoryName: entry.value.category.name,
          iconName: entry.value.category.iconName,
          colorHex: entry.value.category.colorHex,
          description: entry.value.description,
          location: entry.value.location,
          paymentAccount: entry.value.paymentAccount,
        ),
    ];
  }

  @override
  Future<List<HistoryCategory>> loadCategories() async => [
    for (final category in DemoFinance.categories)
      HistoryCategory(
        id: category.id,
        name: category.name,
        slug: category.name.toLowerCase().replaceAll(' ', '-'),
        isIncome: category.type == TransactionType.income,
        iconName: category.iconName,
        colorHex: category.colorHex,
      ),
  ];
}
