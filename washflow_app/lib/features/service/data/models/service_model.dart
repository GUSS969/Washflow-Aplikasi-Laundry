class ServiceModel {
  final int id;
  final String serviceName;
  final double price;
  final String unit; // 'kg', 'item', 'pasang'

  ServiceModel({
    required this.id,
    required this.serviceName,
    required this.price,
    required this.unit,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'],
      serviceName: json['service_name'],
      price: double.parse(json['price'].toString()),
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_name': serviceName,
      'price': price,
      'unit': unit,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
