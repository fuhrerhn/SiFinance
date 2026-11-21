import 'package:flutter/foundation.dart';

import '../data/dashboard_repository.dart';
import '../domain/dashboard_period.dart';
import '../domain/dashboard_summary.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._repository);

  final DashboardRepository _repository;
  DashboardPeriod _period = DashboardPeriod.thisMonth;
  DashboardSummary? _summary;
  bool _isLoading = true;
  bool _failed = false;
  int _request = 0;

  DashboardPeriod get period => _period;
  DashboardSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  bool get failed => _failed;

  Future<void> selectPeriod(DashboardPeriod period) async {
    if (_period == period) return;
    _period = period;
    await reload();
  }

  Future<void> reload() async {
    final request = ++_request;
    _isLoading = true;
    _failed = false;
    _summary = null;
    notifyListeners();
    try {
      final summary = await _repository.load(_period);
      if (_request != request) return;
      _summary = summary;
    } catch (_) {
      if (_request != request) return;
      _failed = true;
    }
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _request++;
    super.dispose();
  }
}
