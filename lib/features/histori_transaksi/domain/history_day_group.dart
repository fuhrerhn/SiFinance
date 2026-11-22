import 'package:intl/intl.dart';

import 'history_transaction.dart';

/// Kumpulan transaksi pada satu hari.
class HistoryDayGroup {
  const HistoryDayGroup({required this.date, required this.items});

  final DateTime date;
  final List<HistoryTransaction> items;

  /// Total PENGELUARAN hari itu saja. Pemasukan tidak ikut dihitung.
  num get totalExpense => items
      .where((transaction) => transaction.isExpense)
      .fold<num>(0, (sum, transaction) => sum + transaction.amount);
}

/// Mengelompokkan transaksi per hari. Hari terbaru ada di urutan pertama,
/// sedangkan urutan transaksi di dalam satu hari mengikuti urutan masukan.
List<HistoryDayGroup> groupByDay(List<HistoryTransaction> transactions) {
  final byDay = <DateTime, List<HistoryTransaction>>{};
  for (final transaction in transactions) {
    final day = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    byDay.putIfAbsent(day, () => []).add(transaction);
  }
  final groups = [
    for (final entry in byDay.entries)
      HistoryDayGroup(date: entry.key, items: entry.value),
  ];
  groups.sort((a, b) => b.date.compareTo(a.date));
  return groups;
}

/// Judul grup: "Hari ini", "Kemarin", selain itu tanggal lengkap
/// seperti "Senin 12 Maret 2026".
String dayLabel(DateTime date, DateTime today) {
  final day = DateTime(date.year, date.month, date.day);
  final now = DateTime(today.year, today.month, today.day);
  if (day == now) return 'Hari ini';
  if (day == DateTime(now.year, now.month, now.day - 1)) return 'Kemarin';
  return DateFormat('EEEE d MMMM y', 'id_ID').format(day);
}
