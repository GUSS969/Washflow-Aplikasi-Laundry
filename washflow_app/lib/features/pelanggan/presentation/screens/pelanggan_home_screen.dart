import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/notification/presentation/providers/notification_provider.dart';
import '../../../../features/notification/presentation/screens/notifications_screen.dart';
import 'pelanggan_dashboard_tab.dart';
import 'pelanggan_order_history_tab.dart';
import 'profile_tab.dart';

class PelangganHomeScreen extends ConsumerStatefulWidget {
  const PelangganHomeScreen({super.key});

  @override
  ConsumerState<PelangganHomeScreen> createState() => _PelangganHomeScreenState();
}

class _PelangganHomeScreenState extends ConsumerState<PelangganHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final unread = ref.watch(notificationProvider).whenOrNull(
          data: (list) => list.where((n) => !n.isRead).length,
        ) ?? 0;

    final tabs = const [
      PelangganDashboardTab(),
      PelangganOrderHistoryTab(),
      ProfileTab(),
    ];
    final tabTitles = ['Beranda', 'Riwayat', 'Profil'];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: 'WashFlow',
        subtitle: tabTitles[_currentIndex],
        showLeading: false,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread', style: GoogleFonts.poppins(fontSize: 9)),
              backgroundColor: AppColors.danger,
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w400, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history_rounded), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
