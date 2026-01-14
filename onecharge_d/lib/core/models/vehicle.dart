import 'package:onecharge_d/core/models/driver.dart';
import 'package:onecharge_d/core/models/driver_vehicle_type.dart';

class Vehicle {
  final int id;
  final String name;
  final String numberPlate;
  final String image;
  final bool status;
  final bool isActive;
  final DriverVehicleType? driverVehicleType;
  final Driver? driver;
  final String createdAt;
  final String updatedAt;

  Vehicle({
    required this.id,
    required this.name,
    required this.numberPlate,
    required this.image,
    required this.status,
    required this.isActive,
    this.driverVehicleType,
    this.driver,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      numberPlate: json['number_plate'] ?? '',
      image: json['image'] ?? '',
      status: json['status'] ?? false,
      isActive: json['is_active'] ?? false,
      driverVehicleType: json['driver_vehicle_type'] != null
          ? DriverVehicleType.fromJson(
              json['driver_vehicle_type'] as Map<String, dynamic>)
          : null,
      driver: json['driver'] != null
          ? Driver.fromJson(json['driver'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
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
      'driver_vehicle_type': driverVehicleType?.toJson(),
      'driver': driver?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}

