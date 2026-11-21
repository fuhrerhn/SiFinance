import 'package:material_ui/material_ui.dart';

import '../data/dashboard_repository.dart';
import 'dashboard_controller.dart';
import 'widgets/category_expense_chart.dart';
import 'widgets/dashboard_state_views.dart';
import 'widgets/monthly_expense_chart.dart';
import 'widgets/period_filter.dart';
import 'widgets/total_expense_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.repository, this.onSignOut});

  final DashboardRepository repository;
  final VoidCallback? onSignOut;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final _controller = DashboardController(widget.repository)..reload();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final summary = _controller.summary;
          return RefreshIndicator(
            onRefresh: _controller.reload,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PeriodFilter(
                        period: _controller.period,
                        onChanged: _controller.selectPeriod,
                      ),
                      const SizedBox(height: 16),
                      if (_controller.isLoading)
                        const DashboardLoadingView()
                      else if (_controller.failed)
                        DashboardErrorView(onRetry: _controller.reload)
                      else if (summary != null) ...[
                        TotalExpenseCard(summary: summary),
                        const SizedBox(height: 16),
                        _Panel(child: MonthlyExpenseChart(summary: summary)),
                        const SizedBox(height: 16),
                        _Panel(
                          child: summary.categorySpendings.isEmpty
                              ? const DashboardEmptyView()
                              : CategoryExpenseChart(
                                  spendings: summary.categorySpendings,
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      margin: EdgeInsets.zero,
      color: colors.surface,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
