import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onecharge_d/core/config/api_config.dart';
import 'package:onecharge_d/core/models/driver_profile_response.dart';
import 'package:onecharge_d/core/models/login_request.dart';
import 'package:onecharge_d/core/models/login_response.dart';
import 'package:onecharge_d/core/models/logout_response.dart';
import 'package:onecharge_d/core/models/password_update_request.dart';
import 'package:onecharge_d/core/models/password_update_response.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';

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

  Future<DriverProfileResponse> getDriverProfile() async {
    try {
      print('\n📡 [API REQUEST] Get Driver Profile');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return DriverProfileResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.driverProfileEndpoint));
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: GET');
      print('📋 Headers: {Content-Type: application/json, Accept: application/json, Authorization: Bearer ***}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [API RESPONSE] Get Driver Profile');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return DriverProfileResponse.fromJson(responseData);
      } else {
        return DriverProfileResponse.fromJson(responseData);
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      return DriverProfileResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<LogoutResponse> logout() async {
    try {
      print('\n📡 [API REQUEST] Logout');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return LogoutResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.logoutEndpoint));
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: POST');
      print('📋 Headers: {Content-Type: application/json, Accept: application/json, Authorization: Bearer ***}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [API RESPONSE] Logout');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return LogoutResponse.fromJson(responseData);
      } else {
        return LogoutResponse.fromJson(responseData);
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      return LogoutResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<PasswordUpdateResponse> updatePassword(PasswordUpdateRequest request) async {
    try {
      print('\n📡 [API REQUEST] Update Password');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return PasswordUpdateResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.updatePasswordEndpoint));
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: PUT');
      print('📋 Headers: {Content-Type: application/json, Accept: application/json, Authorization: Bearer ***}');
      print('📦 Request Body: {current_password: ***, password: ***, password_confirmation: ***}');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 [API RESPONSE] Update Password');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        print('❌ [ERROR] Failed to parse response: ${e.toString()}');
        return PasswordUpdateResponse(
          success: false,
          message: 'Invalid response from server',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PasswordUpdateResponse.fromJson(responseData);
      } else {
        // For error responses, still parse the JSON to get error details
        return PasswordUpdateResponse.fromJson(responseData);
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      return PasswordUpdateResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
