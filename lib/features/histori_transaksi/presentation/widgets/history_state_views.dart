import 'package:material_ui/material_ui.dart';

/// Indikator saat halaman pertama sedang dimuat.
class HistoryLoadingView extends StatelessWidget {
  const HistoryLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

/// Pesan saat tidak ada transaksi.
class HistoryEmptyView extends StatelessWidget {
  const HistoryEmptyView({super.key, this.message = 'Belum ada transaksi'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.receipt_long, size: 48, color: Color(0xFF98A2B3)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}

/// Pesan error dengan tombol "Coba lagi".
class HistoryErrorView extends StatelessWidget {
  const HistoryErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFFD92D20)),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat histori transaksi.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}
