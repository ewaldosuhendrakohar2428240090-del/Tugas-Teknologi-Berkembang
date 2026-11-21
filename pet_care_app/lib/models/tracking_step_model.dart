class TrackingStepModel {
  final int id;
  final int orderId;
  final int stepNumber;
  final String title;
  final String? description;
  final String status; // 'PENDING', 'IN_PROGRESS', 'COMPLETED'
  final String? photoUrl;
  final DateTime? completedAt;
  final String? staffNotes;

  TrackingStepModel({
    required this.id,
    required this.orderId,
    required this.stepNumber,
    required this.title,
    this.description,
    required this.status,
    this.photoUrl,
    this.completedAt,
    this.staffNotes,
  });

  factory TrackingStepModel.fromJson(Map<String, dynamic> json) {
    return TrackingStepModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      orderId: json['order_id'] is int ? json['order_id'] : int.tryParse(json['order_id'].toString()) ?? 0,
      stepNumber: json['step_number'] is int ? json['step_number'] : int.tryParse(json['step_number'].toString()) ?? 1,
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'PENDING',
      photoUrl: json['photo_url'],
      completedAt: json['completed_at'] != null ? DateTime.tryParse(json['completed_at'].toString()) : null,
      staffNotes: json['staff_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'step_number': stepNumber,
      'title': title,
      'description': description,
      'status': status,
      'photo_url': photoUrl,
      'completed_at': completedAt?.toIso8601String(),
      'staff_notes': staffNotes,
    };
  }

  bool get isCompleted => status == 'COMPLETED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isPending => status == 'PENDING';
}
