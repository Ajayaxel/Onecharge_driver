class NearbyDriversResponse {
  final bool success;
  final String? message;
  final List<NearbyDriver> nearbyDrivers;

  NearbyDriversResponse({
    required this.success,
    this.message,
    required this.nearbyDrivers,
  });

  factory NearbyDriversResponse.fromJson(Map<String, dynamic> json) {
    List<NearbyDriver> drivers = [];
    if (json['data'] != null && json['data']['nearby_drivers'] != null) {
      final driversList = json['data']['nearby_drivers'] as List;
      drivers = driversList
          .map((driver) => NearbyDriver.fromJson(driver as Map<String, dynamic>))
          .toList();
    }

    return NearbyDriversResponse(
      success: json['success'] ?? false,
      message: json['message'],
      nearbyDrivers: drivers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'nearby_drivers': nearbyDrivers.map((driver) => driver.toJson()).toList(),
      },
    };
  }
}

class NearbyDriver {
  final int id;
  final String? name;
  final double latitude;
  final double longitude;
  final String? lastLocationUpdatedAt;

  NearbyDriver({
    required this.id,
    this.name,
    required this.latitude,
    required this.longitude,
    this.lastLocationUpdatedAt,
  });

  factory NearbyDriver.fromJson(Map<String, dynamic> json) {
    return NearbyDriver(
      id: json['id'] ?? json['driver_id'] ?? 0,
      name: json['name'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      lastLocationUpdatedAt: json['last_location_updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'last_location_updated_at': lastLocationUpdatedAt,
    };
  }
}

