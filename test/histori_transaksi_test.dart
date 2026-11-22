import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tekber/features/histori_transaksi/data/histori_transaksi_repository.dart';
import 'package:tekber/features/histori_transaksi/domain/history_day_group.dart';
import 'package:tekber/features/histori_transaksi/domain/history_filter.dart';
import 'package:tekber/features/histori_transaksi/domain/history_transaction.dart';
import 'package:tekber/features/histori_transaksi/presentation/histori_transaksi_controller.dart';
import 'package:tekber/features/histori_transaksi/presentation/histori_transaksi_page.dart';

const _food = HistoryCategory(
  id: 1,
  name: 'Makanan',
  slug: 'makanan',
  isIncome: false,
);
const _transport = HistoryCategory(
  id: 2,
  name: 'Transportasi',
  slug: 'transportasi',
  isIncome: false,
);

/// Satu transaksi contoh. Kategori 1 = makanan, 2 = transportasi, 3 = gaji.
HistoryTransaction _tx(
  String id,
  DateTime date,
  num amount, {
  int categoryId = 1,
  HistoryType type = HistoryType.expense,
  String name = 'Makanan',
  String? description,
}) => HistoryTransaction(
  id: id,
  type: type,
  date: date,
  amount: amount,
  categoryId: categoryId,
  categoryName: name,
  description: description,
);

/// Repository palsu: tidak memakai Supabase, datanya dari daftar di konstruktor.
class _FakeRepository implements HistoriTransaksiRepository {
  _FakeRepository(this.data);

  final List<HistoryTransaction> data;

  /// Filter dan offset yang diterima, untuk diperiksa di tes.
  final filters = <HistoryFilter>[];
  final offsets = <int>[];

  bool failLoading = false;

  /// Kalau > 0, halaman berikutnya sengaja mengulang beberapa baris terakhir
  /// dari halaman sebelumnya (meniru data yang bergeser saat dimuat).
  int overlapBy = 0;

  @override
  Future<List<HistoryTransaction>> load(
    HistoryFilter filter, {
    required int offset,
    required int limit,
  }) async {
    if (failLoading) throw Exception('gagal');
    filters.add(filter);
    offsets.add(offset);
    final matching = data
        .where(
          (t) => filter.categoryId == null || t.categoryId == filter.categoryId,
        )
        .toList();
    final start = math.max(0, offset - overlapBy);
    return matching.skip(start).take(limit).toList();
  }

  @override
  Future<List<HistoryCategory>> loadCategories() async => [_food, _transport];
}

// Tanggal tetap supaya "Hari ini" dan "Kemarin" tidak bergantung jam asli.
final _now = DateTime(2026, 11, 22, 15);

