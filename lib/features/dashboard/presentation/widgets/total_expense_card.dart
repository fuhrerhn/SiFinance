import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../domain/dashboard_summary.dart';
import 'dashboard_formats.dart';

class TotalExpenseCard extends StatelessWidget {
  const TotalExpenseCard({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final start = summary.startDate;
    final end = summary.endDate;
    final format = DateFormat('d MMM y', 'id_ID');
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Pengeluaran',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                formatRupiah(summary.totalExpense),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                start != null && end != null
                    ? '${format.format(start)} – ${format.format(end)}'
                    : summary.selectedPeriod.label,
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
