import 'package:onecharge_d/core/models/vehicle.dart';

class DropOffVehicleResponse {
  final bool success;
  final String? message;
  final Vehicle? vehicle;

  DropOffVehicleResponse({
    required this.success,
    this.message,
    this.vehicle,
  });

  factory DropOffVehicleResponse.fromJson(Map<String, dynamic> json) {
    Vehicle? vehicleData;
    if (json['data'] != null && json['data']['vehicle'] != null) {
      vehicleData = Vehicle.fromJson(
        json['data']['vehicle'] as Map<String, dynamic>,
      );
    }

    return DropOffVehicleResponse(
      success: json['success'] ?? false,
      message: json['message'],
      vehicle: vehicleData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'vehicle': vehicle?.toJson(),
      },
    };
  }
}

