import 'package:onecharge_d/core/models/driver.dart';

class LoginResponse {
  final bool success;
  final String message;
  final String? token;
  final Driver? driver;

  LoginResponse({
    required this.success,
    required this.message,
    this.token,
    this.driver,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    Driver? driver;
    String? token;

    if (json['data'] != null) {
      final data = json['data'] as Map<String, dynamic>;
      token = data['token'] as String?;
      
      if (data['driver'] != null) {
        driver = Driver.fromJson(data['driver'] as Map<String, dynamic>);
      }
    }

    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      token: token,
      driver: driver,
    );
  }
}
