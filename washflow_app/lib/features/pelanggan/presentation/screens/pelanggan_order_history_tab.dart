import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';
import '../../../../features/kasir/presentation/screens/order_detail_screen.dart';

class PelangganOrderHistoryTab extends ConsumerStatefulWidget {
  const PelangganOrderHistoryTab({super.key});
  @override
  ConsumerState<PelangganOrderHistoryTab> createState() => _PelangganOrderHistoryTabState();
}

class _PelangganOrderHistoryTabState extends ConsumerState<PelangganOrderHistoryTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(orderProvider.notifier).fetchOrders());
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ordersAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorWidget2(
          message: 'Gagal memuat riwayat order',
          onRetry: () => ref.read(orderProvider.notifier).fetchOrders(),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'Belum Ada Riwayat Order',
              subtitle: 'Semua riwayat laundry kamu akan muncul di sini.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(orderProvider.notifier).fetchOrders(),
            child: Column(
              children: [
                // Summary Bar
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${orders.length} riwayat order',
                        style: GoogleFonts.poppins(
                          color: AppColors.textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: AppTheme.cardDecoration(),
                        child: OrderListTile(
                          order: orders[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(order: orders[i], isReadOnly: true),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