HistoriTransaksiController _makeController(_FakeRepository repository) =>
    HistoriTransaksiController(repository, clock: () => _now);

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('pengelompokan per hari', () {
    final repository = _FakeRepository([
      _tx('a', DateTime(2026, 11, 22), 25000),
      _tx('b', DateTime(2026, 11, 22), 45000),
      // Pemasukan tidak boleh ikut dihitung di total hari.
      _tx(
        'c',
        DateTime(2026, 11, 22),
        500000,
        categoryId: 3,
        type: HistoryType.income,
        name: 'Gaji',
      ),
      _tx('d', DateTime(2026, 11, 21), 20000),
      _tx('e', DateTime(2026, 3, 12), 25000),
      _tx('f', DateTime(2026, 3, 12), 100000),
    ]);

    test('label Hari ini, Kemarin, dan tanggal lengkap', () async {
      final controller = _makeController(repository);
      await controller.load();

      final labels = [
        for (final group in controller.groups)
          dayLabel(group.date, controller.today),
      ];
      expect(labels, ['Hari ini', 'Kemarin', 'Kamis 12 Maret 2026']);
    });

    test('total per hari hanya menghitung pengeluaran', () async {
      final controller = _makeController(repository);
      await controller.load();

      final totals = [for (final group in controller.groups) group.totalExpense];
      expect(totals, [70000, 20000, 125000]);
    });

    test('groupByDay mengurutkan hari dari yang terbaru', () {
      final groups = groupByDay([
        _tx('x', DateTime(2026, 3, 12), 1000),
        _tx('y', DateTime(2026, 11, 22), 1000),
      ]);
      expect(groups.first.date, DateTime(2026, 11, 22));
      expect(groups.last.date, DateTime(2026, 3, 12));
    });
  });

  group('HistoriTransaksiController', () {
    test('filter kategori mengirim categoryId ke repository', () async {
      final repository = _FakeRepository([
        _tx('a', DateTime(2026, 11, 22), 25000),
        _tx('b', DateTime(2026, 11, 22), 40000, categoryId: 2, name: 'Transportasi'),
      ]);
      final controller = _makeController(repository);
      await controller.load();
      expect(controller.items, hasLength(2));

      await controller.setCategory(2);

      expect(repository.filters.last.categoryId, 2);
      expect(controller.items.single.categoryId, 2);
      expect(controller.filter.hasCategory, isTrue);
    });

    test('filter tanggal mengirim rentang ke repository', () async {
      final repository = _FakeRepository([_tx('a', DateTime(2026, 11, 22), 1)]);
      final controller = _makeController(repository);
      await controller.load();

      await controller.setDateRange(DateTime(2026, 11, 15), DateTime(2026, 11, 22));

      expect(repository.filters.last.start, DateTime(2026, 11, 15));
      expect(repository.filters.last.end, DateTime(2026, 11, 22));

      await controller.setDateRange(null, null);
      expect(controller.filter.hasDate, isFalse);
    });

    test('tanpa transaksi, state menjadi kosong', () async {
      final controller = _makeController(_FakeRepository([]));
      expect(controller.loading, isTrue);

      await controller.load();

      expect(controller.isEmpty, isTrue);
      expect(controller.failed, isFalse);
      expect(controller.groups, isEmpty);
    });

    test('gagal memuat memberi state error, lalu bisa dicoba lagi', () async {
      final repository = _FakeRepository([_tx('a', DateTime(2026, 11, 22), 1)])
        ..failLoading = true;
      final controller = _makeController(repository);

      await controller.load();
      expect(controller.failed, isTrue);
      expect(controller.loading, isFalse);
      expect(controller.items, isEmpty);

      repository.failLoading = false;
      await controller.load();
      expect(controller.failed, isFalse);
      expect(controller.items, hasLength(1));
    });

    test('muat lebih banyak menambah daftar tanpa duplikat', () async {
      final repository = _FakeRepository([
        for (var i = 0; i < 35; i++) _tx('id$i', DateTime(2026, 11, 22), 1000),
      ]);
      final controller = _makeController(repository);

      await controller.load();
      expect(controller.items, hasLength(30));
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.items, hasLength(35));
      expect(controller.items.map((t) => t.id).toSet(), hasLength(35));
      expect(controller.hasMore, isFalse);
      expect(repository.offsets, [0, 30]);
    });

    test('baris yang diulang repository tidak dimasukkan dua kali', () async {
      final repository = _FakeRepository([
        for (var i = 0; i < 35; i++) _tx('id$i', DateTime(2026, 11, 22), 1000),
      ])..overlapBy = 1;
      final controller = _makeController(repository);

      await controller.load();
      await controller.loadMore();

      expect(controller.items, hasLength(35));
      expect(controller.items.map((t) => t.id).toSet(), hasLength(35));
    });
  });

  group('HistoriTransaksiPage', () {
    Future<void> openPage(
      WidgetTester tester,
      _FakeRepository repository,
    ) async {
      // Lebar 360 piksel, seperti HP kecil.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(home: HistoriTransaksiPage(repository: repository)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('tanpa transaksi menampilkan pesan kosong', (tester) async {
      await openPage(tester, _FakeRepository([]));

      expect(find.text('Belum ada transaksi'), findsOneWidget);
    });

    testWidgets('error menampilkan pesan dan Coba lagi memuat ulang', (
      tester,
    ) async {
      final repository = _FakeRepository([
        _tx('a', DateTime.now(), 25000, description: 'bensin motor'),
      ])..failLoading = true;
      await openPage(tester, repository);

      expect(find.text('Gagal memuat histori transaksi.'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);

      repository.failLoading = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(find.text('Gagal memuat histori transaksi.'), findsNothing);
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('bensin motor'), findsOneWidget);
    });

    testWidgets('teks panjang tidak overflow di lebar 360', (tester) async {
      final repository = _FakeRepository([
        _tx(
          'a',
          DateTime.now(),
          12345678,
          name: 'Kebutuhan Rumah Tangga dan Perlengkapan Rumah',
          description:
              'Belanja bulanan di supermarket dekat rumah bersama keluarga besar',
        ),
      ]);
      await openPage(tester, repository);

      expect(tester.takeException(), isNull);
      expect(find.text('Hari ini'), findsOneWidget);
      expect(find.text('-Rp 12.345.678'), findsWidgets);
    });

    testWidgets('Muat lebih banyak menambah transaksi lalu tombolnya hilang', (
      tester,
    ) async {
      final repository = _FakeRepository([
        for (var i = 0; i < 35; i++) _tx('id$i', DateTime.now(), 1000),
      ]);
      await openPage(tester, repository);

      await tester.scrollUntilVisible(find.text('Muat lebih banyak'), 300);
      await tester.tap(find.text('Muat lebih banyak'));
      await tester.pumpAndSettle();

      expect(repository.offsets, [0, 30]);
      expect(find.text('Muat lebih banyak'), findsNothing);
    });
  });
}
