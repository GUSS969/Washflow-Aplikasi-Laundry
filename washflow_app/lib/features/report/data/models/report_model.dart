import '../../../order/data/models/order_model.dart';

class ReportModel {
  final String startDate;
  final String endDate;
  final int totalOrders;
  final int ordersProcessed;
  final int ordersCompleted;
  final double totalRevenue;
  final List<OrderModel> orders;

  ReportModel({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.ordersProcessed,
    required this.ordersCompleted,
    required this.totalRevenue,
    required this.orders,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    var orderList = json['orders'] as List? ?? [];
    List<OrderModel> orders = orderList
        .map((o) => OrderModel.fromJson(o))
        .toList();

    return ReportModel(
      startDate: json['start_date'],
      endDate: json['end_date'],
      totalOrders: json['total_orders'] ?? 0,
      ordersProcessed: json['orders_processed'] ?? 0,
      ordersCompleted: json['orders_completed'] ?? 0,
      totalRevenue: double.parse((json['total_revenue'] ?? 0).toString()),
      orders: orders,
    );
  }
}
