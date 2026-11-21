import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/pet_model.dart';
import '../models/service_model.dart';
import '../models/tracking_step_model.dart';

class ApiService {
  static const String _defaultHost = kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
  static String baseUrl = _defaultHost;

  // Standalone in-memory fallback state to ensure the app works flawlessly out-of-the-box
  static bool useMockData = false;
  static List<OrderModel> _mockOrders = [];
  static List<PetModel> _mockPets = [];
  static List<ServiceModel> _mockServices = [];

  static void initMockData() {
    _mockPets = [
      PetModel(
        id: 1,
        userId: 1,
        name: 'Milo',
        species: 'Kucing',
        breed: 'British Shorthair',
        gender: 'Jantan',
        ageYears: 2,
        weightKg: 4.2,
        photoUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600',
        specialNotes: 'Agak takut pengering bising, mohon perlahan.',
      ),
      PetModel(
        id: 2,
        userId: 1,
        name: 'Rocky',
        species: 'Anjing',
        breed: 'Golden Retriever',
        gender: 'Jantan',
        ageYears: 3,
        weightKg: 28.5,
        photoUrl: 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=600',
        specialNotes: 'Sangat ramah, gemar mandi busa.',
      ),
      PetModel(
        id: 3,
        userId: 2,
        name: 'Luna',
        species: 'Kucing',
        breed: 'Persia Peaknose',
        gender: 'Betina',
        ageYears: 1,
        weightKg: 3.1,
        photoUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600',
        specialNotes: 'Tindakan steril betina, sudah puasa 8 jam.',
      ),
    ];

    _mockServices = [
      ServiceModel(
        id: 1,
        code: 'GROOM-FULL',
        name: 'Full Grooming Spa Premium',
        category: 'Grooming',
        description: 'Mandi shampoo antikutu & jamur, blow dry, gunting kuku, pembersihan telinga, styling bulu & parfum.',
        basePrice: 120000.0,
        estimatedDurationMin: 120,
        iconName: 'cut',
      ),
      ServiceModel(
        id: 2,
        code: 'GROOM-BASIC',
        name: 'Basic Bath & Dry Clean',
        category: 'Grooming',
        description: 'Mandi wangi higienis, sikat gigi ringan, dan pengeringan hangat.',
        basePrice: 75000.0,
        estimatedDurationMin: 60,
        iconName: 'shower',
      ),
      ServiceModel(
        id: 3,
        code: 'STERIL-CAT-M',
        name: 'Sterilisasi Kucing Jantan (Kastrasi)',
        category: 'Steril',
        description: 'Operasi kastrasi profesional oleh dokter hewan + pemulihan anestesi steril ber-AC.',
        basePrice: 350000.0,
        estimatedDurationMin: 180,
        iconName: 'medical_services',
      ),
      ServiceModel(
        id: 4,
        code: 'STERIL-CAT-F',
        name: 'Sterilisasi Kucing Betina (OH)',
        category: 'Steril',
        description: 'Operasi pengangkatan rahim/ovariohisterektomi profesional + observasi siuman anestesi.',
        basePrice: 550000.0,
        estimatedDurationMin: 240,
        iconName: 'medical_services',
      ),
      ServiceModel(
        id: 5,
        code: 'HOTEL-DELUXE',
        name: 'Pet Hotel Deluxe (Per Malam)',
        category: 'Pet Hotel',
        description: 'Kamar individual ber-AC, makan pakan premium 3x sehari, 2x waktu bermain, update foto harian.',
        basePrice: 85000.0,
        estimatedDurationMin: 1440,
        iconName: 'hotel',
      ),
    ];

    // Order 1: Milo (READY FOR PICKUP - Mengatasi Keterlambatan!)
    final stepsMilo = [
      TrackingStepModel(
        id: 1,
        orderId: 1,
        stepNumber: 1,
        title: 'Check-in & Pemeriksaan Fisik',
        description: 'Kulit dan telinga bersih, tidak ada kutu aktif.',
        status: 'COMPLETED',
        photoUrl: 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?w=600',
        completedAt: DateTime.now().subtract(const Duration(minutes: 130)),
        staffNotes: 'Milo sangat kooperatif.',
      ),
      TrackingStepModel(
        id: 2,
        orderId: 1,
        stepNumber: 2,
        title: 'Mandi Spa & Shampoo Premium',
        description: 'Pembersihan bulu dengan air hangat dan formula chamomile.',
        status: 'COMPLETED',
        photoUrl: 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=600',
        completedAt: DateTime.now().subtract(const Duration(minutes: 85)),
        staffNotes: 'Bulu dibilas sampai wangi lembut.',
      ),
      TrackingStepModel(
        id: 3,
        orderId: 1,
        stepNumber: 3,
        title: 'Pengeringan & Blow Dry',
        description: 'Bulu dikeringkan menggunakan blower hangat suara halus.',
        status: 'COMPLETED',
        photoUrl: null,
        completedAt: DateTime.now().subtract(const Duration(minutes: 40)),
      ),
      TrackingStepModel(
        id: 4,
        orderId: 1,
        stepNumber: 4,
        title: 'Styling, Potong Kuku & Parfum',
        description: 'Potong kuku rapi, trimming bulu wajah, parfum baby powder.',
        status: 'COMPLETED',
        photoUrl: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600',
        completedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      TrackingStepModel(
        id: 5,
        orderId: 1,
        stepNumber: 5,
        title: '🎉 SIAP DIJEMPUT DI TOKO!',
        description: 'Milo telah selesai dan berada di Kandang A-02 ber-AC.',
        status: 'COMPLETED',
        photoUrl: null,
        completedAt: DateTime.now().subtract(const Duration(minutes: 15)),
        staffNotes: 'Silakan bawa PIN / QR untuk pengambilan cepat di kasir.',
      ),
    ];

    // Order 2: Luna (POST_CARE - Sterilisasi sedang dipantau)
    final stepsLuna = [
      TrackingStepModel(
        id: 6,
        orderId: 2,
        stepNumber: 1,
        title: 'Pemeriksaan Pra-Operasi & Timbang',
        description: 'Suhu tubuh 38.4°C normal, puasa 8 jam terpenuhi.',
        status: 'COMPLETED',
        photoUrl: null,
        completedAt: DateTime.now().subtract(const Duration(minutes: 150)),
      ),
      TrackingStepModel(
        id: 7,
        orderId: 2,
        stepNumber: 2,
        title: 'Tindakan Operasi Sterilisasi (OH)',
        description: 'Prosedur bedah ovariohisterektomi lancar dan aman.',
        status: 'COMPLETED',
        photoUrl: null,
        completedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        staffNotes: 'Jahitan halus dan kuat.',
      ),
      TrackingStepModel(
        id: 8,
        orderId: 2,
        stepNumber: 3,
        title: 'Observasi Pemulihan Anestesi',
        description: 'Pasien berada di inkubator hangat dengan pantauan oksigen.',
        status: 'IN_PROGRESS',
        photoUrl: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600',
        completedAt: null,
        staffNotes: 'Sudah mulai sadar, mata sudah berkedip normal.',
      ),
      TrackingStepModel(
        id: 9,
        orderId: 2,
        stepNumber: 4,
        title: 'Edukasi Pasca-Operasi & Resep Obat',
        description: 'Persiapan antibiotik, pereda nyeri & kerah proteksi (collar).',
        status: 'PENDING',
        photoUrl: null,
        completedAt: null,
      ),
      TrackingStepModel(
        id: 10,
        orderId: 2,
        stepNumber: 5,
        title: 'Siap Dijemput Pemilik',
        description: 'Hewan telah pulih 100% dan siap dijemput.',
        status: 'PENDING',
        photoUrl: null,
        completedAt: null,
      ),
    ];

    _mockOrders = [
      OrderModel(
        id: 1,
        orderCode: 'ORD-2026-001',
        customerId: 1,
        petId: 1,
        serviceId: 1,
        status: 'READY_FOR_PICKUP',
        holdingCageNumber: 'Kandang A-02 (Area Siap Jemput)',
        pickupPin: '482910',
        notes: 'Model kepala bulat manis, wangi baby powder.',
        totalPrice: 120000.0,
        checkInTime: DateTime.now().subtract(const Duration(minutes: 135)),
        estimatedCompletionTime: DateTime.now().subtract(const Duration(minutes: 15)),
        readyAt: DateTime.now().subtract(const Duration(minutes: 25)),
        minutesSinceReady: 25,
        customerName: 'Budi Santoso',
        customerPhone: '081234567890',
        petName: 'Milo',
        petSpecies: 'Kucing',
        petBreed: 'British Shorthair',
        petPhoto: 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600',
        petNotes: 'Agak takut pengering bising, mohon perlahan.',
        serviceName: 'Full Grooming Spa Premium',
        serviceCategory: 'Grooming',
        trackingSteps: stepsMilo,
      ),
      OrderModel(
        id: 2,
        orderCode: 'ORD-2026-002',
        customerId: 2,
        petId: 3,
        serviceId: 4,
        status: 'POST_CARE',
        holdingCageNumber: 'Ruang Rawat Inap Steril B-01',
        pickupPin: '739104',
        notes: 'Kucing betina, sudah puasa 8 jam.',
        totalPrice: 550000.0,
        checkInTime: DateTime.now().subtract(const Duration(minutes: 160)),
        estimatedCompletionTime: DateTime.now().add(const Duration(minutes: 45)),
        readyAt: null,
        minutesSinceReady: null,
        customerName: 'Siti Rahma',
        customerPhone: '081298765432',
        petName: 'Luna',
        petSpecies: 'Kucing',
        petBreed: 'Persia Peaknose',
        petPhoto: 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600',
        petNotes: 'Tindakan steril betina, sudah puasa 8 jam.',
        serviceName: 'Sterilisasi Kucing Betina (OH)',
        serviceCategory: 'Steril',
        trackingSteps: stepsLuna,
      ),
    ];
  }

  // 1. Fetch Orders (Customer or Staff view)
  static Future<List<OrderModel>> fetchOrders({int? customerId, String? status}) async {
    initMockData();

    if (!useMockData) {
      try {
        final url = customerId != null
            ? '$baseUrl/orders/customer/$customerId'
            : '$baseUrl/orders${status != null ? '?status=$status' : ''}';

        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['data'] is List) {
            return (data['data'] as List).map((o) => OrderModel.fromJson(o)).toList();
          }
        }
      } catch (e) {
        debugPrint('ℹ️ MySQL API offline, menggunakan simulator in-memory state: $e');
        useMockData = true;
      }
    }

