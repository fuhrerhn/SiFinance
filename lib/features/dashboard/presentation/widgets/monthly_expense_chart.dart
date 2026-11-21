import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../domain/dashboard_summary.dart';
import 'dashboard_formats.dart';

class MonthlyExpenseChart extends StatelessWidget {
  const MonthlyExpenseChart({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final months = summary.monthlySpendings;
    final shortMonth = DateFormat('MMM', 'id_ID');
    final fullMonth = DateFormat('MMMM y', 'id_ID');
    final peak = months.map((month) => month.total).reduce(math.max);
    final targetStep = math.max(1, peak / 4);
    final magnitude = math.pow(10, (math.log(targetStep) / math.ln10).floor());
    final step = ((targetStep / magnitude).ceil() * magnitude).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pengeluaran per bulan', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Rata-rata 6 bulan: ${formatRupiah(summary.averageMonthlyExpense)}',
        ),
        const SizedBox(height: 20),
        Semantics(
          label: months
              .map(
                (month) =>
                    '${fullMonth.format(month.month)}: ${formatRupiah(month.total)}',
              )
              .join(', '),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: 4 * step,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: step,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: colors.outlineVariant, strokeWidth: 1),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipColor: (_) => colors.inverseSurface,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${fullMonth.format(months[group.x].month)}\n${formatRupiah(rod.toY)}',
                      TextStyle(color: colors.onInverseSurface),
                    ),
                  ),
                ),
                barGroups: [
                  for (final (index, month) in months.indexed)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: month.total,
                          width: 16,
                          color: colors.primary,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                ],
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: step,
                      reservedSize: 65,
                      getTitlesWidget: (value, _) => Text(
                        formatAxisRupiah(value),
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          shortMonth.format(months[value.toInt()].month),
                          style: theme.textTheme.labelSmall,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
