class Driver {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String? licenseNumber;
  final String? profileImage;
  final String createdAt;
  final String updatedAt;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.licenseNumber,
    this.profileImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      licenseNumber: json['license_number'],
      profileImage: json['profile_image'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'license_number': licenseNumber,
      'profile_image': profileImage,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
