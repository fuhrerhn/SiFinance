import 'package:material_ui/material_ui.dart';

/// Chip bulat seperti "Pengeluaran" dan "Hari ini" di desain.
/// Kalau [selected] true, latar biru. Kalau [showArrow] true, ada panah bawah.
class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.selected = false,
    this.showArrow = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool selected;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final foreground = selected ? Colors.white : primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primary : Colors.white,
          border: Border.all(color: primary),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 18, color: foreground),
            ],
          ],
        ),
      ),
    );
  }
}