    // Fallback Mock Filter
    return _mockOrders.where((o) {
      if (customerId != null && o.customerId != customerId) return false;
      if (status != null && o.status != status) return false;
      return true;
    }).toList();
  }

  // 2. Fetch Single Order Details with Steps
  static Future<OrderModel?> fetchOrderDetail(int orderId) async {
    initMockData();

    if (!useMockData) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/orders/$orderId')).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true && data['data'] != null) {
            return OrderModel.fromJson(data['data']);
          }
        }
      } catch (e) {
        useMockData = true;
      }
    }

    try {
      return _mockOrders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  // 3. Update Order Status (Staf mengubah status: misal ke READY_FOR_PICKUP)
  static Future<bool> updateOrderStatus(int orderId, String newStatus, {String? cageNumber, String? notes}) async {
    if (!useMockData) {
      try {
        final response = await http.patch(
          Uri.parse('$baseUrl/orders/$orderId/status'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'status': newStatus,
            'holdingCageNumber': cageNumber,
            'notes': notes,
          }),
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) return true;
      } catch (e) {
        useMockData = true;
      }
    }

    // Update in-memory mock
    final index = _mockOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final old = _mockOrders[index];
      final isReady = newStatus == 'READY_FOR_PICKUP';
      final isPicked = newStatus == 'PICKED_UP';

      // Complete all steps if ready
      final updatedSteps = old.trackingSteps.map((s) {
        if (isReady || isPicked) {
          return TrackingStepModel(
            id: s.id,
            orderId: s.orderId,
            stepNumber: s.stepNumber,
            title: s.title,
            description: s.description,
            status: 'COMPLETED',
            photoUrl: s.photoUrl,
            completedAt: s.completedAt ?? DateTime.now(),
            staffNotes: s.staffNotes,
          );
        }
        return s;
      }).toList();

      _mockOrders[index] = OrderModel(
        id: old.id,
        orderCode: old.orderCode,
        customerId: old.customerId,
        petId: old.petId,
        serviceId: old.serviceId,
        status: newStatus,
        holdingCageNumber: cageNumber ?? old.holdingCageNumber,
        pickupPin: old.pickupPin,
        notes: notes ?? old.notes,
        totalPrice: old.totalPrice,
        checkInTime: old.checkInTime,
        estimatedCompletionTime: old.estimatedCompletionTime,
        readyAt: isReady ? DateTime.now() : old.readyAt,
        pickedUpAt: isPicked ? DateTime.now() : old.pickedUpAt,
        minutesSinceReady: isReady ? 0 : old.minutesSinceReady,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        petName: old.petName,
        petSpecies: old.petSpecies,
        petBreed: old.petBreed,
        petPhoto: old.petPhoto,
        petNotes: old.petNotes,
        serviceName: old.serviceName,
        serviceCategory: old.serviceCategory,
        trackingSteps: updatedSteps,
      );
      return true;
    }
    return false;
  }

  // 4. Update Step Foto & Catatan
  static Future<bool> updateStepProgress(int orderId, int stepId, String status, {String? photoUrl, String? notes}) async {
    final orderIdx = _mockOrders.indexWhere((o) => o.id == orderId);
    if (orderIdx != -1) {
      final order = _mockOrders[orderIdx];
      final stepList = List<TrackingStepModel>.from(order.trackingSteps);
      final sIdx = stepList.indexWhere((s) => s.id == stepId);
      if (sIdx != -1) {
        final oldS = stepList[sIdx];
        stepList[sIdx] = TrackingStepModel(
          id: oldS.id,
          orderId: oldS.orderId,
          stepNumber: oldS.stepNumber,
          title: oldS.title,
          description: oldS.description,
          status: status,
          photoUrl: photoUrl ?? oldS.photoUrl,
          completedAt: status == 'COMPLETED' ? DateTime.now() : null,
          staffNotes: notes ?? oldS.staffNotes,
        );

        _mockOrders[orderIdx] = OrderModel(
          id: order.id,
          orderCode: order.orderCode,
          customerId: order.customerId,
          petId: order.petId,
          serviceId: order.serviceId,
          status: order.status,
          holdingCageNumber: order.holdingCageNumber,
          pickupPin: order.pickupPin,
          notes: order.notes,
          totalPrice: order.totalPrice,
          checkInTime: order.checkInTime,
          estimatedCompletionTime: order.estimatedCompletionTime,
          readyAt: order.readyAt,
          pickedUpAt: order.pickedUpAt,
          isOwnerOnTheWay: order.isOwnerOnTheWay,
          ownerEtaMinutes: order.ownerEtaMinutes,
          minutesSinceReady: order.minutesSinceReady,
          customerName: order.customerName,
          customerPhone: order.customerPhone,
          petName: order.petName,
          petSpecies: order.petSpecies,
          petBreed: order.petBreed,
          petPhoto: order.petPhoto,
          petNotes: order.petNotes,
          serviceName: order.serviceName,
          serviceCategory: order.serviceCategory,
          trackingSteps: stepList,
        );
        return true;
      }
    }
    return true;
  }

  // 5. Pemilik Mengabarkan "Saya Sedang Menuju ke Toko"
  static Future<bool> notifyOnTheWay(int orderId, int etaMinutes) async {
    final index = _mockOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final old = _mockOrders[index];
      _mockOrders[index] = OrderModel(
        id: old.id,
        orderCode: old.orderCode,
        customerId: old.customerId,
        petId: old.petId,
        serviceId: old.serviceId,
        status: old.status,
        holdingCageNumber: old.holdingCageNumber,
        pickupPin: old.pickupPin,
        notes: old.notes,
        totalPrice: old.totalPrice,
        checkInTime: old.checkInTime,
        estimatedCompletionTime: old.estimatedCompletionTime,
        readyAt: old.readyAt,
        pickedUpAt: old.pickedUpAt,
        isOwnerOnTheWay: true,
        ownerEtaMinutes: etaMinutes,
        minutesSinceReady: old.minutesSinceReady,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        petName: old.petName,
        petSpecies: old.petSpecies,
        petBreed: old.petBreed,
        petPhoto: old.petPhoto,
        petNotes: old.petNotes,
        serviceName: old.serviceName,
        serviceCategory: old.serviceCategory,
        trackingSteps: old.trackingSteps,
      );
      return true;
    }
    return false;
  }

  // 6. Buat Reservasi Baru
  static Future<bool> createBooking({
    required int customerId,
    required PetModel pet,
    required ServiceModel service,
    required String notes,
  }) async {
    final newId = _mockOrders.length + 1;
    final orderCode = 'ORD-2026-00$newId';
    final pin = (100000 + _mockOrders.length * 3421).toString();

    List<TrackingStepModel> templateSteps = [];
    if (service.category == 'Grooming') {
      templateSteps = [
        TrackingStepModel(id: newId * 10 + 1, orderId: newId, stepNumber: 1, title: 'Check-in & Pemeriksaan Fisik', status: 'IN_PROGRESS', description: 'Pemeriksaan kondisi bulu, kulit, telinga.'),
        TrackingStepModel(id: newId * 10 + 2, orderId: newId, stepNumber: 2, title: 'Mandi Spa & Shampoo Khusus', status: 'PENDING', description: 'Pembersihan bulu dengan air hangat.'),
        TrackingStepModel(id: newId * 10 + 3, orderId: newId, stepNumber: 3, title: 'Pengeringan & Blow Dry', status: 'PENDING', description: 'Pengeringan bulu menyeluruh.'),
        TrackingStepModel(id: newId * 10 + 4, orderId: newId, stepNumber: 4, title: 'Styling & Perapihan Kuku', status: 'PENDING', description: 'Trimming bulu dan potong kuku rapi.'),
        TrackingStepModel(id: newId * 10 + 5, orderId: newId, stepNumber: 5, title: 'Siap Dijemput!', status: 'PENDING', description: 'Peliharaan harum dan siap dipeluk pulang.'),
      ];
    } else if (service.category == 'Steril') {
      templateSteps = [
        TrackingStepModel(id: newId * 10 + 1, orderId: newId, stepNumber: 1, title: 'Pemeriksaan Pra-Operasi', status: 'IN_PROGRESS', description: 'Cek suhu tubuh, berat badan dan kesiapan anestesi.'),
        TrackingStepModel(id: newId * 10 + 2, orderId: newId, stepNumber: 2, title: 'Tindakan Operasi Sterilisasi', status: 'PENDING', description: 'Operasi steril aseptik oleh Dokter Hewan.'),
        TrackingStepModel(id: newId * 10 + 3, orderId: newId, stepNumber: 3, title: 'Observasi Pemulihan Anestesi', status: 'PENDING', description: 'Monitoring hingga pasien sadar dan stabil.'),
        TrackingStepModel(id: newId * 10 + 4, orderId: newId, stepNumber: 4, title: 'Pemberian Obat Pasca Operasi', status: 'PENDING', description: 'Persiapan antibiotik & panduan perawatan di rumah.'),
        TrackingStepModel(id: newId * 10 + 5, orderId: newId, stepNumber: 5, title: 'Siap Dijemput Pemilik!', status: 'PENDING', description: 'Pasien sadar penuh dan aman untuk pulang.'),
      ];
    } else {
      templateSteps = [
        TrackingStepModel(id: newId * 10 + 1, orderId: newId, stepNumber: 1, title: 'Check-in Kamar Hotel', status: 'IN_PROGRESS', description: 'Masuk ke kamar AC privat & penimbangan.'),
        TrackingStepModel(id: newId * 10 + 2, orderId: newId, stepNumber: 2, title: 'Pemberian Pakan Terjadwal', status: 'PENDING', description: 'Makanan sesuai jadwal dari pemilik.'),
        TrackingStepModel(id: newId * 10 + 3, orderId: newId, stepNumber: 3, title: 'Waktu Bermain & Sosialisasi', status: 'PENDING', description: 'Sesi olahraga dan playtime santai.'),
        TrackingStepModel(id: newId * 10 + 4, orderId: newId, stepNumber: 4, title: 'Persiapan Check-out', status: 'PENDING', description: 'Pemeriksaan kesehatan akhir sebelum penjemputan.'),
        TrackingStepModel(id: newId * 10 + 5, orderId: newId, stepNumber: 5, title: 'Siap Dijemput!', status: 'PENDING', description: 'Hewan dan bawaan siap diserahkan.'),
      ];
    }

    final newOrder = OrderModel(
      id: newId,
      orderCode: orderCode,
      customerId: customerId,
      petId: pet.id,
      serviceId: service.id,
      status: 'CHECKED_IN',
      holdingCageNumber: 'Kandang Waiting Room $newId',
      pickupPin: pin,
      notes: notes,
      totalPrice: service.basePrice,
      checkInTime: DateTime.now(),
      estimatedCompletionTime: DateTime.now().add(Duration(minutes: service.estimatedDurationMin)),
      readyAt: null,
      customerName: 'Budi Santoso',
      customerPhone: '081234567890',
      petName: pet.name,
      petSpecies: pet.species,
      petBreed: pet.breed,
      petPhoto: pet.photoUrl,
      petNotes: pet.specialNotes,
      serviceName: service.name,
      serviceCategory: service.category,
      trackingSteps: templateSteps,
    );

    _mockOrders.insert(0, newOrder);
    return true;
  }

  static List<PetModel> getPets() {
    initMockData();
    return _mockPets;
  }

  static List<ServiceModel> getServices() {
    initMockData();
    return _mockServices;
  }
}
