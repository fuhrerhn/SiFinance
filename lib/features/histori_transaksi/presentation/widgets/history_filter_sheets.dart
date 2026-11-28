import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/history_filter.dart';
import 'history_transaction_tile.dart';

/// Hasil sheet tanggal. start dan end sama-sama null berarti "hapus filter".
typedef HistoryDateChoice = ({DateTime? start, DateTime? end});

/// Hasil sheet kategori. id null berarti "hapus filter".
typedef HistoryCategoryChoice = ({int? id});

/// Nama grup kategori di sheet.
///
/// Desain Figma membagi kategori menjadi grup seperti "Kebutuhan Sehari-Hari"
/// dan "Rumah Tangga", tapi tabel kategori tidak punya kolom untuk itu.
/// Isi peta ini (slug -> nama grup) kalau tim sudah sepakat soal
/// pengelompokannya, misalnya: {'makanan': 'Kebutuhan Sehari-Hari'}.
/// Kategori yang slug-nya tidak ada di sini masuk ke grup "Pengeluaran"
/// atau "Pemasukan" sesuai group_name di database.
const _namaGrupKategori = <String, String>{};

String _namaGrup(HistoryCategory category) =>
    _namaGrupKategori[category.slug] ??
    (category.isIncome ? 'Pemasukan' : 'Pengeluaran');

/// Membuka sheet "Pilih Tanggal Transaksi".
/// Hasilnya null kalau pengguna menekan Batal atau menutup sheet.
Future<HistoryDateChoice?> showDateFilterSheet(
  BuildContext context, {
  required DateTime? currentStart,
  required DateTime? currentEnd,
  required DateTime today,
}) {
  return showModalBottomSheet<HistoryDateChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DateSheet(
      currentStart: currentStart,
      currentEnd: currentEnd,
      today: today,
    ),
  );
}

/// Membuka sheet "Pilih Kategori Transaksi".
/// Hasilnya null kalau pengguna menekan Batal atau menutup sheet.
Future<HistoryCategoryChoice?> showCategoryFilterSheet(
  BuildContext context, {
  required List<HistoryCategory> categories,
  required int? currentId,
}) {
  return showModalBottomSheet<HistoryCategoryChoice>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CategorySheet(categories: categories, currentId: currentId),
  );
}

/// Kerangka bersama: judul, isi, tombol utama, (tombol hapus), dan Batal.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
    required this.saveLabel,
    required this.onSave,
    this.onClear,
    this.clearLabel = 'Hapus filter',
  });

  final String title;
  final Widget child;
  final String saveLabel;
  final VoidCallback? onSave;
  final VoidCallback? onClear;
  final String clearLabel;

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
            if (onClear != null)
              TextButton(onPressed: onClear, child: Text(clearLabel)),
            FilledButton(onPressed: onSave, child: Text(saveLabel)),
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

/// Ikon radio di kanan, dipakai semua baris pilihan.
class _RadioIcon extends StatelessWidget {
  const _RadioIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_off,
      size: 20,
      color: selected ? primary : const Color(0xFF98A2B3),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet tanggal
// ---------------------------------------------------------------------------

class _DateSheet extends StatefulWidget {
  const _DateSheet({
    required this.currentStart,
    required this.currentEnd,
    required this.today,
  });

  final DateTime? currentStart;
  final DateTime? currentEnd;
  final DateTime today;

