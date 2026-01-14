import 'package:onecharge_d/core/models/vehicle.dart';

class SelectVehicleResponse {
  final bool success;
  final String? message;
  final Vehicle? vehicle;

  SelectVehicleResponse({
    required this.success,
    this.message,
    this.vehicle,
  });

  factory SelectVehicleResponse.fromJson(Map<String, dynamic> json) {
    Vehicle? vehicleData;
    if (json['data'] != null && json['data']['vehicle'] != null) {
      vehicleData = Vehicle.fromJson(
        json['data']['vehicle'] as Map<String, dynamic>,
      );
    }

    return SelectVehicleResponse(
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

