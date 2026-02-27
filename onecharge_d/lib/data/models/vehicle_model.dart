/// A single vehicle returned by the API.
class VehicleModel {
  final int id;
  final String name;
  final String numberPlate;
  final String? image;
  final bool status;
  final bool isActive;
  final DriverVehicleType vehicleType;
  final Map<String, dynamic>? driver;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleModel({
    required this.id,
    required this.name,
    required this.numberPlate,
    this.image,
    required this.status,
    required this.isActive,
    required this.vehicleType,
    this.driver,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      numberPlate: json['number_plate'] as String,
      image: json['image'] as String?,
      status: json['status'] is bool
          ? json['status'] as bool
          : json['status'] == 1,
      isActive: json['is_active'] is bool
          ? json['is_active'] as bool
          : json['is_active'] == 1,
      vehicleType: json['driver_vehicle_type'] != null
          ? DriverVehicleType.fromJson(
              json['driver_vehicle_type'] as Map<String, dynamic>,
            )
          : DriverVehicleType(id: 0, name: 'Unknown'),
      driver: json['driver'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// Pagination-aware response wrapper returned when the API uses `data.vehicles`
/// together with pagination metadata.
class VehiclePageResponse {
  /// All vehicles on this page.
  final List<VehicleModel> vehicles;

  /// Total number of vehicles available across all pages (from
  /// `data.total_count`, `data.total`, or `meta.total`).
  final int totalCount;

  /// Current page number (1-based).
  final int currentPage;

  /// Last page number.
  final int lastPage;

  const VehiclePageResponse({
    required this.vehicles,
    required this.totalCount,
    required this.currentPage,
    required this.lastPage,
  });

  /// Parses the full decoded API body:
  /// ```json
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "vehicles": [...],
  ///     "total_count": 20,   // or "total", or inside "pagination"
  ///     "current_page": 1,
  ///     "last_page": 3
  ///   }
  /// }
  /// ```
  factory VehiclePageResponse.fromJson(Map<String, dynamic> data) {
    final rawVehicles = (data['vehicles'] as List<dynamic>? ?? []);
    final vehicles = rawVehicles
        .map((j) => VehicleModel.fromJson(j as Map<String, dynamic>))
        .toList();

    // Support multiple common pagination key names.
    final int totalCount =
        (data['total_count'] ??
                data['total'] ??
                data['pagination']?['total'] ??
                vehicles.length)
            as int;

    final int currentPage =
        (data['current_page'] ?? data['pagination']?['current_page'] ?? 1)
            as int;

    final int lastPage =
        (data['last_page'] ??
                data['pagination']?['last_page'] ??
                data['total_pages'] ??
                1)
            as int;

    return VehiclePageResponse(
      vehicles: vehicles,
      totalCount: totalCount,
      currentPage: currentPage,
      lastPage: lastPage,
    );
  }

  bool get hasNextPage => currentPage < lastPage;
}

/// Vehicle type descriptor.
class DriverVehicleType {
  final int id;
  final String name;

  const DriverVehicleType({required this.id, required this.name});

  factory DriverVehicleType.fromJson(Map<String, dynamic> json) {
    return DriverVehicleType(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
