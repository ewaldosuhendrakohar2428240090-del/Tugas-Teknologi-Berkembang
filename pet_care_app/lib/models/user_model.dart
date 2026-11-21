class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'customer', 'staff', 'admin', 'owner'

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'customer',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'role': role,
  };

  bool get isCustomer => role == 'customer';
  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
  bool get isOwner => role == 'owner';

  String get roleDisplayIndonesian {
    switch (role) {
      case 'customer':
        return 'Pemilik Hewan';
      case 'staff':
        return 'Staf Pet Shop';
      case 'admin':
        return 'Administrator';
      case 'owner':
        return 'Owner Pet Shop';
      default:
        return role;
    }
  }

  IconData get roleIcon {
    switch (role) {
      case 'customer':
        return IconData(0xe4a2, fontFamily: 'MaterialIcons'); // pets
      case 'staff':
        return IconData(0xe043, fontFamily: 'MaterialIcons'); // badge
      case 'admin':
        return IconData(0xf05be, fontFamily: 'MaterialIcons'); // admin_panel_settings
      case 'owner':
        return IconData(0xe0d2, fontFamily: 'MaterialIcons'); // business
      default:
        return IconData(0xe491, fontFamily: 'MaterialIcons'); // person
    }
  }
}
