import 'package:material_ui/material_ui.dart';

import '../data/budget_repository.dart';
import '../domain/budget.dart';
import 'budget_controller.dart';
import 'budget_form_page.dart';
import 'widgets/budget_card.dart';
import 'widgets/budget_state_views.dart';

class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key, required this.repository});

  final BudgetRepository repository;

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  late final _controller = BudgetController(widget.repository)..reload();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm({Budget? budget}) async {
    if (_controller.isLoading || _controller.failed) return;
    // Satu kategori hanya boleh punya satu budget.
    final taken = {
      for (final b in _controller.budgets)
        if (b.id != budget?.id) b.category.id,
    };
    final categories = [
      for (final c in _controller.categories)
        if (!taken.contains(c.id)) c,
    ];
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BudgetFormPage(
          categories: categories,
          budget: budget,
          onSubmit: (input) => _controller.save(id: budget?.id, input: input),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLowest,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Budget',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Tambah', style: TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) return const BudgetLoadingView();
          if (_controller.failed) {
            return BudgetErrorView(onRetry: _controller.reload);
          }
          final budgets = _controller.budgets;
          if (budgets.isEmpty) {
            return BudgetEmptyView(onAdd: () => _openForm());
          }
          return RefreshIndicator(
            onRefresh: _controller.reload,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => BudgetCard(
                    budget: budgets[index],
                    onEdit: () => _openForm(budget: budgets[index]),
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
