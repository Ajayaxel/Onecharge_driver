import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final http.Client _client = http.Client();

  // Headers for API calls
  Map<String, String> _getHeaders({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Generic GET request
  Future<http.Response> get(String endpoint, {String? token}) async {
    final url = Uri.parse(endpoint);
    try {
      final response = await _client.get(
        url,
        headers: _getHeaders(token: token),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Generic POST request
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse(endpoint);
    try {
      final response = await _client.post(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Generic PUT request
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse(endpoint);
    try {
      final response = await _client.put(
        url,
        headers: _getHeaders(token: token),
        body: jsonEncode(body),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Generic DELETE request
  Future<http.Response> delete(String endpoint, {String? token}) async {
    final url = Uri.parse(endpoint);
    try {
      final response = await _client.delete(
        url,
        headers: _getHeaders(token: token),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Generic multipart POST request for file uploads
  Future<http.Response> postMultipart(
    String endpoint,
    Map<String, String> fields,
    List<http.MultipartFile> files, {
    String? token,
  }) async {
    final url = Uri.parse(endpoint);
    try {
      final request = http.MultipartRequest('POST', url);

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      // Add fields
      request.fields.addAll(fields);

      // Add files
      request.files.addAll(files);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Dispose client
  void dispose() {
    _client.close();
  }
}
