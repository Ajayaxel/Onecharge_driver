class DriverVehicleType {
  final int id;
  final String name;

  DriverVehicleType({
    required this.id,
    required this.name,
  });

  factory DriverVehicleType.fromJson(Map<String, dynamic> json) {
    return DriverVehicleType(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

