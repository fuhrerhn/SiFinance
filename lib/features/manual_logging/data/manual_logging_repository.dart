import '../domain/manual_transaction.dart';

abstract interface class ManualLoggingRepository {
  Future<List<LogCategory>> loadCategories();
  Future<void> save(ManualTransaction transaction);
}
