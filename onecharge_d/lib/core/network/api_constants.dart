import '../../config/app_config.dart';

class ApiConstants {
  // Base URL
  static const String baseUrl = AppConfig.baseUrl;

  // Auth Endpoints
  static const String login = '$baseUrl/driver/login';
  static const String getProfile = '$baseUrl/driver/me';
  static const String logout = '$baseUrl/driver/logout';
  static const String getTickets = '$baseUrl/driver/tickets';
  static const String getRejectedTickets =
      '$baseUrl/driver/tickets?status=rejected';
  static const String getCompletedTickets =
      '$baseUrl/driver/tickets?status=completed';
  static String acceptTicket(String id) => '$baseUrl/driver/tickets/$id/accept';
  static String uploadAttachments(String id) =>
      '$baseUrl/driver/tickets/$id/attachments';
  static String rejectTicket(String id) => '$baseUrl/driver/tickets/$id/reject';
  static const String getVehicles = '$baseUrl/driver/vehicles';
  static String selectVehicle(int id) => '$baseUrl/driver/vehicles/$id/select';
  static const String getCurrentVehicle = '$baseUrl/driver/vehicles/current';
  static String dropOffVehicle(int id) =>
      '$baseUrl/driver/vehicles/$id/drop-off';
  static const String updateLocation = '$baseUrl/driver/location/update';
}
