import 'package:material_ui/material_ui.dart';

import '../../domain/dashboard_period.dart';

class PeriodFilter extends StatelessWidget {
  const PeriodFilter({
    super.key,
    required this.period,
    required this.onChanged,
  });

  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<DashboardPeriod>(
      key: ValueKey(period),
      initialValue: period,
      decoration: const InputDecoration(
        labelText: 'Periode',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.calendar_today_outlined),
      ),
      items: [
        for (final option in DashboardPeriod.values)
          DropdownMenuItem(value: option, child: Text(option.label)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
