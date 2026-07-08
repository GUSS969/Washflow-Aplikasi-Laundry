import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }

  @override
  Widget build(BuildContext context) {
    final notifAsync = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'Notifikasi',
        actions: [
          TextButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
            child: Text(
              'Baca Semua',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: notifAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorWidget2(
          message: 'Gagal memuat notifikasi',
          onRetry: () => ref.read(notificationProvider.notifier).fetchNotifications(),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Tidak Ada Notifikasi',
              subtitle: 'Kamu akan melihat pemberitahuan terbaru di sini.',
            );
          }
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (ctx, i) {
                final n = notifications[i];
                return GestureDetector(
                  onTap: () {
                    if (!n.isRead) ref.read(notificationProvider.notifier).markAsRead(n.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: n.isRead ? AppColors.divider : AppColors.primary.withValues(alpha: 0.3),
                        width: n.isRead ? 1 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: n.isRead
                              ? AppColors.surfaceAlt
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          n.isRead ? Icons.notifications_outlined : Icons.notifications_active_outlined,
                          color: n.isRead ? AppColors.textLight : AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        n.title,
                        style: GoogleFonts.poppins(
                          color: n.isRead ? AppColors.textMid : AppColors.textDark,
                          fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(n.message, style: GoogleFonts.poppins(color: AppColors.textMid, fontSize: 12, height: 1.4)),
                          const SizedBox(height: 6),
                          Text(_relativeTime(n.createdAt), style: GoogleFonts.poppins(color: AppColors.textLight, fontSize: 11)),
                        ],
                      ),
                      trailing: !n.isRead
                          ? Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                            )
                          : null,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
