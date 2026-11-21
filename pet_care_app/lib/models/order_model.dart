import 'tracking_step_model.dart';

class OrderModel {
  final int id;
  final String orderCode;
  final int customerId;
  final int petId;
  final int serviceId;
  final String status; // 'BOOKED', 'CHECKED_IN', 'IN_PROGRESS', 'POST_CARE', 'READY_FOR_PICKUP', 'PICKED_UP', 'CANCELLED'
  final String? holdingCageNumber;
  final String pickupPin;
  final String? notes;
  final double totalPrice;
  final DateTime? checkInTime;
  final DateTime? estimatedCompletionTime;
  final DateTime? readyAt;
  final DateTime? pickedUpAt;
  final bool isOwnerOnTheWay;
  final int? ownerEtaMinutes;
  final int? minutesSinceReady;

  // Joined metadata
  final String customerName;
  final String customerPhone;
  final String petName;
  final String petSpecies;
  final String? petBreed;
  final String? petPhoto;
  final String? petNotes;
  final String serviceName;
  final String serviceCategory;

  final List<TrackingStepModel> trackingSteps;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.customerId,
    required this.petId,
    required this.serviceId,
    required this.status,
    this.holdingCageNumber,
    required this.pickupPin,
    this.notes,
    required this.totalPrice,
    this.checkInTime,
    this.estimatedCompletionTime,
    this.readyAt,
    this.pickedUpAt,
    this.isOwnerOnTheWay = false,
    this.ownerEtaMinutes,
    this.minutesSinceReady,
    required this.customerName,
    required this.customerPhone,
    required this.petName,
    required this.petSpecies,
    this.petBreed,
    this.petPhoto,
    this.petNotes,
    required this.serviceName,
    required this.serviceCategory,
    this.trackingSteps = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    List<TrackingStepModel> steps = [];
    if (json['tracking_steps'] != null && json['tracking_steps'] is List) {
      steps = (json['tracking_steps'] as List)
          .map((s) => TrackingStepModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }

    return OrderModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderCode: json['order_code'] ?? '',
      customerId: json['customer_id'] is int ? json['customer_id'] : int.tryParse(json['customer_id'].toString()) ?? 0,
      petId: json['pet_id'] is int ? json['pet_id'] : int.tryParse(json['pet_id'].toString()) ?? 0,
      serviceId: json['service_id'] is int ? json['service_id'] : int.tryParse(json['service_id'].toString()) ?? 0,
      status: json['status'] ?? 'BOOKED',
      holdingCageNumber: json['holding_cage_number'],
      pickupPin: json['pickup_pin'] ?? '000000',
      notes: json['notes'],
      totalPrice: json['total_price'] != null ? double.tryParse(json['total_price'].toString()) ?? 0.0 : 0.0,
      checkInTime: json['check_in_time'] != null ? DateTime.tryParse(json['check_in_time'].toString()) : null,
      estimatedCompletionTime: json['estimated_completion_time'] != null ? DateTime.tryParse(json['estimated_completion_time'].toString()) : null,
      readyAt: json['ready_at'] != null ? DateTime.tryParse(json['ready_at'].toString()) : null,
      pickedUpAt: json['picked_up_at'] != null ? DateTime.tryParse(json['picked_up_at'].toString()) : null,
      isOwnerOnTheWay: json['is_owner_on_the_way'] == 1 || json['is_owner_on_the_way'] == true,
      ownerEtaMinutes: json['owner_eta_minutes'] is int ? json['owner_eta_minutes'] : int.tryParse(json['owner_eta_minutes']?.toString() ?? ''),
      minutesSinceReady: json['minutes_since_ready'] is int ? json['minutes_since_ready'] : int.tryParse(json['minutes_since_ready']?.toString() ?? ''),
      customerName: json['customer_name'] ?? 'Pelanggan',
      customerPhone: json['customer_phone'] ?? '',
      petName: json['pet_name'] ?? 'Peliharaan',
      petSpecies: json['pet_species'] ?? 'Kucing',
      petBreed: json['pet_breed'],
      petPhoto: json['pet_photo'],
      petNotes: json['pet_notes'],
      serviceName: json['service_name'] ?? 'Layanan Pet Care',
      serviceCategory: json['service_category'] ?? 'Grooming',
      trackingSteps: steps,
    );
  }

  bool get isReadyForPickup => status == 'READY_FOR_PICKUP';
  bool get isPickedUp => status == 'PICKED_UP';
  bool get isInProgress => status == 'IN_PROGRESS' || status == 'POST_CARE';
  bool get isBookedOrCheckedIn => status == 'BOOKED' || status == 'CHECKED_IN';

  String get statusDisplayIndonesian {
    switch (status) {
      case 'BOOKED':
        return 'Telah Dipesan';
      case 'CHECKED_IN':
        return 'Check-in di Toko';
      case 'IN_PROGRESS':
        return serviceCategory == 'Steril' ? 'Operasi Berlangsung' : 'Sedang Dimandikan / Grooming';
      case 'POST_CARE':
        return serviceCategory == 'Steril' ? 'Pemulihan Anestesi' : 'Pengeringan Bulu';
      case 'READY_FOR_PICKUP':
        return '🎉 SIAP DIJEMPUT!';
      case 'PICKED_UP':
        return 'Selesai & Dijemput';
      case 'CANCELLED':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  // Apakah penjemputan terlambat (misal sudah > 30 menit siap tapi belum diambil)
  bool get isDelayedPickup {
    if (isReadyForPickup && minutesSinceReady != null && minutesSinceReady! > 30) {
      return true;
    }
    return false;
  }
}
