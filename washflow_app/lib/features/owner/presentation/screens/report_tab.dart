import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/storage/token_manager.dart';
import '../../../../features/report/presentation/providers/report_provider.dart';
import '../../../../features/kasir/presentation/screens/order_detail_screen.dart';

class ReportTab extends ConsumerStatefulWidget {
  const ReportTab({super.key});
  @override
  ConsumerState<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends ConsumerState<ReportTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTab = 0;

  final List<String> _labels = ['Harian', 'Mingguan', 'Bulanan', 'Tahunan'];
  final List<String> _periods = ['daily', 'weekly', 'monthly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
        _fetchForTab(_tabController.index);
      }
    });
    // Load daily on first open
    Future.microtask(() => ref.read(reportProvider.notifier).fetchDaily());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _fetchForTab(int idx) {
    final notifier = ref.read(reportProvider.notifier);
    switch (idx) {
      case 0: notifier.fetchDaily(); break;
      case 1: notifier.fetchWeekly(); break;
      case 2: notifier.fetchMonthly(); break;
      case 3: notifier.fetchYearly(); break;
    }
  }

  Future<void> _downloadPdf() async {
    try {
      final token = await TokenManager.getToken();
      final period = _periods[_currentTab];
      final url = '${AppConstants.baseUrl}/reports/$period?format=pdf&token=$token';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat membuka PDF. Pastikan ada aplikasi PDF viewer.'), backgroundColor: AppColors.danger));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textLight,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, fontFamily: 'Poppins'),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13, fontFamily: 'Poppins'),
              tabs: _labels.map((l) => Tab(text: l)).toList(),
            ),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => ErrorWidget2(message: 'Gagal memuat laporan', onRetry: () => _fetchForTab(_currentTab)),
              data: (report) {
                if (report == null) return const LoadingWidget();
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => _fetchForTab(_currentTab),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Period info
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Text('${report.startDate} – ${report.endDate}', style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),

                        // Summary Cards
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: GridView.count(
                            crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                            childAspectRatio: 1.3,
                            children: [
                              StatCard(title: 'TOTAL ORDER', value: '${report.totalOrders}', icon: Icons.receipt_long_rounded, color: AppColors.primary),
                              StatCard(title: 'DIPROSES', value: '${report.ordersProcessed}', icon: Icons.sync_rounded, color: AppColors.warning),
                              StatCard(title: 'SELESAI', value: '${report.ordersCompleted}', icon: Icons.check_circle_rounded, color: AppColors.success),
                              StatCard(title: 'PENDAPATAN', value: formatCurrency(report.totalRevenue), icon: Icons.payments_rounded, color: const Color(0xFF9C27B0)),
                            ],
                          ),
                        ),

                        // Orders list header
                        Container(
                          color: AppColors.surface,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('DAFTAR ORDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                              Text('${report.orders.length} order', style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
                            ],
                          ),
                        ),
                        
                        // Orders List
                        if (report.orders.isEmpty)
                          Container(
                            color: AppColors.surface,
                            padding: const EdgeInsets.all(32),
                            child: const EmptyState(icon: Icons.receipt_long_outlined, title: 'Tidak Ada Data', subtitle: 'Tidak ada transaksi pada periode ini.'),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: AppTheme.cardDecoration(),
                              child: Column(
                                children: report.orders.map((o) => OrderListTile(
                                  order: o,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o))),
                                )).toList(),
                              ),
                            ),
                          ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _downloadPdf,
        icon: const Icon(Icons.download_rounded),
        label: const Text('Unduh Laporan PDF', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
