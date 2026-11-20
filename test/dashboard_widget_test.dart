import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tekber/features/dashboard/data/dashboard_repository.dart';
import 'package:tekber/features/dashboard/domain/category_spending.dart';
import 'package:tekber/features/dashboard/domain/dashboard_period.dart';
import 'package:tekber/features/dashboard/domain/dashboard_summary.dart';
import 'package:tekber/features/dashboard/presentation/dashboard_page.dart';

class _FakeRepository implements DashboardRepository {
  final periods = <DashboardPeriod>[];
  final pending = <Completer<DashboardSummary>>[];

  @override
  Future<DashboardSummary> load(DashboardPeriod period) {
    periods.add(period);
    final request = Completer<DashboardSummary>();
    pending.add(request);
    return request.future;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('id_ID'));

  testWidgets(
    'renders loading, retry, data, and empty under the active filter',
    (tester) async {
      final repository = _FakeRepository();
      final now = DateTime(2026, 2, 20);
      const category = SpendingCategory(
        id: 1,
        name: 'Makanan',
        colorHex: '#004CFF',
      );
      final transaction = DashboardTransaction(
        date: now,
        amountMinorUnits: 125000000,
        category: category,
        isExpense: true,
      );
      await tester.pumpWidget(
        MaterialApp(home: DashboardPage(repository: repository)),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(repository.periods, [DashboardPeriod.thisMonth]);

      repository.pending.first.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      expect(find.text('Pengeluaran gagal dimuat.'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.pending[1].complete(
        DashboardSummary.calculate(
          period: DashboardPeriod.thisMonth,
          now: now,
          periodTransactions: [transaction],
          trendTransactions: [transaction],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Total Pengeluaran'), findsOneWidget);
      expect(find.text('Rp1.250.000'), findsAtLeastNWidgets(1));
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('Makanan'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('Family Dashboard'), findsNothing);

      await tester.tap(find.text('Bulan ini'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tahun ini').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(repository.periods.last, DashboardPeriod.thisYear);
      repository.pending.last.complete(
        DashboardSummary.calculate(
          period: DashboardPeriod.thisYear,
          now: now,
          periodTransactions: [],
          trendTransactions: [transaction],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tahun ini'), findsOneWidget);
      expect(
        find.text('Belum ada pengeluaran pada periode ini.'),
        findsOneWidget,
      );
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    },
  );
}
