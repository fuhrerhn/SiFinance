import '../domain/dashboard_period.dart';
import '../domain/dashboard_summary.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> load(DashboardPeriod period);
}
