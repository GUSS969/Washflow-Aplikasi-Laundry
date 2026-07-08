import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/report_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ReportNotifier extends StateNotifier<AsyncValue<ReportModel?>> {
  final Ref _ref;

  ReportNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> fetchDaily() async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      final report = await api.getDailyReport();
      state = AsyncValue.data(report);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> fetchWeekly() async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      final report = await api.getWeeklyReport();
      state = AsyncValue.data(report);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> fetchMonthly() async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      final report = await api.getMonthlyReport();
      state = AsyncValue.data(report);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }

  Future<void> fetchYearly() async {
    state = const AsyncValue.loading();
    try {
      final api = _ref.read(apiServiceProvider);
      final report = await api.getYearlyReport();
      state = AsyncValue.data(report);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}

final reportProvider =
    StateNotifierProvider<ReportNotifier, AsyncValue<ReportModel?>>((ref) => ReportNotifier(ref));
