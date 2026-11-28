import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

String _group(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// 50000000 (sen) -> "Rp500.000"
String formatRupiah(int minorUnits) {
  final rupiah = (minorUnits / 100).round();
  return '${rupiah < 0 ? '-' : ''}Rp${_group(rupiah)}';
}

const _months = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// "1 Mei 2026"
String formatBudgetDate(DateTime date) =>
    '${date.day} ${_months[date.month - 1]} ${date.year}';

/// "Rp300.000" -> 30000000 (sen). Teks kosong -> 0.
int parseRupiahInput(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return 0;
  return int.parse(digits) * 100;
}

class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > 12) return oldValue;
    final text = 'Rp${_group(int.parse(digits))}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

Color colorFromHex(String? hex, Color fallback) {
  if (hex == null || hex.length != 7) return fallback;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}

/// Nama ikon di database (`kategori.icon_name`) -> ikon Flutter.
/// Salinan dari logging_sheets.dart; sebaiknya nanti dipindah ke lib/core.
IconData iconForCategory(String? name) => switch (name) {
  'restaurant' => Icons.restaurant,
  'directions_bus' => Icons.directions_bus,
  'shopping_bag' => Icons.shopping_bag,
  'receipt' => Icons.receipt_long,
  'movie' => Icons.movie,
  'medical_services' => Icons.medical_services,
  'payments' => Icons.payments,
  'redeem' => Icons.redeem,
  'work' => Icons.work,
  'more_horiz' => Icons.more_horiz,
  _ => Icons.category,
};
