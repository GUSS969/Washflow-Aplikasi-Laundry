import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/report/presentation/providers/report_provider.dart';
import '../../../../features/report/data/models/report_model.dart';
import '../../../../features/kasir/presentation/screens/order_detail_screen.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class OwnerDashboardTab extends ConsumerStatefulWidget {
  const OwnerDashboardTab({super.key});
  @override
  ConsumerState<OwnerDashboardTab> createState() => _OwnerDashboardTabState();
}

class _OwnerDashboardTabState extends ConsumerState<OwnerDashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(reportProvider.notifier).fetchDaily();
      ref.read(weeklyReportProvider.notifier).fetchWeekly();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final dailyAsync = ref.watch(reportProvider);
    final weeklyAsync = ref.watch(weeklyReportProvider);
    final today = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        await ref.read(reportProvider.notifier).fetchDaily();
        await ref.read(weeklyReportProvider.notifier).fetchWeekly();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Owner Workspace', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Halo, ${user?.name ?? 'Owner'}! 👋',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(today, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ),

          // Daily Stats
          SliverToBoxAdapter(
            child: dailyAsync.when(
              loading: () => const SizedBox(height: 200, child: LoadingWidget()),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ErrorWidget2(message: e.toString()),
              ),
              data: (report) {
                if (report == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 12),
                        child: Row(
                          children: [
                            Container(width: 3, height: 12, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            const Text('RINGKASAN HARI INI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMid, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.15,
                        children: [
                          StatCard(title: 'TOTAL ORDER', value: '${report.totalOrders}', icon: Icons.receipt_long_rounded, color: AppColors.primary, subtitle: 'Transaksi masuk'),
                          StatCard(title: 'DIPROSES', value: '${report.ordersProcessed}', icon: Icons.sync_rounded, color: AppColors.warning, subtitle: 'Sedang berjalan'),
                          StatCard(title: 'SELESAI', value: '${report.ordersCompleted}', icon: Icons.check_circle_outline_rounded, color: AppColors.success, subtitle: 'Selesai hari ini'),
                          StatCard(title: 'PENDAPATAN', value: formatCurrency(report.totalRevenue), icon: Icons.payments_rounded, color: const Color(0xFF9C27B0), subtitle: 'Pembayaran lunas'),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Weekly Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Row(
                      children: [
                        Container(width: 3, height: 12, decoration: BoxDecoration(color: const Color(0xFF9C27B0), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        const Text('GRAFIK PENDAPATAN 7 HARI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMid, letterSpacing: 1.0)),
                      ],
                    ),
                  ),
                  Container(
                    height: 220,
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: weeklyAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary), strokeWidth: 2)),
                      error: (_, __) => const Center(child: Text('Gagal memuat grafik', style: TextStyle(color: AppColors.textLight, fontSize: 13))),
                      data: (report) {
                        if (report == null || report.orders.isEmpty) {
                          return const Center(child: Text('Belum ada data minggu ini', style: TextStyle(color: AppColors.textLight, fontSize: 13)));
                        }
                        final now = DateTime.now();
                        final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
                        final revenueByDay = <String, double>{};
                        for (final day in days) {
                          revenueByDay[DateFormat('E', 'id_ID').format(day)] = 0.0;
                        }
                        for (final order in report.orders) {
                          if (order.paymentStatus == 'lunas') {
                            final key = DateFormat('E', 'id_ID').format(order.createdAt);
                            revenueByDay[key] = (revenueByDay[key] ?? 0) + order.totalPrice;
                          }
                        }
                        final entries = revenueByDay.entries.toList();
                        final maxVal = entries.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);

                        return BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxVal > 0 ? maxVal * 1.25 : 100000,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => AppColors.textDark,
                                tooltipBorder: BorderSide(color: AppColors.surface.withValues(alpha: 0.1), width: 1),
                                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                                  formatCurrency(rod.toY),
                                  const TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700, fontSize: 10),
                                ),
                              ),
                            ),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (v, _) {
                                    final i = v.toInt();
                                    if (i < 0 || i >= entries.length) return const SizedBox();
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(entries[i].key, style: const TextStyle(color: AppColors.textMid, fontSize: 10, fontWeight: FontWeight.w700)),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: maxVal > 0 ? maxVal / 3 : 50000,
                              getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 1),
                              drawVerticalLine: false,
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(
                              entries.length,
                              (i) => BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: entries[i].value,
                                    gradient: LinearGradient(
                                      colors: entries[i].value > 0
                                          ? AppColors.primaryGradient
                                          : [AppColors.divider, AppColors.divider],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                    width: 18,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                    backDrawRodData: BackgroundBarChartRodData(
                                      show: true,
                                      toY: maxVal > 0 ? maxVal * 1.25 : 100000,
                                      color: AppColors.background,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Orders Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
              child: Row(
                children: [
                  Container(width: 3, height: 12, decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  const Text('ORDER TERBARU HARI INI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMid, letterSpacing: 1.0)),
                ],
              ),
            ),
          ),

          // Order List
          dailyAsync.when(
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (report) {
              if (report == null || report.orders.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: EmptyState(
                      icon: Icons.receipt_long_rounded,
                      title: 'Belum Ada Transaksi',
                      subtitle: 'Transaksi hari ini akan muncul di sini.',
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Container(
                      decoration: AppTheme.cardDecoration(),
                      child: OrderListTile(
                        order: report.orders[i],
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: report.orders[i]))),
                      ),
                    ),
                  ),
                  childCount: report.orders.take(5).length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// Weekly report provider
class WeeklyReportNotifier extends StateNotifier<AsyncValue<ReportModel?>> {
  final Ref _ref;
  WeeklyReportNotifier(this._ref) : super(const AsyncValue.data(null));

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
}

final weeklyReportProvider =
    StateNotifierProvider<WeeklyReportNotifier, AsyncValue<ReportModel?>>((ref) => WeeklyReportNotifier(ref));