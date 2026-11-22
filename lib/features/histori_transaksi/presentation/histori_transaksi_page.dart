import 'package:material_ui/material_ui.dart';

import '../data/histori_transaksi_repository.dart';
import 'histori_transaksi_controller.dart';
import 'widgets/history_day_section.dart';
import 'widgets/history_filter_bar.dart';
import 'widgets/history_filter_sheets.dart';
import 'widgets/history_state_views.dart';

/// Layar "Histori Transaksi".
///
/// [onBack] dipanggil saat panah kembali ditekan. Kalau kosong, layar
/// ditutup dengan Navigator.
class HistoriTransaksiPage extends StatefulWidget {
  const HistoriTransaksiPage({
    super.key,
    required this.repository,
    this.onBack,
  });

  final HistoriTransaksiRepository repository;
  final VoidCallback? onBack;

  @override
  State<HistoriTransaksiPage> createState() => _HistoriTransaksiPageState();
}

class _HistoriTransaksiPageState extends State<HistoriTransaksiPage> {
  late final HistoriTransaksiController _controller =
      HistoriTransaksiController(widget.repository);

  @override
  void initState() {
    super.initState();
    _controller.load();
    _controller.loadCategories();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDateSheet() async {
    final choice = await showDateFilterSheet(
      context,
      currentStart: _controller.filter.start,
      currentEnd: _controller.filter.end,
      today: _controller.today,
    );
    if (choice == null) return;
    await _controller.setDateRange(choice.start, choice.end);
  }

  Future<void> _openCategorySheet() async {
    // Kalau kategori belum berhasil dimuat, coba muat sekali lagi.
    if (_controller.categories.isEmpty) await _controller.loadCategories();
    if (!mounted) return;
    if (_controller.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori belum bisa dimuat. Coba lagi nanti.'),
        ),
      );
      return;
    }
    final choice = await showCategoryFilterSheet(
      context,
      categories: _controller.categories,
      currentId: _controller.filter.categoryId,
    );
    if (choice == null) return;
    await _controller.setCategory(choice.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Histori Transaksi',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Column(
          children: [
            HistoryFilterBar(
              dateActive: _controller.filter.hasDate,
              categoryActive: _controller.filter.hasCategory,
              onDateTap: _openDateSheet,
              onCategoryTap: _openCategorySheet,
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.loading) return const HistoryLoadingView();
    if (_controller.failed) {
      return HistoryErrorView(onRetry: _controller.load);
    }

    // Daftar dan tampilan kosong sama-sama bisa ditarik untuk memuat ulang.
    final today = _controller.today;
    return RefreshIndicator(
      onRefresh: () => _controller.load(showLoading: false),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (_controller.isEmpty)
            HistoryEmptyView(
              message: _controller.filter.isActive
                  ? 'Tidak ada transaksi yang cocok dengan filter.'
                  : 'Belum ada transaksi',
            )
          else
            for (final group in _controller.groups)
              HistoryDaySection(group: group, today: today),
          if (_controller.hasMore) _buildLoadMore(),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Column(
      children: [
        if (_controller.loadMoreFailed)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Gagal memuat transaksi berikutnya.',
              style: TextStyle(fontSize: 12, color: Color(0xFFD92D20)),
            ),
          ),
        OutlinedButton(
          onPressed: _controller.loadingMore ? null : _controller.loadMore,
          child: _controller.loadingMore
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Muat lebih banyak'),
        ),
      ],
    );
  }
}
