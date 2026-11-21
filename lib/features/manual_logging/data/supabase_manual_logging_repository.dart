import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/generated/database.g.dart';
import '../domain/manual_transaction.dart';
import 'manual_logging_repository.dart';

class SupabaseManualLoggingRepository implements ManualLoggingRepository {
  SupabaseManualLoggingRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<List<LogCategory>> loadCategories() async {
    final rows = await client
        .from(KategoriRow.table)
        .select()
        .eq('is_active', true)
        .order('name');
    return [
      for (final json in rows)
        _toCategory(KategoriRow(Map<String, dynamic>.from(json))),
    ];
  }

  @override
  Future<void> save(ManualTransaction transaction) async {
    await client.from(TransaksiRow.table).insert({
      'user_id': userId,
      'category_id': transaction.category.id,
      'type': transaction.type.value,
      'transaction_date': _sqlDate(transaction.date),
      'amount': transaction.amount,
      'description': transaction.description,
      'location': transaction.location,
      'payment_account': transaction.paymentAccount,
      'transaksi_pribadi': transaction.isPersonal,
    });
  }
}

LogCategory _toCategory(KategoriRow row) => LogCategory(
  id: row.id,
  name: row.name,
  type: row.groupName == 'income'
      ? TransactionType.income
      : TransactionType.expense,
  iconName: row.iconName,
  colorHex: row.colorHex,
);

String _sqlDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
