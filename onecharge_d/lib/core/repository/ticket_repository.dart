import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:onecharge_d/core/config/api_config.dart';
import 'package:onecharge_d/core/models/attachment_upload_response.dart';
import 'package:onecharge_d/core/models/complete_work_response.dart';
import 'package:onecharge_d/core/models/tickets_response.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';

class TicketRepository {
  Future<TicketsResponse> getTickets() async {
    try {
      print('\n📡 [API REQUEST] Fetch Tickets');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return TicketsResponse(
          success: false,
          message: 'No authentication token found',
          tickets: [],
        );
      }

      final url = Uri.parse(ApiConfig.getFullUrl(ApiConfig.ticketsEndpoint));
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

      print('📥 [API RESPONSE] Fetch Tickets');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ [SUCCESS] Tickets fetched successfully');
        return TicketsResponse.fromJson(responseData);
      } else {
        print('❌ [ERROR] Failed to fetch tickets: ${responseData['message'] ?? 'Unknown error'}');
        return TicketsResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to fetch tickets',
          tickets: [],
        );
      }
    } catch (e) {
      print('❌ [EXCEPTION] Network error: ${e.toString()}');
      return TicketsResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
        tickets: [],
      );
    }
  }

  Future<AttachmentUploadResponse> uploadAttachments({
    required int ticketId,
    required List<XFile> files,
    required String attachmentType, // 'before_work' or 'after_work'
  }) async {
    try {
      print('\n📡 [API REQUEST] Upload Attachments');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🎫 Ticket ID: $ticketId');
      print('📎 Attachment Type: $attachmentType');
      print('📁 Files Count: ${files.length}');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return AttachmentUploadResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      if (files.isEmpty) {
        print('❌ [ERROR] No files selected for upload');
        return AttachmentUploadResponse(
          success: false,
          message: 'No files selected for upload',
        );
      }

      final url = Uri.parse(
        ApiConfig.getFullUrl(ApiConfig.getTicketAttachmentsEndpoint(ticketId)),
      );
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: POST (Multipart)');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      // Add files to the request
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = file.name;
        final fileBytes = await file.readAsBytes();
        
        print('📄 File ${i + 1}: $fileName (${(fileBytes.length / 1024).toStringAsFixed(2)} KB)');
        
        // Determine content type
        String? contentType;
        if (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg')) {
          contentType = 'image/jpeg';
        } else if (fileName.toLowerCase().endsWith('.png')) {
          contentType = 'image/png';
        } else if (fileName.toLowerCase().endsWith('.mp4')) {
          contentType = 'video/mp4';
        } else if (fileName.toLowerCase().endsWith('.mov')) {
          contentType = 'video/quicktime';
        } else {
          // Try to get from mimeType if available
          contentType = file.mimeType;
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'attachments[]',
            fileBytes,
            filename: fileName,
            contentType: contentType != null
                ? http.MediaType.parse(contentType)
                : null,
          ),
        );
      }

      // Add attachment_type field
      request.fields['attachment_type'] = attachmentType;
      print('📋 Fields: {attachment_type: $attachmentType}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 [API RESPONSE] Upload Attachments');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [SUCCESS] Attachments uploaded successfully');
        return AttachmentUploadResponse.fromJson(responseData);
      } else {
        print('❌ [ERROR] Failed to upload attachments: ${responseData['message'] ?? 'Unknown error'}');
        return AttachmentUploadResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to upload attachments',
        );
      }
    } catch (e) {
      print('❌ [EXCEPTION] Network error: ${e.toString()}');
      return AttachmentUploadResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<CompleteWorkResponse> completeWork({
    required int ticketId,
  }) async {
    try {
      print('\n📡 [API REQUEST] Complete Work');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🎫 Ticket ID: $ticketId');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return CompleteWorkResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(
        ApiConfig.getFullUrl(ApiConfig.getCompleteWorkEndpoint(ticketId)),
      );
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: POST');
      print('📋 Headers: {Content-Type: application/json, Accept: application/json, Authorization: Bearer ***}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [API RESPONSE] Complete Work');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [SUCCESS] Work completed successfully');
        if (responseData['ticket'] != null && responseData['ticket']['status'] != null) {
          print('📊 Ticket Status: ${responseData['ticket']['status']}');
        }
        return CompleteWorkResponse.fromJson(responseData);
      } else {
        print('❌ [ERROR] Failed to complete work: ${responseData['message'] ?? 'Unknown error'}');
        return CompleteWorkResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to complete work',
        );
      }
    } catch (e) {
      print('❌ [EXCEPTION] Network error: ${e.toString()}');
      return CompleteWorkResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  Future<CompleteWorkResponse> startWork({
    required int ticketId,
  }) async {
    try {
      print('\n📡 [API REQUEST] Start Work');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🎫 Ticket ID: $ticketId');
      
      final token = await TokenStorage.getToken();
      if (token == null) {
        print('❌ [ERROR] No authentication token found');
        return CompleteWorkResponse(
          success: false,
          message: 'No authentication token found',
        );
      }

      final url = Uri.parse(
        ApiConfig.getFullUrl(ApiConfig.getStartWorkEndpoint(ticketId)),
      );
      print('📍 URL: ${url.toString()}');
      print('🔑 Method: POST');
      print('📋 Headers: {Content-Type: application/json, Accept: application/json, Authorization: Bearer ***}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 [API RESPONSE] Start Work');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ [SUCCESS] Work started successfully');
        if (responseData['ticket'] != null && responseData['ticket']['status'] != null) {
          print('📊 Ticket Status: ${responseData['ticket']['status']}');
        }
        return CompleteWorkResponse.fromJson(responseData);
      } else {
        print('❌ [ERROR] Failed to start work: ${responseData['message'] ?? 'Unknown error'}');
        return CompleteWorkResponse(
          success: false,
          message: responseData['message'] ?? 'Failed to start work',
        );
      }
    } catch (e) {
      print('❌ [EXCEPTION] Network error: ${e.toString()}');
      return CompleteWorkResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }
}
