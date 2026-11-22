import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/generated/database.g.dart';
import '../domain/history_filter.dart';
import '../domain/history_transaction.dart';
import 'histori_transaksi_repository.dart';

class SupabaseHistoriTransaksiRepository implements HistoriTransaksiRepository {
  SupabaseHistoriTransaksiRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<List<HistoryTransaction>> load(
    HistoryFilter filter, {
    required int offset,
    required int limit,
  }) async {
    // Gaya query sama dengan dashboard: transaksi digabung dengan kategori.
    var query = client
        .from(TransaksiRow.table)
        .select(
          'id,type,transaction_date,amount,description,location,'
          'payment_account,kategori(id,name,icon_name,color_hex)',
        )
        .eq('user_id', userId);
    if (filter.start case final start?) {
      query = query.gte('transaction_date', _sqlDate(start));
    }
    if (filter.end case final end?) {
      query = query.lte('transaction_date', _sqlDate(end));
    }
    if (filter.categoryId case final categoryId?) {
      query = query.eq('category_id', categoryId);
    }

    // Kolom id ikut diurutkan supaya urutan antar halaman selalu sama.
    final rows = await query
        .order('transaction_date', ascending: false)
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .range(offset, offset + limit - 1);

    return [
      for (final json in rows)
        _toTransaction(Map<String, dynamic>.from(json)),
    ];
  }

  @override
  Future<List<HistoryCategory>> loadCategories() async {
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
}

HistoryTransaction _toTransaction(Map<String, dynamic> json) {
  final row = TransaksiRow(json);
  final category = KategoriRow(
    Map<String, dynamic>.from(json['kategori'] as Map),
  );
  return HistoryTransaction(
    id: row.id,
    type: row.type == 'income' ? HistoryType.income : HistoryType.expense,
    date: DateTime.parse(row.transactionDate),
    amount: row.amount,
    categoryId: category.id,
    categoryName: category.name,
    iconName: category.iconName,
    colorHex: category.colorHex,
    description: row.description,
    location: row.location,
    paymentAccount: row.paymentAccount,
  );
}

HistoryCategory _toCategory(KategoriRow row) => HistoryCategory(
  id: row.id,
  name: row.name,
  slug: row.slug,
  isIncome: row.groupName == 'income',
  iconName: row.iconName,
  colorHex: row.colorHex,
);

/// Format tanggal yang dimengerti Postgres: yyyy-MM-dd.
String _sqlDate(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
