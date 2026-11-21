class PetModel {
  final int id;
  final int userId;
  final String name;
  final String species;
  final String? breed;
  final String gender;
  final int ageYears;
  final double weightKg;
  final String? photoUrl;
  final String? specialNotes;

  PetModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    required this.gender,
    required this.ageYears,
    required this.weightKg,
    this.photoUrl,
    this.specialNotes,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      name: json['name'] ?? '',
      species: json['species'] ?? 'Kucing',
      breed: json['breed'],
      gender: json['gender'] ?? 'Jantan',
      ageYears: json['age_years'] is int ? json['age_years'] : int.tryParse(json['age_years']?.toString() ?? '1') ?? 1,
      weightKg: json['weight_kg'] != null ? double.tryParse(json['weight_kg'].toString()) ?? 3.0 : 3.0,
      photoUrl: json['photo_url'],
      specialNotes: json['special_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'age_years': ageYears,
      'weight_kg': weightKg,
      'photo_url': photoUrl,
      'special_notes': specialNotes,
    };
  }
}
