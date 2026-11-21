class ServiceModel {
  final int id;
  final String code;
  final String name;
  final String category; // 'Grooming', 'Steril', 'Pet Hotel'
  final String description;
  final double basePrice;
  final int estimatedDurationMin;
  final String iconName;

  ServiceModel({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.description,
    required this.basePrice,
    required this.estimatedDurationMin,
    required this.iconName,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Grooming',
      description: json['description'] ?? '',
      basePrice: json['base_price'] != null ? double.tryParse(json['base_price'].toString()) ?? 0.0 : 0.0,
      estimatedDurationMin: json['estimated_duration_min'] is int 
          ? json['estimated_duration_min'] 
          : int.tryParse(json['estimated_duration_min']?.toString() ?? '60') ?? 60,
      iconName: json['icon_name'] ?? 'pets',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'description': description,
      'base_price': basePrice,
      'estimated_duration_min': estimatedDurationMin,
      'icon_name': iconName,
    };
  }
}
