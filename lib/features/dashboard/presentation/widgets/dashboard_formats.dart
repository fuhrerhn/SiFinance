import 'package:intl/intl.dart';

final _rupiah = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);
final _rupiahWithCents = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 2,
);
final _percentage = NumberFormat('0.#%', 'id_ID');
final _compact = NumberFormat.compact(locale: 'id_ID');

String formatRupiah(num value) =>
    (value % 1 == 0 ? _rupiah : _rupiahWithCents).format(value);
String formatFraction(double fraction) => _percentage.format(fraction);
String formatAxisRupiah(double value) => 'Rp${_compact.format(value)}';
