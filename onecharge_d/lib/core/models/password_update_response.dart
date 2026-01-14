class PasswordUpdateResponse {
  final bool success;
  final String? message;
  final Map<String, List<String>>? errors;

  PasswordUpdateResponse({
    required this.success,
    this.message,
    this.errors,
  });

  factory PasswordUpdateResponse.fromJson(Map<String, dynamic> json) {
    Map<String, List<String>>? errors;
    
    // Handle errors object from API (common Laravel format)
    if (json['errors'] != null) {
      errors = <String, List<String>>{};
      final errorsData = json['errors'] as Map<String, dynamic>;
      errorsData.forEach((key, value) {
        if (value is List) {
          errors![key] = value.cast<String>();
        } else if (value is String) {
          errors![key] = [value];
        }
      });
    }
    
    // Extract message from various possible locations
    String? message;
    if (json['message'] != null) {
      message = json['message'] as String;
    } else if (errors != null && errors.isNotEmpty) {
      // Build message from errors if no message provided
      final errorMessages = <String>[];
      errors.forEach((key, value) {
        errorMessages.addAll(value);
      });
      message = errorMessages.join(', ');
    }

    return PasswordUpdateResponse(
      success: json['success'] ?? false,
      message: message,
      errors: errors,
    );
  }
  
  // Helper method to get error for a specific field
  String? getFieldError(String fieldName) {
    if (errors == null) return null;
    
    // Try different possible field name formats
    final possibleKeys = [
      fieldName,
      fieldName.replaceAll('_', ' '),
      fieldName.replaceAll(' ', '_'),
      'current_password',
      'password',
      'password_confirmation',
    ];
    
    for (final key in possibleKeys) {
      if (errors!.containsKey(key) && errors![key]!.isNotEmpty) {
        return errors![key]!.first;
      }
    }
    
    return null;
  }
}

