import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:tekber/features/manual_logging/data/manual_logging_repository.dart';
import 'package:tekber/features/manual_logging/domain/manual_transaction.dart';
import 'package:tekber/features/manual_logging/presentation/manual_logging_controller.dart';
import 'package:tekber/features/manual_logging/presentation/manual_logging_page.dart';
import 'package:tekber/features/manual_logging/presentation/widgets/amount_input.dart';

const food = LogCategory(
  id: 1,
  name: 'Makanan',
  type: TransactionType.expense,
);
const salary = LogCategory(id: 7, name: 'Gaji', type: TransactionType.income);

class _FakeRepository implements ManualLoggingRepository {
  final saved = <ManualTransaction>[];
  bool failSaving = false;

  @override
  Future<List<LogCategory>> loadCategories() async => [food, salary];

  @override
  Future<void> save(ManualTransaction transaction) async {
    if (failSaving) throw Exception('gagal');
    saved.add(transaction);
  }
}

ManualLoggingController _makeController(_FakeRepository repository) =>
    ManualLoggingController(repository, clock: () => DateTime(2026, 11, 21, 15));

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  group('ManualLoggingController', () {
    test('menolak nominal kosong dan kategori kosong', () async {
      final repository = _FakeRepository();
      final controller = _makeController(repository);
      await controller.loadCategories();

      expect(await controller.save(), isFalse);
      expect(controller.error, 'Nominal harus lebih dari Rp0.');

      controller.setAmount(10000);
      expect(await controller.save(), isFalse);
      expect(controller.error, 'Pilih kategori dulu.');
      expect(repository.saved, isEmpty);
    });

    test('menyimpan transaksi dan mengosongkan teks kosong menjadi null', () async {
      final repository = _FakeRepository();
      final controller = _makeController(repository);
      await controller.loadCategories();
      controller
        ..setAmount(10000)
        ..selectCategory(food)
        ..setLocation('  Supermarket ')
        ..setDescription('   ');

      expect(await controller.save(), isTrue);

      final transaction = repository.saved.single;
      expect(transaction.type, TransactionType.expense);
      expect(transaction.amount, 10000);
      expect(transaction.date, DateTime(2026, 11, 21));
      expect(transaction.category.id, 1);
      expect(transaction.location, 'Supermarket');
      expect(transaction.description, isNull);
      expect(transaction.paymentAccount, 'Tunai');
      expect(transaction.isPersonal, isTrue);
    });

    test('gagal menyimpan memberi pesan dan data tidak hilang', () async {
      final repository = _FakeRepository()..failSaving = true;
      final controller = _makeController(repository);
      await controller.loadCategories();
      controller
        ..setAmount(5000)
        ..selectCategory(food);

      expect(await controller.save(), isFalse);
      expect(controller.error, 'Gagal menyimpan transaksi. Coba lagi.');
      expect(controller.saving, isFalse);
      expect(controller.amount, 5000);
      expect(controller.category, food);
    });

    test('ganti tipe menghapus kategori yang tidak cocok', () async {
      final controller = _makeController(_FakeRepository());
      await controller.loadCategories();
      controller.selectCategory(food);

      controller.setType(TransactionType.income);

      expect(controller.category, isNull);
      expect(controller.categoriesForType, [salary]);
    });

    test('Tambah Lagi menyimpan tipe, tanggal, dan akun', () async {
      final controller = _makeController(_FakeRepository());
      await controller.loadCategories();
      controller
        ..setType(TransactionType.income)
        ..setDate(DateTime(2026, 11, 19))
        ..addAccount('OVO')
        ..setAmount(20000)
        ..selectCategory(salary);

      controller.resetForNext();

      expect(controller.amount, 0);
      expect(controller.category, isNull);
      expect(controller.type, TransactionType.income);
      expect(controller.date, DateTime(2026, 11, 19));
      expect(controller.account, 'OVO');
    });

    test('kategori gagal dimuat bisa dicoba lagi', () async {
      final repository = _BrokenCategoriesRepository();
      final controller = _makeController(repository);

      await controller.loadCategories();
      expect(controller.categoriesFailed, isTrue);

      repository.broken = false;
      await controller.loadCategories();
      expect(controller.categoriesFailed, isFalse);
      expect(controller.categoriesForType, [food]);
    });
  });

  group('input nominal', () {
    test('amountFromText mengambil angka dari teks rupiah', () {
      expect(amountFromText('Rp10.000'), 10000);
      expect(amountFromText(''), 0);
    });

    test('formatter menambah titik ribuan dan membatasi 12 digit', () {
      final formatter = RupiahInputFormatter();
      const empty = TextEditingValue.empty;

      final typed = formatter.formatEditUpdate(
        empty,
        const TextEditingValue(text: '1500000'),
      );
      expect(typed.text, 'Rp1.500.000');

      const full = TextEditingValue(text: 'Rp999.999.999.999');
      final tooLong = formatter.formatEditUpdate(
        full,
        const TextEditingValue(text: 'Rp999.999.999.9999'),
      );
      expect(tooLong, full);
    });
  });

  group('ManualLoggingPage', () {
    Future<void> openPage(
      WidgetTester tester,
      _FakeRepository repository, {
      VoidCallback? onSaved,
    }) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: ManualLoggingPage(repository: repository, onSaved: onSaved),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('mengisi form lalu Selesai menyimpan transaksi', (tester) async {
      final repository = _FakeRepository();
      var savedCalls = 0;
      await openPage(tester, repository, onSaved: () => savedCalls++);

      await tester.enterText(find.byType(TextField).first, '10000');
      await tester.tap(find.text('Tentukan kategori'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makanan'));
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(repository.saved, hasLength(1));
      expect(repository.saved.single.amount, 10000);
      expect(repository.saved.single.category.name, 'Makanan');
      expect(savedCalls, 1);
    });

    testWidgets('Selesai tanpa isian menampilkan pesan kesalahan', (tester) async {
      final repository = _FakeRepository();
      await openPage(tester, repository);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      expect(find.text('Nominal harus lebih dari Rp0.'), findsOneWidget);
      expect(repository.saved, isEmpty);
    });

    testWidgets('Tambah Lagi menyimpan lalu mengosongkan form', (tester) async {
      final repository = _FakeRepository();
      await openPage(tester, repository);

      await tester.enterText(find.byType(TextField).first, '25000');
      await tester.tap(find.text('Tentukan kategori'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Makanan'));
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tambah Lagi'));
      await tester.pumpAndSettle();

      expect(repository.saved, hasLength(1));
      expect(find.text('Transaksi tersimpan.'), findsOneWidget);
      expect(find.text('Tentukan kategori'), findsOneWidget);
      expect(find.text('Rp25.000'), findsNothing);
    });

    testWidgets('tipe Pemasukan hanya menampilkan kategori pemasukan', (
      tester,
    ) async {
      final repository = _FakeRepository();
      await openPage(tester, repository);

      await tester.tap(find.text('Pengeluaran'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Pemasukan'));
      await tester.pump();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tentukan kategori'));
      await tester.pumpAndSettle();

      expect(find.text('Gaji'), findsOneWidget);
      expect(find.text('Makanan'), findsNothing);
    });
  });
}

class _BrokenCategoriesRepository extends _FakeRepository {
  bool broken = true;

  @override
  Future<List<LogCategory>> loadCategories() async {
    if (broken) throw Exception('offline');
    return [food];
  }
}
