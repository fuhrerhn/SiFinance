import 'package:material_ui/material_ui.dart';

import '../../domain/manual_transaction.dart';

/// Ketiga fungsi di bawah membuka bottom sheet dan mengembalikan pilihan
/// pengguna. Hasilnya null kalau pengguna menekan Batal atau menutup sheet.

Future<TransactionType?> showTypeSheet(
  BuildContext context,
  TransactionType current,
) {
  return showModalBottomSheet<TransactionType>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TypeSheet(current: current),
  );
}

Future<DateTime?> showDateSheet(
  BuildContext context, {
  required DateTime current,
  required DateTime today,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DateSheet(current: current, today: today),
  );
}

Future<LogCategory?> showCategorySheet(
  BuildContext context, {
  required List<LogCategory> categories,
  required LogCategory? current,
  required TransactionType type,
}) {
  return showModalBottomSheet<LogCategory>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) =>
        _CategorySheet(categories: categories, current: current, type: type),
  );
}

/// Kerangka yang dipakai bersama: judul, isi, tombol Simpan dan Batal.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Flexible(child: child),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSave, child: const Text('Simpan')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Satu baris pilihan dengan ikon radio di kanan.
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.labelColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Expanded(
              child: Text(label, style: TextStyle(color: labelColor)),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 20,
              color: selected ? primary : const Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeSheet extends StatefulWidget {
  const _TypeSheet({required this.current});

  final TransactionType current;

  @override
  State<_TypeSheet> createState() => _TypeSheetState();
}

class _TypeSheetState extends State<_TypeSheet> {
  late TransactionType _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Pilih Tipe Transaksi',
      onSave: () => Navigator.of(context).pop(_selected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ChoiceRow(
            label: TransactionType.expense.label,
            labelColor: const Color(0xFFD92D20),
            leading: const Icon(
              Icons.circle,
              size: 10,
              color: Color(0xFFD92D20),
            ),
            selected: _selected == TransactionType.expense,
            onTap: () => setState(() => _selected = TransactionType.expense),
          ),
          _ChoiceRow(
            label: TransactionType.income.label,
            labelColor: const Color(0xFF079455),
            leading: const Icon(
              Icons.circle,
              size: 10,
              color: Color(0xFF079455),
            ),
            selected: _selected == TransactionType.income,
            onTap: () => setState(() => _selected = TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _DateSheet extends StatefulWidget {
  const _DateSheet({required this.current, required this.today});

  final DateTime current;
  final DateTime today;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  late DateTime _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: 'Pilih Tanggal Transaksi',
      onSave: () => Navigator.of(context).pop(_selected),
      child: SingleChildScrollView(
        child: CalendarDatePicker(
          initialDate: widget.current,
          firstDate: DateTime(2020),
          lastDate: widget.today,
          onDateChanged: (date) => _selected = date,
        ),
      ),
    );
  }
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.categories,
    required this.current,
    required this.type,
  });

  final List<LogCategory> categories;
  final LogCategory? current;
  final TransactionType type;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late LogCategory? _selected = widget.current;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final shown = widget.categories
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return _SheetFrame(
      title: 'Pilih Kategori Transaksi',
      onSave: _selected == null
          ? null
          : () => Navigator.of(context).pop(_selected),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Cari Kategori',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: const Color(0xFFF2F4F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kategori ${widget.type.label}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Flexible(
            child: shown.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Kategori tidak ditemukan.')),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final category in shown)
                        _ChoiceRow(
                          label: category.name,
                          leading: _CategoryIcon(category),
                          selected: _selected?.id == category.id,
                          onTap: () => setState(() => _selected = category),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon(this.category);

  final LogCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(category.colorHex) ?? const Color(0xFF667085);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(_iconFor(category.iconName), size: 16, color: Colors.white),
    );
  }
}

Color? _parseColor(String? hex) {
  if (hex == null || hex.length != 7) return null;
  final value = int.tryParse(hex.substring(1), radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// Nama ikon di database (`kategori.icon_name`) dipetakan ke ikon Flutter.
IconData _iconFor(String? name) => switch (name) {
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
