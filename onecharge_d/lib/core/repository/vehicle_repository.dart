import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:onecharge_d/core/config/api_config.dart';
import 'package:onecharge_d/core/models/drop_off_vehicle_request.dart';
import 'package:onecharge_d/core/models/drop_off_vehicle_response.dart';
import 'package:onecharge_d/core/models/nearby_vehicles_response.dart';
import 'package:onecharge_d/core/models/select_vehicle_request.dart';
import 'package:onecharge_d/core/models/select_vehicle_response.dart';
import 'package:onecharge_d/core/models/vehicles_response.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';

class VehicleRepository {
  Future<VehiclesResponse> getVehicles() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return VehiclesResponse(
          success: false,
          message: 'No authentication token found',
          vehicles: [],
        );
      }

      final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.vehiclesEndpoint));
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return VehiclesResponse.fromJson(responseData);
      } else {
        return VehiclesResponse.fromJson(responseData);
      }
    } catch (e) {
      return VehiclesResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        vehicles: [],
      );
    }
  }

  Future<SelectVehicleResponse> selectVehicle(
    int vehicleId,
    SelectVehicleRequest request,
  ) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return SelectVehicleResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(
        ApiConfig.getFullUrl(ApiConfig.getSelectVehicleEndpoint(vehicleId)),
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SelectVehicleResponse.fromJson(responseData);
      } else {
        return SelectVehicleResponse.fromJson(responseData);
      }
    } catch (e) {
      return SelectVehicleResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<DropOffVehicleResponse> dropOffVehicle(
    int vehicleId,
    DropOffVehicleRequest request,
  ) async {
    try {
      print('\n📡 [API REQUEST] Drop Off Vehicle');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🚗 Vehicle ID: $vehicleId');
      print('📍 Latitude: ${request.latitude}');
      print('📍 Longitude: ${request.longitude}');
      print('📸 Images Count: ${request.images.length}');
      print('📋 Sides: ${request.sides}');
      print('👤 Has Driver Seated Image: ${request.driverSeatedImage != null}');

      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return DropOffVehicleResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      // Validate request
      if (!request.isValid()) {
        print('❌ [ERROR] Invalid request data');
        return DropOffVehicleResponse(
          success: false,
          message: 'Invalid request data. All 6 images are required.',
        );
      }

      final url = Uri.parse(
        ApiConfig.getFullUrl(ApiConfig.getDropOffVehicleEndpoint(vehicleId)),
      );
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: POST (Multipart)');

      // Create multipart request
      final multipartRequest = http.MultipartRequest('POST', url);

      // Add authorization header
      multipartRequest.headers['Authorization'] = 'Bearer $token';
      multipartRequest.headers['Accept'] = 'application/json';

      // Add latitude and longitude fields
      multipartRequest.fields['latitude'] = request.latitude.toString();
      multipartRequest.fields['longitude'] = request.longitude.toString();

      // Add images with corresponding sides
      for (int i = 0; i < request.images.length; i++) {
        try {
          final image = request.images[i];
          final side = request.sides[i];
          final fileName = image.name;
          
          // Read file bytes with error handling
          final fileBytes = await image.readAsBytes();
          
          // Check file size (max 10MB per image)
          const maxFileSize = 10 * 1024 * 1024; // 10MB
          if (fileBytes.length > maxFileSize) {
            print('❌ [ERROR] Image ${i + 1} ($fileName) exceeds maximum size of 10MB');
            return DropOffVehicleResponse(
              success: false,
              message: 'Image ${i + 1} ($fileName) is too large. Maximum size is 10MB.',
            );
          }

          print('📄 Image ${i + 1}: $fileName (${(fileBytes.length / 1024).toStringAsFixed(2)} KB) - Side: $side');

          // Determine content type
          String? contentType;
          if (fileName.toLowerCase().endsWith('.jpg') ||
              fileName.toLowerCase().endsWith('.jpeg')) {
            contentType = 'image/jpeg';
          } else if (fileName.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          } else {
            contentType = image.mimeType;
          }

          // Add image file
          multipartRequest.files.add(
            http.MultipartFile.fromBytes(
              'images[$i]',
              fileBytes,
              filename: fileName,
              contentType: contentType != null
                  ? http.MediaType.parse(contentType)
                  : null,
            ),
          );

          // Add corresponding side identifier
          multipartRequest.fields['sides[$i]'] = side;
        } catch (e) {
          print('❌ [ERROR] Failed to read image ${i + 1}: $e');
          return DropOffVehicleResponse(
            success: false,
            message: 'Failed to read image ${i + 1}. Please try again.',
          );
        }
      }

      // Add driver seated image if present
      if (request.driverSeatedImage != null) {
        try {
          final driverImage = request.driverSeatedImage!;
          final fileName = driverImage.name;
          final fileBytes = await driverImage.readAsBytes();
          
          // Check file size (max 10MB)
          const maxFileSize = 10 * 1024 * 1024; // 10MB
          if (fileBytes.length > maxFileSize) {
            print('❌ [ERROR] Driver seated image exceeds maximum size of 10MB');
            return DropOffVehicleResponse(
              success: false,
              message: 'Driver seated image is too large. Maximum size is 10MB.',
            );
          }

          print('👤 Driver Seated Image: $fileName (${(fileBytes.length / 1024).toStringAsFixed(2)} KB)');

          String? contentType;
          if (fileName.toLowerCase().endsWith('.jpg') ||
              fileName.toLowerCase().endsWith('.jpeg')) {
            contentType = 'image/jpeg';
          } else if (fileName.toLowerCase().endsWith('.png')) {
            contentType = 'image/png';
          } else {
            contentType = driverImage.mimeType;
          }

          multipartRequest.files.add(
            http.MultipartFile.fromBytes(
              'driver_seated_image',
              fileBytes,
              filename: fileName,
              contentType: contentType != null
                  ? http.MediaType.parse(contentType)
                  : null,
            ),
          );
        } catch (e) {
          print('❌ [ERROR] Failed to read driver seated image: $e');
          return DropOffVehicleResponse(
            success: false,
            message: 'Failed to read driver seated image. Please try again.',
          );
        }
      }

      print('📋 Fields: {latitude: ${request.latitude}, longitude: ${request.longitude}}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Send request with timeout
      final streamedResponse = await multipartRequest.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Request timeout. Please check your internet connection and try again.');
        },
      );
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 [API RESPONSE] Drop Off Vehicle');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        print('❌ [ERROR] Failed to parse JSON response: $e');
        return DropOffVehicleResponse(
          success: false,
          message: 'Invalid response from server',
        );
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DropOffVehicleResponse.fromJson(responseData);
      } else {
        return DropOffVehicleResponse.fromJson(responseData);
      }
    } catch (e) {
      print('❌ [ERROR] Network error: $e');
      String errorMessage = 'Network error occurred. Please try again.';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. Please check your internet connection and try again.';
      } else if (e.toString().contains('SocketException') || 
                 e.toString().contains('Failed host lookup')) {
        errorMessage = 'No internet connection. Please check your network and try again.';
      } else {
        errorMessage = 'An error occurred: ${e.toString()}';
      }
      
      return DropOffVehicleResponse(
        success: false,
        message: errorMessage,
      );
    }
  }

  Future<NearbyVehiclesResponse> getNearbyVehicles({
    required double latitude,
    required double longitude,
    double radius = 100.0,
  }) async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        return NearbyVehiclesResponse(
          success: false,
          message: 'No authentication token found',
          vehicles: [],
          count: 0,
        );
      }

      // Convert radius to integer to match API expectations
      final radiusInt = radius.toInt();
      
      final url = Uri.parse(
        '${ApiConfig.getFullUrl(ApiConfig.nearbyVehiclesEndpoint)}?latitude=$latitude&longitude=$longitude&radius=$radiusInt',
      );

      print('\n📡 [API REQUEST] Get Nearby Vehicles');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: GET');
      print('📋 Headers: {Accept: application/json, Authorization: Bearer ***}');
      print('🌐 Latitude: $latitude, Longitude: $longitude, Radius: $radiusInt km');

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [API RESPONSE] Get Nearby Vehicles');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📋 Response Headers:');
      response.headers.forEach((key, value) {
        print('  $key: $value');
      });
      print('📏 Response Body Length: ${response.body.length}');
      print('📄 Raw Response Body:');
      if (response.body.isEmpty) {
        print('(EMPTY - No content in response body)');
      } else if (response.body.trim().isEmpty) {
        print('(WHITESPACE ONLY - Response contains only whitespace)');
        print('Body bytes: ${response.bodyBytes}');
      } else {
        print(response.body);
      }
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      // Parse JSON response safely
      Map<String, dynamic>? responseData;
      try {
        if (response.body.trim().isNotEmpty) {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
          print('✅ [SUCCESS] JSON parsed successfully');
          print('📋 Formatted JSON Response:');
          final JsonEncoder encoder = JsonEncoder.withIndent('  ');
          print(encoder.convert(responseData));
        } else {
          print('⚠️ [WARNING] Response body empty after trim, skipping JSON parse');
        }
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      } catch (e) {
        print('❌ [ERROR] Failed to parse JSON: $e');
        print('📄 Response body that failed to parse:');
        print(response.body);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return NearbyVehiclesResponse(
          success: false,
          message: 'Invalid JSON response: ${e.toString()}',
          vehicles: [],
          count: 0,
        );
      }

      // Handle error status codes
      if (response.statusCode >= 400) {
        String errorMessage = 'Server error (Status: ${response.statusCode})';
        if (responseData != null && responseData.containsKey('message')) {
          errorMessage = responseData['message'] ?? errorMessage;
        } else if (response.statusCode == 500) {
          errorMessage = 'Internal server error. Please try again later.';
        } else if (response.statusCode == 401) {
          errorMessage = 'Authentication failed. Please login again.';
        } else if (response.statusCode == 403) {
          errorMessage = 'Access forbidden. You don\'t have permission.';
        }
        
        return NearbyVehiclesResponse(
          success: false,
          message: errorMessage,
          vehicles: [],
          count: 0,
        );
      }

      // Guard against empty/invalid response data
      if (responseData == null) {
        return NearbyVehiclesResponse(
          success: false,
          message: 'Empty response from server (Status: ${response.statusCode})',
          vehicles: [],
          count: 0,
        );
      }

      // Parse and return response
      return NearbyVehiclesResponse.fromJson(responseData);
    } catch (e) {
      return NearbyVehiclesResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        vehicles: [],
        count: 0,
      );
    }
  }
}

