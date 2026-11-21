import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../data/manual_logging_repository.dart';
import '../domain/manual_transaction.dart';
import 'manual_logging_controller.dart';
import 'widgets/amount_input.dart';
import 'widgets/logging_sheets.dart';
import 'widgets/option_chip.dart';

class ManualLoggingPage extends StatefulWidget {
  const ManualLoggingPage({super.key, required this.repository, this.onSaved});

  final ManualLoggingRepository repository;

  /// Dipanggil setiap kali transaksi berhasil tersimpan, misalnya untuk
  /// memuat ulang dashboard.
  final VoidCallback? onSaved;

  @override
  State<ManualLoggingPage> createState() => _ManualLoggingPageState();
}

class _ManualLoggingPageState extends State<ManualLoggingPage> {
  late final _controller = ManualLoggingController(widget.repository)
    ..loadCategories();
  final _amountField = TextEditingController();
  final _locationField = TextEditingController();
  final _descriptionField = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _amountField.dispose();
    _locationField.dispose();
    _descriptionField.dispose();
    super.dispose();
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature segera hadir.')));
  }

  Future<void> _pickType() async {
    final picked = await showTypeSheet(context, _controller.type);
    if (picked != null) _controller.setType(picked);
  }

  Future<void> _pickDate() async {
    final picked = await showDateSheet(
      context,
      current: _controller.date,
      today: _controller.today,
    );
    if (picked != null) _controller.setDate(picked);
  }

  Future<void> _pickCategory() async {
    if (_controller.categoriesFailed) {
      await _controller.loadCategories();
      return;
    }
    final picked = await showCategorySheet(
      context,
      categories: _controller.categoriesForType,
      current: _controller.category,
      type: _controller.type,
    );
    if (picked != null) _controller.selectCategory(picked);
  }

  Future<void> _addAccount() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddAccountDialog(),
    );
    if (name != null) _controller.addAccount(name);
  }

  /// Menyimpan lalu menjalankan [afterSave] kalau berhasil.
  Future<void> _save(VoidCallback afterSave) async {
    FocusScope.of(context).unfocus();
    final saved = await _controller.save();
    if (!saved || !mounted) return;
    widget.onSaved?.call();
    afterSave();
  }

  void _finish() => Navigator.of(context).maybePop();

  void _addAnother() {
    _amountField.clear();
    _locationField.clear();
    _descriptionField.clear();
    _controller.resetForNext();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaksi tersimpan.')));
  }

  String _dateLabel() {
    final date = _controller.date;
    if (date == _controller.today) return 'Hari ini';
    return DateFormat('d MMM y', 'id_ID').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => Column(
            children: [
              _Header(
                onBack: () => Navigator.of(context).maybePop(),
                onUpload: () => _comingSoon('Upload struk'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Theme(
                        // Kolom isian dengan garis tepi, seperti di desain.
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: InputDecorationTheme(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFFD0D5DD),
                              ),
                            ),
                          ),
                        ),
                        child: _buildForm(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final category = _controller.category;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OptionChip(
                label: _controller.type.label,
                icon: _controller.type == TransactionType.expense
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
                showArrow: true,
                onTap: _pickType,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OptionChip(
                label: _dateLabel(),
                icon: Icons.calendar_today,
                showArrow: true,
                onTap: _pickDate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _comingSoon('Catat menggunakan AI'),
          icon: const Icon(Icons.mic, size: 18),
          label: const Text('Catat Menggunakan AI'),
        ),
        const SizedBox(height: 32),
        AmountInput(controller: _amountField, onChanged: _controller.setAmount),
        const SizedBox(height: 32),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final account in _controller.accounts)
              OptionChip(
                label: account,
                selected: _controller.account == account,
                onTap: () => _controller.selectAccount(account),
              ),
            OptionChip(
              label: 'Tambah Akun',
              icon: Icons.add,
              onTap: _addAccount,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CategoryField(
          label: category?.name,
          loading: _controller.loadingCategories,
          failed: _controller.categoriesFailed,
          onTap: _pickCategory,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _locationField,
          onChanged: _controller.setLocation,
          decoration: const InputDecoration(
            hintText: 'Belanja dimana? (cth: pasar)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionField,
          onChanged: _controller.setDescription,
          decoration: const InputDecoration(
            hintText: 'Deskripsi (cth: beli buah)',
          ),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: const Text('Tandai sebagai transaksi pribadi'),
          value: _controller.isPersonal,
          onChanged: _controller.setPersonal,
        ),
        if (_controller.error case final error?)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _controller.saving ? null : () => _save(_finish),
          child: _controller.saving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Selesai'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _controller.saving ? null : () => _save(_addAnother),
          child: const Text('Tambah Lagi'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onUpload});

  final VoidCallback onBack;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
          const Expanded(
            child: Text(
              'Manual Logging',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ),
          OptionChip(
            label: 'Upload',
            icon: Icons.add,
            selected: true,
            onTap: onUpload,
          ),
        ],
      ),
    );
  }
}

/// Kolom kategori yang kelihatan seperti dropdown dan membuka bottom sheet.
class _CategoryField extends StatelessWidget {
  const _CategoryField({
    required this.label,
    required this.loading,
    required this.failed,
    required this.onTap,
  });

  final String? label;
  final bool loading;
  final bool failed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = failed
        ? 'Kategori gagal dimuat. Ketuk untuk coba lagi.'
        : loading
        ? 'Memuat kategori...'
        : label ?? 'Tentukan kategori';
    final hasValue = label != null && !failed && !loading;
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: hasValue ? null : const Color(0xFF667085),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }
}

class _AddAccountDialog extends StatefulWidget {
  const _AddAccountDialog();

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Akun'),
      content: TextField(
        controller: _field,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'cth: OVO, BCA'),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_field.text),
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}
