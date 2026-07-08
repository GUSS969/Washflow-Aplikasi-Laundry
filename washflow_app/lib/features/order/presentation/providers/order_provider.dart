import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/order_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class OrderNotifier extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final Ref _ref;

  OrderNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchOrders();
  }

  Future<void> fetchOrders({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final apiService = _ref.read(apiServiceProvider);
      final orders = await apiService.getOrders(status: status);
      state = AsyncValue.data(orders);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createOrder(
    int? customerId,
    List<Map<String, dynamic>> details, {
    String? paymentStatus,
    String? deliveryType,
    String? serviceType,
    String? perfumeType,
    String? clothNotes,
    DateTime? estimatedReady,
    String? notes,
  }) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.createOrder(
        customerId,
        details,
        paymentStatus: paymentStatus,
        deliveryType: deliveryType,
        serviceType: serviceType,
        perfumeType: perfumeType,
        clothNotes: clothNotes,
        estimatedReady: estimatedReady,
        notes: notes,
      );
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrderStatus(int orderId, String status) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateOrderStatus(orderId, status);
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateOrder(int orderId, {String? status, String? paymentStatus, DateTime? estimatedReady}) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateOrder(orderId, status: status, paymentStatus: paymentStatus, estimatedReady: estimatedReady);
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> payOrder(int orderId, String method, double amount,
      {String? notes, File? proof}) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.createPayment(orderId, method, amount, notes: notes, proof: proof);
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmPayment(int paymentId) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.confirmPayment(paymentId);
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteOrder(int id) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.deleteOrder(id);
      await fetchOrders();
    } catch (e) {
      rethrow;
    }
  }
}

final orderProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<List<OrderModel>>>((ref) {
  return OrderNotifier(ref);
});
