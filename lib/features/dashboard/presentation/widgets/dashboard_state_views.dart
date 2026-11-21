import 'package:material_ui/material_ui.dart';

class DashboardLoadingView extends StatelessWidget {
  const DashboardLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(semanticsLabel: 'Memuat pengeluaran'),
      ),
    );
  }
}

class DashboardErrorView extends StatelessWidget {
  const DashboardErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Pengeluaran gagal dimuat.', textAlign: TextAlign.center),
        TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
      ],
    );
  }
}

class DashboardEmptyView extends StatelessWidget {
  const DashboardEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Belum ada pengeluaran pada periode ini.');
  }
}
