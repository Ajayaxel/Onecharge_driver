import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onecharge_d/core/config/api_config.dart';
import 'package:onecharge_d/core/models/login_request.dart';
import 'package:onecharge_d/core/models/login_response.dart';

class AuthRepository {
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.loginEndpoint));
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(responseData);
      } else {
        return LoginResponse.fromJson(responseData);
      }
    } catch (e) {
      return LoginResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
