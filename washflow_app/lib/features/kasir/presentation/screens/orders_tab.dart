import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';

import 'order_detail_screen.dart';

class OrdersTab extends ConsumerStatefulWidget {
  const OrdersTab({super.key});
  @override
  ConsumerState<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<OrdersTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Maps tab index to status values
  final _tabs = [
    {'label': 'Antrian', 'status': 'diterima'},
    {'label': 'Proses', 'status': 'proses'},
    {'label': 'Siap Diambil', 'status': 'selesai'},
    {'label': 'Selesai', 'status': 'sudah_diambil'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    Future.microtask(() => ref.read(orderProvider.notifier).fetchOrders());
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref.read(orderProvider.notifier).fetchOrders(
          status: _tabs[_tabController.index]['status'],
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);

    return Column(
      children: [
        // Tab bar
        Container(
          color: AppColors.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Poppins'),
            unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400, fontFamily: 'Poppins'),
            tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
          ),
        ),
        Expanded(
          child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => ErrorWidget2(
              message: 'Gagal memuat transaksi',
              onRetry: () => ref.read(orderProvider.notifier).fetchOrders(
                status: _tabs[_tabController.index]['status'],
              ),
            ),
            data: (orders) {
              if (orders.isEmpty) {
                return const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Tidak Ada Transaksi',
                  subtitle: 'Belum ada transaksi untuk status ini.',
                );
              }
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => ref.read(orderProvider.notifier).fetchOrders(
                  status: _tabs[_tabController.index]['status'],
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) => _SindryOrderCard(
                    order: orders[i],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: orders[i])),
                    ).then((_) => ref.read(orderProvider.notifier).fetchOrders(
                      status: _tabs[_tabController.index]['status'],
                    )),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SindryOrderCard extends StatelessWidget {
  final dynamic order;
  final VoidCallback onTap;
  const _SindryOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currency = RegExp(r'(\d)(?=(\d{3})+(?!\d))');
    String formatRp(double v) => 'Rp ' + v.toStringAsFixed(0).replaceAllMapped(currency, (m) => '${m[1]}.');

    final statusColor = _statusColor(order.status);
    final payColor = order.paymentStatus == 'lunas' ? AppColors.success : AppColors.danger;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(order.invoice, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                ),
                Row(
                  children: [
                    Text(order.customer?.name ?? '-', style: const TextStyle(fontSize: 12, color: AppColors.textMid)),
                    const Icon(Icons.expand_more_rounded, size: 16, color: AppColors.textLight),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Date info
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textLight),
              const SizedBox(width: 4),
              Text(
                'Masuk: ${_fmt(order.createdAt)}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMid),
              ),
            ]),
            if (order.estimatedReady != null) ...[
              const SizedBox(height: 2),
              Row(children: [
                const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textLight),
                const SizedBox(width: 4),
                Text(
                  'Estimasi: ${_fmtEstimasi(order.estimatedReady!)}',
                  style: TextStyle(fontSize: 11, color: _isLate(order.estimatedReady!) ? AppColors.danger : AppColors.textMid),
                ),
              ]),
            ],
            const SizedBox(height: 6),
            // Services
            Text(
              '${order.orderDetails.length > 0 ? order.orderDetails[0].service?.serviceName ?? "-" : "-"} · ${order.serviceType.replaceAll("_", " ")}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMid),
            ),
            const SizedBox(height: 8),
            // Footer
            Row(
              children: [
                Text(formatRp(order.totalPrice), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const Spacer(),
                _badge(order.status == 'diterima' ? 'ANTRIAN' : order.status.toUpperCase(), statusColor),
                const SizedBox(width: 6),
                _badge(order.paymentStatus == 'lunas' ? 'LUNAS' : 'BELUM LUNAS', payColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
  );

  Color _statusColor(String s) {
    switch (s) {
      case 'diterima': return AppColors.warning;
      case 'dicuci':
      case 'dikeringkan':
      case 'disetrika': return AppColors.info;
      case 'selesai': return AppColors.success;
      case 'sudah_diambil': return AppColors.textMid;
      default: return AppColors.textMid;
    }
  }

  String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  String _fmtEstimasi(DateTime d) {
    final diff = d.difference(DateTime.now());
    if (_isLate(d)) return 'Terlambat ${(-diff.inHours)} jam';
    return '${d.day}/${d.month}/${d.year}';
  }

  bool _isLate(DateTime d) => d.isBefore(DateTime.now());
}