  @override
  State<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends State<_DateSheet> {
  /// Pilihan cepat sesuai desain: 7, 30, dan 90 hari terakhir.
  static const _presets = [7, 30, 90];

  late DateTime? _start = widget.currentStart;
  late DateTime? _end = widget.currentEnd;

  /// Tanggal N hari sebelum hari ini.
  DateTime _daysAgo(int days) => DateTime(
    widget.today.year,
    widget.today.month,
    widget.today.day - days,
  );

  /// Pilihan cepat yang cocok dengan rentang sekarang (null kalau rentang manual).
  int? get _selectedPreset {
    for (final days in _presets) {
      if (_start == _daysAgo(days) && _end == widget.today) return days;
    }
    return null;
  }

  bool get _rangeIsBackwards =>
      _start != null && _end != null && _end!.isBefore(_start!);

  bool get _canApply => _start != null && _end != null && !_rangeIsBackwards;

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? widget.today,
      firstDate: DateTime(2020),
      lastDate: widget.today,
    );
    if (picked == null || !mounted) return;
    final day = DateTime(picked.year, picked.month, picked.day);
    setState(() {
      if (isStart) {
        _start = day;
      } else {
        _end = day;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final longFormat = DateFormat('EEEE, d MMMM y', 'id_ID');
    final fieldFormat = DateFormat('E, d MMMM y', 'id_ID');
    final selectedPreset = _selectedPreset;
    return _SheetFrame(
      title: 'Pilih Tanggal Transaksi',
      saveLabel: 'Pasang Filter',
      onSave: _canApply
          ? () => Navigator.of(
              context,
            ).pop<HistoryDateChoice>((start: _start, end: _end))
          : null,
      // Tombol hapus hanya muncul kalau filter tanggal sedang aktif.
      onClear: widget.currentStart != null && widget.currentEnd != null
          ? () => Navigator.of(
              context,
            ).pop<HistoryDateChoice>((start: null, end: null))
          : null,
      clearLabel: 'Hapus filter tanggal',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final days in _presets)
              _PresetRow(
                label: '$days hari terakhir',
                subtitle:
                    '${longFormat.format(_daysAgo(days))} - '
                    '${longFormat.format(widget.today)}',
                selected: selectedPreset == days,
                onTap: () => setState(() {
                  _start = _daysAgo(days);
                  _end = widget.today;
                }),
              ),
            const SizedBox(height: 16),
            const Text(
              'Atur tanggal',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Dari',
                    value: _start == null
                        ? 'Pilih tanggal'
                        : fieldFormat.format(_start!),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DateField(
                    label: 'Sampai',
                    value: _end == null
                        ? 'Pilih tanggal'
                        : fieldFormat.format(_end!),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            if (_rangeIsBackwards)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Tanggal "Sampai" tidak boleh sebelum "Dari".',
                  style: TextStyle(fontSize: 12, color: Color(0xFFD92D20)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Satu pilihan cepat: judul, keterangan rentang, dan ikon radio.
class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            _RadioIcon(selected: selected),
          ],
        ),
      ),
    );
  }
}

/// Kolom abu-abu "Dari" atau "Sampai". Kalau ditekan membuka kalender.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2F4F7),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sheet kategori
// ---------------------------------------------------------------------------

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({required this.categories, required this.currentId});

  final List<HistoryCategory> categories;
  final int? currentId;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late int? _selectedId = widget.currentId;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final shown = widget.categories
        .where((category) => category.name.toLowerCase().contains(query))
        .toList();
    // Pengeluaran ditampilkan lebih dulu, baru pemasukan.
    final ordered = [
      ...shown.where((category) => !category.isIncome),
      ...shown.where((category) => category.isIncome),
    ];
    final groups = <String, List<HistoryCategory>>{};
    for (final category in ordered) {
      groups.putIfAbsent(_namaGrup(category), () => []).add(category);
    }

    final rows = <Widget>[];
    for (final entry in groups.entries) {
      if (rows.isNotEmpty) rows.add(const Divider(height: 24));
      rows.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(
            entry.key,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      );
      for (final category in entry.value) {
        rows.add(
          InkWell(
            onTap: () => setState(() => _selectedId = category.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  HistoryCategoryIcon(
                    iconName: category.iconName,
                    colorHex: category.colorHex,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  _RadioIcon(selected: _selectedId == category.id),
                ],
              ),
            ),
          ),
        );
      }
    }

    return _SheetFrame(
      title: 'Pilih Kategori Transaksi',
      saveLabel: 'Simpan',
      onSave: () =>
          Navigator.of(context).pop<HistoryCategoryChoice>((id: _selectedId)),
      // Tombol hapus hanya muncul kalau filter kategori sedang aktif.
      onClear: widget.currentId != null
          ? () => Navigator.of(
              context,
            ).pop<HistoryCategoryChoice>((id: null))
          : null,
      clearLabel: 'Hapus filter kategori',
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
          const SizedBox(height: 4),
          Flexible(
            child: rows.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Kategori tidak ditemukan.')),
                  )
                : ListView(shrinkWrap: true, children: rows),
          ),
        ],
      ),
    );
  }
}
