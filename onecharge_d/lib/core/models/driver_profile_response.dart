import 'package:onecharge_d/core/models/driver.dart';

class DriverProfileResponse {
  final bool success;
  final String? message;
  final Driver? driver;

  DriverProfileResponse({
    required this.success,
    this.message,
    this.driver,
  });

  factory DriverProfileResponse.fromJson(Map<String, dynamic> json) {
    Driver? driver;

    if (json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;
      
      if (data['driver'] != null) {
        driver = Driver.fromJson(data['driver'] as Map<String, dynamic>);
      }
    }

    return DriverProfileResponse(
      success: json['success'] ?? false,
      message: json['message'],
      driver: driver,
    );
  }
}

