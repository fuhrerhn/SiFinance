import 'package:material_ui/material_ui.dart';

import '../../../dashboard/presentation/widgets/dashboard_formats.dart';
import '../../domain/history_transaction.dart';

/// Warna nominal. Nilainya sama dengan yang dipakai di fitur catat transaksi.
const historyExpenseColor = Color(0xFFD92D20);
const historyIncomeColor = Color(0xFF079455);
const _fallbackCategoryColor = Color(0xFF667085);

/// Nominal rupiah dengan spasi setelah "Rp", sesuai desain ("Rp 25.000").
/// Memakai formatRupiah() dari dashboard, lalu spasinya dirapikan di sini.
String rupiahDenganSpasi(num value) =>
    'Rp ${formatRupiah(value).replaceFirst('Rp', '').trim()}';

/// Satu baris transaksi: ikon kategori, nama kategori, deskripsi, nominal.
class HistoryTransactionTile extends StatelessWidget {
  const HistoryTransactionTile({super.key, required this.transaction});

  final HistoryTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final description = transaction.description?.trim() ?? '';
    final isExpense = transaction.isExpense;
    final sign = isExpense ? '-' : '+';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          HistoryCategoryIcon(
            iconName: transaction.iconName,
            colorHex: transaction.colorHex,
          ),
          const SizedBox(width: 10),
          // Expanded membuat teks panjang terpotong, bukan overflow.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${rupiahDenganSpasi(transaction.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isExpense ? historyExpenseColor : historyIncomeColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kotak berwarna berisi ikon kategori.
class HistoryCategoryIcon extends StatelessWidget {
  const HistoryCategoryIcon({
    super.key,
    required this.iconName,
    required this.colorHex,
    this.size = 32,
  });

  final String? iconName;
  final String? colorHex;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(colorHex) ?? _fallbackCategoryColor;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(_iconFor(iconName), size: size * 0.56, color: Colors.white),
    );
  }
}

/// Mengubah "#RRGGBB" menjadi Color. Hasilnya null kalau formatnya salah.
Color? _parseColor(String? hex) {
  if (hex == null || hex.length != 7) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// Nama ikon di database (kategori.icon_name) dipetakan ke ikon Flutter.
IconData _iconFor(String? name) => switch (name) {
  'restaurant' => Icons.restaurant,
  'directions_bus' => Icons.directions_bus,
  'shopping_bag' => Icons.shopping_bag,
  'receipt' || 'receipt_long' => Icons.receipt_long,
  'movie' => Icons.movie,
  'medical_services' => Icons.medical_services,
  'payments' => Icons.payments,
  'redeem' => Icons.redeem,
  'work' => Icons.work,
  'more_horiz' => Icons.more_horiz,
  _ => Icons.category,
};
