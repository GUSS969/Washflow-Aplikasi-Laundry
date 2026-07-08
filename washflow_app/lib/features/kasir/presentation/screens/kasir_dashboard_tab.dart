import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';
import '../../../../features/customer/presentation/providers/customer_provider.dart';
import 'create_order_screen.dart';
import 'order_detail_screen.dart';

class KasirDashboardTab extends ConsumerStatefulWidget {
  final Function(int)? onTabChange;
  const KasirDashboardTab({super.key, this.onTabChange});
  @override
  ConsumerState<KasirDashboardTab> createState() => _KasirDashboardTabState();
}

class _KasirDashboardTabState extends ConsumerState<KasirDashboardTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(orderProvider.notifier).fetchOrders();
      ref.read(customerProvider.notifier).fetchCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final ordersAsync = ref.watch(orderProvider);
    final customersAsync = ref.watch(customerProvider);
    final now = DateTime.now();
    final today = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        await ref.read(orderProvider.notifier).fetchOrders();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting Banner ─────────────────────────────────
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          const Icon(Icons.storefront_outlined, color: Colors.white, size: 13),
                          const SizedBox(width: 5),
                          Text('Super Laundry', style: GoogleFonts.poppins(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Halo, ${user?.name ?? 'Kasir'}! 👋',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                  Text(
                    today,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // ── Quick Actions ───────────────────────────────────
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _quickAction(
                        context,
                        icon: Icons.add_shopping_cart_rounded,
                        label: 'Tambah\nTransaksi',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateOrderScreen()),
                        ).then((_) => ref.read(orderProvider.notifier).fetchOrders()),
                      ),
                      _quickAction(
                        context,
                        icon: Icons.local_laundry_service_rounded,
                        label: 'Layanan\nLaundry',
                        color: AppColors.danger,
                        onTap: () {
                          if (widget.onTabChange != null) widget.onTabChange!(3);
                        },
                      ),
                      _quickAction(
                        context,
                        icon: Icons.people_outline_rounded,
                        label: 'Data\nPelanggan',
                        color: AppColors.info,
                        onTap: () {
                          if (widget.onTabChange != null) widget.onTabChange!(2);
                        },
                      ),
                      _quickAction(
                        context,
                        icon: Icons.search_rounded,
                        label: 'Cari\nTransaksi',
                        color: const Color(0xFF9C27B0),
                        onTap: () {
                          if (widget.onTabChange != null) widget.onTabChange!(1);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Status Cards ────────────────────────────────────
            ordersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: ErrorWidget2(message: e.toString(), onRetry: () => ref.read(orderProvider.notifier).fetchOrders()),
              ),
              data: (orders) {
                final todayOrders = orders.where((o) =>
                  o.createdAt.year == now.year &&
                  o.createdAt.month == now.month &&
                  o.createdAt.day == now.day
                ).toList();

                final antrian = orders.where((o) => o.status == 'diterima').length;
                final proses = orders.where((o) => ['dicuci','dikeringkan','disetrika'].contains(o.status)).length;
                final siap = orders.where((o) => o.status == 'selesai').length;
                final deadline = orders.where((o) {
                  if (o.estimatedReady == null) return false;
                  return o.estimatedReady!.isBefore(DateTime.now()) && !['sudah_diambil'].contains(o.status);
                }).length;
                final revenue = todayOrders
                    .where((o) => o.paymentStatus == 'lunas')
                    .fold(0.0, (sum, o) => sum + o.totalPrice);
                final totalNominal = todayOrders.fold(0.0, (sum, o) => sum + o.totalPrice);
                final totalCustomers = customersAsync.whenOrNull(data: (c) => c.length) ?? 0;

                final todayKg = todayOrders
                    .expand((o) => o.orderDetails)
                    .where((d) => d.weight != null && d.weight! > 0)
                    .fold(0.0, (sum, d) => sum + (d.weight ?? 0));
                final todayPcs = todayOrders
                    .expand((o) => o.orderDetails)
                    .where((d) => d.qty != null && d.qty! > 0)
                    .fold(0, (sum, d) => sum + (d.qty ?? 0));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badges
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _statusCard('Antrian', antrian, AppColors.danger, Icons.inbox_outlined),
                          const SizedBox(width: 8),
                          _statusCard('Proses', proses, AppColors.warning, Icons.sync_rounded),
                          const SizedBox(width: 8),
                          _statusCard('Siap Diambil', siap, AppColors.success, Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          _statusCard('Deadline', deadline, const Color(0xFF9C27B0), Icons.timer_outlined),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Summary Section
                    const SectionHeader(title: 'Ringkasan Hari Ini'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        decoration: AppTheme.cardDecoration(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _summaryItem(Icons.receipt_long_outlined, '${todayOrders.length}', 'Transaksi', AppColors.primary),
                                _summaryDivider(),
                                _summaryItem(Icons.payments_outlined, currency.format(totalNominal), 'Nominal', AppColors.info),
                                _summaryDivider(),
                                _summaryItem(Icons.account_balance_wallet_outlined, currency.format(revenue), 'Pendapatan', AppColors.success),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                _summaryItem(Icons.scale_outlined, '${todayKg % 1 == 0 ? todayKg.toInt() : todayKg.toStringAsFixed(1)} kg', 'Kiloan', AppColors.warning),
                                _summaryDivider(),
                                _summaryItem(Icons.style_outlined, '$todayPcs pcs', 'Satuan', const Color(0xFF9C27B0)),
                                _summaryDivider(),
                                _summaryItem(Icons.people_outline, '$totalCustomers', 'Pelanggan', AppColors.info),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Support Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Butuh bantuan?', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                                  Text('Tim support kami siap membantu Anda', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textMid)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recent Orders
                    const SectionHeader(title: 'Transaksi Terbaru'),
                    if (orders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          decoration: AppTheme.cardDecoration(),
                          child: const EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: 'Belum Ada Transaksi',
                            subtitle: 'Buat order pertama untuk mulai mencatat transaksi.',
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: AppTheme.cardDecoration(),
                        child: Column(
                          children: orders.take(8).map((order) => OrderListTile(
                            order: order,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
                            ).then((_) => ref.read(orderProvider.notifier).fetchOrders()),
                          )).toList(),
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text('$count', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textMid, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textDark), overflow: TextOverflow.ellipsis),
          Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textMid)),
        ],
      ),
    );
  }

  Widget _summaryDivider() => Container(
    width: 1, height: 48,
    color: AppColors.divider,
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}