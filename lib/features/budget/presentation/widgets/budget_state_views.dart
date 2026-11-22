import 'package:material_ui/material_ui.dart';

class BudgetLoadingView extends StatelessWidget {
  const BudgetLoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class BudgetErrorView extends StatelessWidget {
  const BudgetErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Budget gagal dimuat.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

class BudgetEmptyView extends StatelessWidget {
  const BudgetEmptyView({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Belum ada budget.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAdd, child: const Text('Tambah Budget')),
        ],
      ),
    );
  }
}
