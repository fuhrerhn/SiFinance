import 'package:material_ui/material_ui.dart';

import '../../domain/category_spending.dart';
import 'dashboard_formats.dart';

Color categoryColor(SpendingCategory category) {
  final hex = category.colorHex;
  final rgb = hex != null && hex.length == 7 && hex.startsWith('#')
      ? int.tryParse(hex.substring(1), radix: 16)
      : null;
  if (rgb != null) return Color(0xff000000 | rgb);

  const colors = [
    Color(0xff004cff),
    Color(0xff008979),
    Color(0xff9647d6),
    Color(0xffcd6816),
    Color(0xffd64072),
    Color(0xff5366aa),
  ];
  return colors[category.id % colors.length];
}

class CategorySpendingList extends StatelessWidget {
  const CategorySpendingList({super.key, required this.spendings});

  final List<CategorySpending> spendings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final entry in spendings)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 12,
                  color: categoryColor(entry.category),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(entry.category.name)),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatRupiah(entry.total), textAlign: TextAlign.end),
                      Text(
                        formatFraction(entry.fraction),
                        style: theme.textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
