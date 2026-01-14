class LocationUpdateResponse {
  final bool success;
  final String? message;
  final LocationUpdateData? data;

  LocationUpdateResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory LocationUpdateResponse.fromJson(Map<String, dynamic> json) {
    LocationUpdateData? locationData;
    if (json['data'] != null && json['data']['driver'] != null) {
      locationData = LocationUpdateData.fromJson(
        json['data']['driver'] as Map<String, dynamic>,
      );
    }

    return LocationUpdateResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: locationData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'driver': data?.toJson(),
      },
    };
  }
}

class LocationUpdateData {
  final int id;
  final double latitude;
  final double longitude;
  final String lastLocationUpdatedAt;

  LocationUpdateData({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.lastLocationUpdatedAt,
  });

  factory LocationUpdateData.fromJson(Map<String, dynamic> json) {
    return LocationUpdateData(
      id: json['id'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      lastLocationUpdatedAt: json['last_location_updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'last_location_updated_at': lastLocationUpdatedAt,
    };
  }
}

