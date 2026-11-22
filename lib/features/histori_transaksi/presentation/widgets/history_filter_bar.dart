import 'package:material_ui/material_ui.dart';

/// Dua chip di atas daftar: "Tanggal" dan "Kategori".
/// Chip yang filternya sedang aktif diberi latar biru muda.
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.dateActive,
    required this.categoryActive,
    required this.onDateTap,
    required this.onCategoryTap,
  });

  final bool dateActive;
  final bool categoryActive;
  final VoidCallback onDateTap;
  final VoidCallback onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _FilterChip(label: 'Tanggal', active: dateActive, onTap: onDateTap),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Kategori',
            active: categoryActive,
            onTap: onCategoryTap,
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: active ? primary.withValues(alpha: 0.08) : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: primary)),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: primary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 18, color: primary),
            ],
          ),
        ),
      ),
    );
  }
}
