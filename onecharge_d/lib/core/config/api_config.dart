class ApiConfig {
  // Base URL for API - Update this with your actual base URL
  static const String baseUrl = 'https://onecharge.io';
  
  // API Endpoints
  static const String loginEndpoint = '/api/driver/login';
  static const String ticketsEndpoint = '/api/driver/tickets';
  
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
  
  // Helper method to get full URL
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}
