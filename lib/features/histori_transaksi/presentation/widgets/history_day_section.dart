import 'package:material_ui/material_ui.dart';

import '../../domain/history_day_group.dart';
import 'history_transaction_tile.dart';

/// Satu hari: judul + total pengeluaran, lalu satu kartu berisi
/// semua transaksi hari itu (dipisah garis tipis).
class HistoryDaySection extends StatelessWidget {
  const HistoryDaySection({
    super.key,
    required this.group,
    required this.today,
  });

  final HistoryDayGroup group;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final total = group.totalExpense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    dayLabel(group.date, today),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                // Hari yang hanya berisi pemasukan tidak punya total pengeluaran.
                if (total > 0)
                  Text(
                    '-${rupiahDenganSpasi(total)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: historyExpenseColor,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEAECF0)),
            ),
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
                  HistoryTransactionTile(transaction: group.items[i]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
