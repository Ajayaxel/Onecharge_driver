import 'package:onecharge_d/core/models/vehicle.dart';

class VehiclesResponse {
  final bool success;
  final String? message;
  final List<Vehicle> vehicles;

  VehiclesResponse({
    required this.success,
    this.message,
    required this.vehicles,
  });

  factory VehiclesResponse.fromJson(Map<String, dynamic> json) {
    List<Vehicle> vehiclesList = [];

    if (json['data'] != null && json['data']['vehicles'] != null) {
      final vehiclesData = json['data']['vehicles'] as List<dynamic>;
      vehiclesList = vehiclesData
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return VehiclesResponse(
      success: json['success'] ?? false,
      message: json['message'],
      vehicles: vehiclesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'vehicles': vehicles.map((e) => e.toJson()).toList(),
      },
    };
  }
}

