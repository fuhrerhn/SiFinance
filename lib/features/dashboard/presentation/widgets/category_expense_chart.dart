import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../domain/category_spending.dart';
import 'category_spending_list.dart';

class CategoryExpenseChart extends StatelessWidget {
  const CategoryExpenseChart({super.key, required this.spendings});

  final List<CategorySpending> spendings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengeluaran per kategori',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ExcludeSemantics(
          child: SizedBox(
            height: 176,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 1,
                sections: [
                  for (final entry in spendings)
                    PieChartSectionData(
                      value: entry.total,
                      color: categoryColor(entry.category),
                      radius: 38,
                      showTitle: false,
                    ),
                ],
              ),
            ),
          ),
        ),
        CategorySpendingList(spendings: spendings),
      ],
    );
  }
}
