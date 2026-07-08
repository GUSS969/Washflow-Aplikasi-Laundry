import 'dart:io';
import 'package:dio/dio.dart';
import 'dio_client.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/customer/data/models/customer_model.dart';
import '../../features/service/data/models/service_model.dart';
import '../../features/order/data/models/order_model.dart';
import '../../features/notification/data/models/notification_model.dart';
import '../../features/report/data/models/report_model.dart';
import '../storage/token_manager.dart';

class ApiService {
  final Dio _dio = DioClient.instance;

  // --- AUTH ---
  Future<UserModel> login(String email, String password) async {
    final response = await _dio.post('/login', data: {
      'email': email,
      'password': password,
    });
    final token = response.data['access_token'];
    final userData = response.data['user'];
    
    await TokenManager.saveToken(token);
    await TokenManager.saveUserData(userData);

    return UserModel.fromJson(userData);
  }

  Future<void> register(String name, String email, String? phone, String password, String role) async {
    await _dio.post('/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
    });
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } catch (_) {}
    await TokenManager.clearAll();
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get('/profile');
    final userData = response.data['user'];
    await TokenManager.saveUserData(userData);
    return UserModel.fromJson(userData);
  }

  Future<UserModel> updateProfile(String name, String email, {String? phone, String? password}) async {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
    };
    if (password != null && password.isNotEmpty) {
      data['password'] = password;
    }
    final response = await _dio.put('/profile', data: data);
    final userData = response.data['user'];
    await TokenManager.saveUserData(userData);
    return UserModel.fromJson(userData);
  }

  // --- CUSTOMERS ---
  Future<List<CustomerModel>> getCustomers({String? query}) async {
    final response = await _dio.get('/customers', queryParameters: query != null ? {'q': query} : null);
    final list = response.data as List;
    return list.map((c) => CustomerModel.fromJson(c)).toList();
  }

  Future<CustomerModel> getCustomerDetails(int id) async {
    final response = await _dio.get('/customers/$id');
    return CustomerModel.fromJson(response.data);
  }

  Future<CustomerModel> createCustomer(String name, String phone, String? address) async {
    final response = await _dio.post('/customers', data: {
      'name': name,
      'phone': phone,
      'address': address,
    });
    return CustomerModel.fromJson(response.data['customer']);
  }

  Future<CustomerModel> updateCustomer(int id, String name, String phone, String? address) async {
    final response = await _dio.put('/customers/$id', data: {
      'name': name,
      'phone': phone,
      'address': address,
    });
    return CustomerModel.fromJson(response.data['customer']);
  }

  Future<void> deleteCustomer(int id) async {
    await _dio.delete('/customers/$id');
  }

  // --- SERVICES ---
  Future<List<ServiceModel>> getServices() async {
    final response = await _dio.get('/services');
    final list = response.data as List;
    return list.map((s) => ServiceModel.fromJson(s)).toList();
  }

  Future<ServiceModel> createService(String name, double price, String unit) async {
    final response = await _dio.post('/services', data: {
      'service_name': name,
      'price': price,
      'unit': unit,
    });
    return ServiceModel.fromJson(response.data['service']);
  }

  Future<ServiceModel> updateService(int id, String name, double price, String unit) async {
    final response = await _dio.put('/services/$id', data: {
      'service_name': name,
      'price': price,
      'unit': unit,
    });
    return ServiceModel.fromJson(response.data['service']);
  }

  Future<void> deleteService(int id) async {
    await _dio.delete('/services/$id');
  }

  // --- ORDERS ---
  Future<List<OrderModel>> getOrders({String? status}) async {
    final Map<String, dynamic> params = {};
    if (status != null) {
      params['status'] = status;
    }
    final response = await _dio.get('/orders', queryParameters: params);
    final list = response.data as List;
    return list.map((o) => OrderModel.fromJson(o)).toList();
  }

  Future<OrderModel> getOrderDetails(int id) async {
    final response = await _dio.get('/orders/$id');
    return OrderModel.fromJson(response.data);
  }

  Future<OrderModel> createOrder(
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
    final Map<String, dynamic> data = {
      'details': details,
      'payment_status': paymentStatus ?? 'belum_lunas',
      'service_type': serviceType ?? 'cuci_setrika',
      'perfume_type': perfumeType ?? 'reguler',
    };
    if (customerId != null) data['customer_id'] = customerId;
    if (deliveryType != null) data['delivery_type'] = deliveryType;
    if (clothNotes != null) data['cloth_notes'] = clothNotes;
    if (estimatedReady != null) data['estimated_ready'] = estimatedReady.toIso8601String();
    if (notes != null) data['notes'] = notes;

    final response = await _dio.post('/orders', data: data);
    return OrderModel.fromJson(response.data['order']);
  }

  Future<OrderModel> updateOrder(int id, {String? status, String? paymentStatus, DateTime? estimatedReady}) async {
    final Map<String, dynamic> data = {};
    if (status != null) data['status'] = status;
    if (paymentStatus != null) data['payment_status'] = paymentStatus;
    if (estimatedReady != null) data['estimated_ready'] = estimatedReady.toIso8601String();
    
    final response = await _dio.put('/orders/$id', data: data);
    return OrderModel.fromJson(response.data['order']);
  }

  Future<OrderModel> updateOrderStatus(int id, String status) async {
    final response = await _dio.patch('/orders/$id/status', data: {'status': status});
    return OrderModel.fromJson(response.data['order']);
  }

  Future<void> deleteOrder(int id) async {
    await _dio.delete('/orders/$id');
  }

  // --- PAYMENTS ---
  Future<List<PaymentModel>> getPayments() async {
    final response = await _dio.get('/payments');
    final list = response.data as List;
    return list.map((p) => PaymentModel.fromJson(p)).toList();
  }

  Future<PaymentModel> createPayment(int orderId, String method, double amount, {String? notes, File? proof}) async {
    final data = {
      'order_id': orderId,
      'method': method,
      'amount': amount,
    };
    if (notes != null) data['payment_notes'] = notes;

    dynamic requestData;
    if (proof != null) {
      requestData = FormData.fromMap({
        ...data,
        'payment_proof': await MultipartFile.fromFile(proof.path),
      });
    } else {
      requestData = data;
    }

    final response = await _dio.post('/payments', data: requestData);
    return PaymentModel.fromJson(response.data['payment']);
  }

  Future<PaymentModel> confirmPayment(int paymentId) async {
    final response = await _dio.patch('/payments/$paymentId/confirm');
    return PaymentModel.fromJson(response.data['payment']);
  }

  // --- REPORTS ---
  Future<ReportModel> getDailyReport() async {
    final response = await _dio.get('/reports/daily');
    return ReportModel.fromJson(response.data);
  }

  Future<ReportModel> getWeeklyReport() async {
    final response = await _dio.get('/reports/weekly');
    return ReportModel.fromJson(response.data);
  }

  Future<ReportModel> getMonthlyReport() async {
    final response = await _dio.get('/reports/monthly');
    return ReportModel.fromJson(response.data);
  }

  Future<ReportModel> getYearlyReport() async {
    final response = await _dio.get('/reports/yearly');
    return ReportModel.fromJson(response.data);
  }

  // --- NOTIFICATIONS ---
  Future<List<NotificationModel>> getNotifications() async {
    final response = await _dio.get('/notifications');
    final list = response.data as List;
    return list.map((n) => NotificationModel.fromJson(n)).toList();
  }

  Future<NotificationModel> markNotificationAsRead(int id) async {
    final response = await _dio.patch('/notifications/$id/read');
    return NotificationModel.fromJson(response.data['notification']);
  }

  Future<void> markAllNotificationsAsRead() async {
    await _dio.post('/notifications/mark-all-read');
  }

  static String parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        final data = error.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            return errors.values.first[0].toString();
          }
        }
      }
      return 'Koneksi gagal: ${error.message}';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'Terjadi kesalahan sistem';
  }
}
