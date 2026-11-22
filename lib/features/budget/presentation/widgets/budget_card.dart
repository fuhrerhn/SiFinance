import 'package:material_ui/material_ui.dart';

import '../../domain/budget.dart';
import '../budget_format.dart';

class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.budget, required this.onEdit});

  final Budget budget;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final categoryColor = colorFromHex(
      budget.category.colorHex,
      colors.primary,
    );
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surface,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    iconForCategory(budget.category.iconName),
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    budget.category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  height: 24,
                  child: OutlinedButton(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Edit', style: TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _UsageBar(budget: budget),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _caption(context, formatBudgetDate(budget.range.start)),
                _caption(context, formatBudgetDate(budget.range.end)),
              ],
            ),
            const Divider(height: 24),
            _row(
              'Sisa Budget',
              formatRupiah(budget.remainingMinorUnits),
              bold: true,
              color: budget.isOverBudget ? colors.error : null,
            ),
            const SizedBox(height: 6),
            _row('Pengeluaran', formatRupiah(budget.spentMinorUnits)),
            const SizedBox(height: 6),
            _row('Total Budget', formatRupiah(budget.limitMinorUnits)),
          ],
        ),
      ),
    );
  }

  Widget _caption(BuildContext context, String text) => Text(
    text,
    style: TextStyle(
      fontSize: 10,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontSize: 13,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fill = budget.isOverBudget ? colors.error : colors.primary;
    final onFill = budget.fraction >= 0.35;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        height: 20,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: colors.surfaceContainerHighest),
            ),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: budget.fraction,
                child: ColoredBox(color: fill),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${budget.percent}% terpakai',
                    style: TextStyle(
                      fontSize: 10,
                      color: onFill ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
