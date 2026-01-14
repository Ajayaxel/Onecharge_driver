import 'package:onecharge_d/core/models/vehicle.dart';

class NearbyVehiclesResponse {
  final bool success;
  final String? message;
  final List<NearbyVehicle> vehicles;
  final int count;
  final String? radiusKm;

  NearbyVehiclesResponse({
    required this.success,
    this.message,
    required this.vehicles,
    required this.count,
    this.radiusKm,
  });

  factory NearbyVehiclesResponse.fromJson(Map<String, dynamic> json) {
    List<NearbyVehicle> vehiclesList = [];
    
    if (json['data'] != null && json['data']['vehicles'] != null) {
      final vehiclesData = json['data']['vehicles'] as List<dynamic>;
      vehiclesList = vehiclesData
          .map((e) => NearbyVehicle.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return NearbyVehiclesResponse(
      success: json['success'] ?? false,
      message: json['message'],
      vehicles: vehiclesList,
      count: json['data']?['count'] ?? 0,
      radiusKm: json['data']?['radius_km']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'vehicles': vehicles.map((e) => e.toJson()).toList(),
        'count': count,
        'radius_km': radiusKm,
      },
    };
  }
}

class NearbyVehicle {
  final int id;
  final String name;
  final String numberPlate;
  final String image;
  final bool status;
  final bool isActive;
  final double latitude;
  final double longitude;
  final String? droppedOffAt;
  final double? distanceKm;
  final Vehicle? vehicleDetails;

  NearbyVehicle({
    required this.id,
    required this.name,
    required this.numberPlate,
    required this.image,
    required this.status,
    required this.isActive,
    required this.latitude,
    required this.longitude,
    this.droppedOffAt,
    this.distanceKm,
    this.vehicleDetails,
  });

  factory NearbyVehicle.fromJson(Map<String, dynamic> json) {
    Vehicle? vehicleDetails;
    try {
      vehicleDetails = Vehicle.fromJson(json);
    } catch (e) {
      // If parsing fails, vehicleDetails will be null
    }

    return NearbyVehicle(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      numberPlate: json['number_plate'] ?? '',
      image: json['image'] ?? '',
      status: json['status'] ?? false,
      isActive: json['is_active'] ?? false,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      droppedOffAt: json['dropped_off_at'],
      distanceKm: json['distance_km'] != null 
          ? (json['distance_km'] as num).toDouble() 
          : null,
      vehicleDetails: vehicleDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'number_plate': numberPlate,
      'image': image,
      'status': status,
      'is_active': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'dropped_off_at': droppedOffAt,
      'distance_km': distanceKm,
    };
  }
}

