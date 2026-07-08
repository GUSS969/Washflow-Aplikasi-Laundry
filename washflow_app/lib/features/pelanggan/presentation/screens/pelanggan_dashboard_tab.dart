import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';
import '../../../../features/order/data/models/order_model.dart';
import '../../../../features/kasir/presentation/screens/order_detail_screen.dart';
import 'pelanggan_create_order_screen.dart';

class PelangganDashboardTab extends ConsumerStatefulWidget {
  const PelangganDashboardTab({super.key});
  @override
  ConsumerState<PelangganDashboardTab> createState() => _PelangganDashboardTabState();
}

class _PelangganDashboardTabState extends ConsumerState<PelangganDashboardTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    Future.microtask(() => ref.read(orderProvider.notifier).fetchOrders());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final ordersAsync = ref.watch(orderProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () => ref.read(orderProvider.notifier).fetchOrders(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          // Greeting Header
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
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text('Pelanggan', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Halo, ${user?.name ?? 'Pelanggan'}! 👋',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pantau status cucianmu di sini',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w500),
                        ),
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
                    child: const Icon(Icons.local_laundry_service_rounded, color: Colors.white, size: 26),
                  ),
                ],
              ),
            ),
          ),

          // CTA Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Container(
                decoration: BoxDecoration(
                   gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PelangganCreateOrderScreen())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          const Text('Pesan Layanan Cuci', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white, letterSpacing: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          ordersAsync.when(
            loading: () => const SliverFillRemaining(child: LoadingWidget()),
            error: (e, _) => SliverFillRemaining(child: ErrorWidget2(message: e.toString(), onRetry: () => ref.read(orderProvider.notifier).fetchOrders())),
            data: (orders) {
              final active = orders.where((o) => o.status != 'sudah_diambil').toList();
              final totalSpent = orders.where((o) => o.paymentStatus == 'lunas').fold(0.0, (s, o) => s + o.totalPrice);

              return SliverList(
                delegate: SliverChildListDelegate([
                  // Stats
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.15,
                      children: [
                        StatCard(title: 'TOTAL ORDER', value: '${orders.length}', icon: Icons.receipt_long_rounded, color: AppColors.primary, subtitle: 'Semua transaksi'),
                        StatCard(title: 'TOTAL BELANJA', value: formatCurrency(totalSpent), icon: Icons.payments_rounded, color: AppColors.success, subtitle: 'Sudah lunas'),
                      ],
                    ),
                  ),

                  // Active Orders Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 3, height: 12, decoration: BoxDecoration(color: AppColors.warning, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            const Text('CUCIAN AKTIF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMid, letterSpacing: 1.0)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.25), width: 1),
                          ),
                          child: Text(
                            '${active.length} aktif',
                            style: const TextStyle(color: AppColors.warning, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (active.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: EmptyState(
                        icon: Icons.local_laundry_service_outlined,
                        title: 'Tidak Ada Cucian Aktif',
                        subtitle: 'Semua cucianmu sudah selesai atau belum ada order.',
                      ),
                    )
                  else
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: active.length,
                        itemBuilder: (ctx, i) => _ActiveOrderCard(order: active[i], pulseAnim: _pulseAnim),
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Recent History
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 16, 12),
                    child: Row(
                      children: [
                        Container(width: 3, height: 12, decoration: BoxDecoration(color: const Color(0xFF9C27B0), borderRadius: BorderRadius.circular(2))),
                        const SizedBox(width: 8),
                        const Text('RIWAYAT TERBARU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMid, letterSpacing: 1.0)),
                      ],
                    ),
                  ),

                  if (orders.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum Ada Order',
                      subtitle: 'Lakukan order pertamamu.',
                    )
                  else
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: AppTheme.cardDecoration(),
                      child: Column(
                        children: orders.take(3).map((o) => OrderListTile(
                          order: o,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o, isReadOnly: true))),
                        )).toList(),
                      ),
                    ),

                  const SizedBox(height: 32),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActiveOrderCard extends StatelessWidget {
  final OrderModel order;
  final Animation<double> pulseAnim;
  const _ActiveOrderCard({required this.order, required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    const flow = ['menunggu_konfirmasi', 'diterima', 'dicuci', 'dikeringkan', 'disetrika', 'selesai', 'sudah_diambil'];
    final step = flow.indexOf(order.status);
    final progress = step < 0 ? 0.0 : (step + 1) / flow.length;
    final color = getStatusColor(order.status);
    final isWaiting = order.status == 'menunggu_konfirmasi';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order, isReadOnly: true))),
      child: Container(
        width: 230,
        margin: const EdgeInsets.only(right: 14, bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: invoice + pulse dot
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    order.invoice,
                    style: const TextStyle(color: AppColors.textLight, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedBuilder(
                  animation: pulseAnim,
                  builder: (context, child) => Opacity(
                    opacity: pulseAnim.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(getStatusIcon(order.status), color: color, size: 13),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      getStatusLabel(order.status),
                      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Progress bar (sembunyikan jika menunggu konfirmasi)
            if (!isWaiting) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(progress * 100).toStringAsFixed(0)}% selesai',
                      style: const TextStyle(color: AppColors.textLight, fontSize: 9)),
                  Text('${step + 1}/${flow.length}',
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
                ],
              ),
            ] else ...[
              // Info menunggu konfirmasi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⏳ Kasir sedang memproses pesananmu',
                  style: TextStyle(color: AppColors.textMid, fontSize: 9, fontStyle: FontStyle.italic),
                ),
              ),
            ],

            const Spacer(),

            // Estimasi ambil
            if (order.estimatedReady != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimasi Ambil',
                            style: TextStyle(color: AppColors.textLight, fontSize: 9)),
                        Text(
                          DateFormat('EEE, dd MMM · HH:mm', 'id_ID').format(order.estimatedReady!),
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Total harga
            Text(
              formatCurrency(order.totalPrice),
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}