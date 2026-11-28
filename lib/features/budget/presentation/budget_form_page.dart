import 'package:material_ui/material_ui.dart';

import '../domain/budget.dart';
import '../domain/budget_period.dart';
import 'budget_format.dart';

/// Dipakai untuk Tambah Budget (budget == null) dan Edit Budget.
class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({
    super.key,
    required this.categories,
    required this.onSubmit,
    this.budget,
  });

  final List<BudgetCategory> categories;
  final Future<void> Function(BudgetInput input) onSubmit;
  final Budget? budget;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  late final _amount = TextEditingController(
    text: widget.budget == null
        ? ''
        : formatRupiah(widget.budget!.limitMinorUnits),
  );
  late int? _categoryId = widget.budget?.category.id;
  late BudgetPeriod? _period = widget.budget?.period;
  bool _saving = false;

  bool get _isEdit => widget.budget != null;
  bool get _valid =>
      _categoryId != null &&
      _period != null &&
      parseRupiahInput(_amount.text) > 0;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        BudgetInput(
          categoryId: _categoryId!,
          limitMinorUnits: parseRupiahInput(_amount.text),
          period: _period!,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget gagal disimpan. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colors.outlineVariant),
    );
    final decoration = InputDecoration(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: border,
      enabledBorder: border,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          _isEdit ? 'Edit Budget' : 'Tambah Budget',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Kategori'),
                          DropdownButtonFormField<int>(
                            initialValue: _categoryId,
                            isExpanded: true,
                            decoration: decoration.copyWith(
                              hintText: 'Tentukan kategori budget',
                            ),
                            items: [
                              for (final c in widget.categories)
                                DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _categoryId = value),
                          ),
                          const SizedBox(height: 16),
                          _label('Total Budget'),
                          TextField(
                            controller: _amount,
                            keyboardType: TextInputType.number,
                            inputFormatters: [RupiahInputFormatter()],
                            decoration: decoration.copyWith(hintText: 'Rp0'),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _label('Periode Budget'),
                          DropdownButtonFormField<BudgetPeriod>(
                            initialValue: _period,
                            isExpanded: true,
                            decoration: decoration.copyWith(
                              hintText: 'Tentukan periode budget',
                            ),
                            items: [
                              for (final p in BudgetPeriod.values)
                                DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => _period = value),
                          ),
                        ],
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _valid && !_saving ? _submit : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isEdit ? 'Simpan' : 'Tambah Kategori Budget'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
  );
}
