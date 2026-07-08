import '../../../customer/data/models/customer_model.dart';
import '../../../service/data/models/service_model.dart';
import '../../../auth/data/models/user_model.dart';

class OrderModel {
  final int id;
  final String invoice;
  final int customerId;
  final CustomerModel? customer;
  final int? userId;
  final UserModel? user;
  final String status;
  final String paymentStatus;
  final String? deliveryType;
  final String serviceType;   // cuci_setrika | cuci_saja | setrika_saja
  final String perfumeType;   // tanpa_parfum | reguler | antibakteri | lavender | floral | sport
  final String? clothNotes;
  final DateTime? estimatedReady;
  final String? notes;
  final double totalPrice;
  final double totalPaid;
  final DateTime createdAt;
  final List<OrderDetailModel> orderDetails;
  final List<PaymentModel> payments;

  OrderModel({
    required this.id,
    required this.invoice,
    required this.customerId,
    this.customer,
    this.userId,
    this.user,
    required this.status,
    required this.paymentStatus,
    this.deliveryType,
    this.serviceType = 'cuci_setrika',
    this.perfumeType = 'reguler',
    this.clothNotes,
    this.estimatedReady,
    this.notes,
    required this.totalPrice,
    this.totalPaid = 0.0,
    required this.createdAt,
    required this.orderDetails,
    this.payments = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var detailsList = json['order_details'] as List? ?? [];
    List<OrderDetailModel> details =
        detailsList.map((d) => OrderDetailModel.fromJson(d)).toList();

    return OrderModel(
      id: json['id'],
      invoice: json['invoice'],
      customerId: json['customer_id'],
      customer:
          json['customer'] != null ? CustomerModel.fromJson(json['customer']) : null,
      userId: json['user_id'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      status: json['status'],
      paymentStatus: json['payment_status'],
      deliveryType: json['delivery_type'],
      serviceType: json['service_type'] ?? 'cuci_setrika',
      perfumeType: json['perfume_type'] ?? 'reguler',
      clothNotes: json['cloth_notes'],
      estimatedReady: json['estimated_ready'] != null
          ? DateTime.tryParse(json['estimated_ready'].toString())?.toLocal()
          : null,
      notes: json['notes'],
      totalPrice: double.parse(json['total_price'].toString()),
      totalPaid: double.tryParse(json['total_paid']?.toString() ?? '0') ?? 0.0,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      orderDetails: details,
      payments: (json['payments'] as List? ?? []).map((p) => PaymentModel.fromJson(p)).toList(),
    );
  }
}

class OrderDetailModel {
  final int id;
  final int orderId;
  final int serviceId;
  final ServiceModel? service;
  final double? weight;
  final int? qty;
  final double subtotal;

  OrderDetailModel({
    required this.id,
    required this.orderId,
    required this.serviceId,
    this.service,
    this.weight,
    this.qty,
    required this.subtotal,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      id: json['id'],
      orderId: json['order_id'],
      serviceId: json['service_id'],
      service:
          json['service'] != null ? ServiceModel.fromJson(json['service']) : null,
      weight:
          json['weight'] != null ? double.parse(json['weight'].toString()) : null,
      qty: json['qty'] != null ? int.parse(json['qty'].toString()) : null,
      subtotal: double.parse(json['subtotal'].toString()),
    );
  }
}

class PaymentModel {
  final int id;
  final int orderId;
  final String method; // 'cash', 'qris', 'transfer', 'ewallet'
  final double amount;
  final DateTime paymentDate;
  final String? paymentProofUrl;
  final String? paymentNotes;
  final int? userId;
  final String? referenceNumber;
  final String status; // 'pending', 'success', 'failed'

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.paymentDate,
    this.paymentProofUrl,
    this.paymentNotes,
    this.userId,
    this.referenceNumber,
    this.status = 'success',
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      orderId: json['order_id'],
      method: json['method'],
      amount: double.parse(json['amount'].toString()),
      paymentDate: DateTime.parse(json['payment_date']).toLocal(),
      paymentProofUrl: json['payment_proof_url'],
      paymentNotes: json['payment_notes'],
      userId: json['user_id'],
      referenceNumber: json['reference_number'],
      status: json['status'] ?? 'success',
    );
  }
}
