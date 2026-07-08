import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/notification_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class NotificationNotifier extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final Ref _ref;

  NotificationNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = const AsyncValue.loading();
    try {
      final apiService = _ref.read(apiServiceProvider);
      final notifications = await apiService.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.markNotificationAsRead(id);
      state.whenData((notifications) {
        state = AsyncValue.data(notifications.map((n) {
          if (n.id == id) {
            return NotificationModel(
              id: n.id, userId: n.userId, title: n.title,
              message: n.message, isRead: true, createdAt: n.createdAt,
            );
          }
          return n;
        }).toList());
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.markAllNotificationsAsRead();
      state.whenData((notifications) {
        state = AsyncValue.data(notifications
            .map((n) => NotificationModel(
                  id: n.id, userId: n.userId, title: n.title,
                  message: n.message, isRead: true, createdAt: n.createdAt,
                ))
            .toList());
      });
    } catch (e) {
      rethrow;
    }
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<List<NotificationModel>>>(
        (ref) => NotificationNotifier(ref));
