import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onecharge_d/core/config/api_config.dart';
import 'package:onecharge_d/core/models/location_update_response.dart';
import 'package:onecharge_d/core/models/nearby_drivers_response.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';

class LocationRepository {
  Future<LocationUpdateResponse> updateLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('\n📡 [API REQUEST] Update Location');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📍 Latitude: $latitude, Longitude: $longitude');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return LocationUpdateResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.locationUpdateEndpoint));
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
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      print('📥 [API RESPONSE] Update Location');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return LocationUpdateResponse.fromJson(responseData);
      } else {
        return LocationUpdateResponse.fromJson(responseData);
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      return LocationUpdateResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<NearbyDriversResponse> getNearbyDrivers({double radius = 10.0}) async {
    try {
      print('\n📡 [API REQUEST] Get Nearby Drivers');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📏 Radius: $radius km');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return NearbyDriversResponse(
          success: false,
          message: 'No authentication token found',
          nearbyDrivers: [],
        );
      }

      final url = Uri.parse(
        '${ApiConfig.getFullUrl(ApiConfig.nearbyDriversEndpoint)}?radius=$radius',
      );
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: GET');
      print('📋 Headers: {Accept: application/json, Authorization: Bearer ***}');
      
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [API RESPONSE] Get Nearby Drivers');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return NearbyDriversResponse.fromJson(responseData);
      } else {
        return NearbyDriversResponse.fromJson(responseData);
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      return NearbyDriversResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        nearbyDrivers: [],
      );
    }
  }
}

