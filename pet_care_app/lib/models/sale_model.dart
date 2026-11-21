class SaleModel {
  final int id;
  final String orderCode;
  final int customerId;
  final String status;
  final String? notes;
  final double totalPrice;
  final double? originalPrice;
  final DateTime? checkInTime;
  final DateTime? pickedUpAt;
  final DateTime? createdAt;
  final String customerName;
  final String? customerPhone;
  final String petName;
  final String? petSpecies;
  final String serviceName;
  final String serviceCategory;

  SaleModel({
    required this.id,
    required this.orderCode,
    required this.customerId,
    required this.status,
    this.notes,
    required this.totalPrice,
    this.originalPrice,
    this.checkInTime,
    this.pickedUpAt,
    this.createdAt,
    required this.customerName,
    this.customerPhone,
    required this.petName,
    this.petSpecies,
    required this.serviceName,
    required this.serviceCategory,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderCode: json['order_code'] ?? '',
      customerId: json['customer_id'] is int ? json['customer_id'] : int.tryParse(json['customer_id'].toString()) ?? 0,
      status: json['status'] ?? 'PICKED_UP',
      notes: json['notes'],
      totalPrice: json['total_price'] != null ? double.tryParse(json['total_price'].toString()) ?? 0.0 : 0.0,
      originalPrice: json['original_price'] != null ? double.tryParse(json['original_price'].toString()) : null,
      checkInTime: json['check_in_time'] != null ? DateTime.tryParse(json['check_in_time'].toString()) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.tryParse(json['picked_up_at'].toString()) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      customerName: json['customer_name'] ?? 'Pelanggan',
      customerPhone: json['customer_phone'],
      petName: json['pet_name'] ?? 'Hewan',
      petSpecies: json['pet_species'],
      serviceName: json['service_name'] ?? 'Layanan',
      serviceCategory: json['service_category'] ?? 'Grooming',
    );
  }
}
