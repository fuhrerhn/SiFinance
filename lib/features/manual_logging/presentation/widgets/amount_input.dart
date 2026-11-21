import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../../dashboard/presentation/widgets/dashboard_formats.dart';

/// Batas 12 digit supaya muat di kolom numeric(14,2).
const _maxDigits = 12;

/// Mengambil angka dari teks seperti "Rp10.000" -> 10000.
int amountFromText(String text) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? 0 : int.parse(digits);
}

/// Mengubah isi kolom menjadi format rupiah saat pengguna mengetik.
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue();
    if (digits.length > _maxDigits) return oldValue;
    final text = formatRupiah(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class AmountInput extends StatelessWidget {
  const AmountInput({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      inputFormatters: [RupiahInputFormatter()],
      onChanged: (text) => onChanged(amountFromText(text)),
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF101828),
      ),
      decoration: InputDecoration(
        hintText: 'Rp0',
        hintStyle: theme.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF98A2B3),
        ),
        border: InputBorder.none,
      ),
    );
  }
}
