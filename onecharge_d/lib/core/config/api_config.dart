class ApiConfig {
  // Base URL for API - Update this with your actual base URL
  static const String baseUrl = 'https://onecharge.io';
  
  // API Endpoints
  static const String loginEndpoint = '/api/driver/login';
  static const String ticketsEndpoint = '/api/driver/tickets';
  static const String driverProfileEndpoint = '/api/driver/profile';
  static const String logoutEndpoint = '/api/driver/logout';
  static const String updatePasswordEndpoint = '/api/driver/profile/password';
  static const String vehiclesEndpoint = '/api/driver/vehicles';
  
  // Helper method to get ticket attachments endpoint
  static String getTicketAttachmentsEndpoint(int ticketId) {
    return '/api/driver/tickets/$ticketId/attachments';
  }
  
  // Helper method to get complete work endpoint
  static String getCompleteWorkEndpoint(int ticketId) {
    return '/api/driver/tickets/$ticketId/complete-work';
  }
  
  // Helper method to get start work endpoint
  static String getStartWorkEndpoint(int ticketId) {
    return '/api/driver/tickets/$ticketId/start-work';
  }
  
  // Helper method to get select vehicle endpoint
  static String getSelectVehicleEndpoint(int vehicleId) {
    return '/api/driver/vehicles/$vehicleId/select';
  }
  
  // Helper method to get drop-off vehicle endpoint
  static String getDropOffVehicleEndpoint(int vehicleId) {
    return '/api/driver/vehicles/$vehicleId/drop-off';
  }
  
  // Location endpoints
  static const String locationUpdateEndpoint = '/api/driver/location/update';
  static const String nearbyDriversEndpoint = '/api/driver/location/nearby';
  static const String nearbyVehiclesEndpoint = '/api/driver/vehicles/nearby';
  
  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
