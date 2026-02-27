import 'package:equatable/equatable.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();
  @override
  List<Object?> get props => [];
}

// ─── List / Grid ──────────────────────────────────────────────────────────────

/// Resets to page 1 and refetches (used on screen open & pull-to-refresh).
class FetchVehicles extends VehicleEvent {
  const FetchVehicles();
}

/// Appends next page; ignored if already loading or no more pages.
class FetchVehiclesPage extends VehicleEvent {
  final int page;
  const FetchVehiclesPage(this.page);
  @override
  List<Object?> get props => [page];
}

// ─── Banner (active vehicle) ──────────────────────────────────────────────────

/// Fetches the currently active vehicle for the banner.
class FetchCurrentVehicle extends VehicleEvent {
  const FetchCurrentVehicle();
}

// ─── Actions ─────────────────────────────────────────────────────────────────

class SelectVehicle extends VehicleEvent {
  final int vehicleId;
  const SelectVehicle(this.vehicleId);
  @override
  List<Object?> get props => [vehicleId];
}

class DropOffVehicle extends VehicleEvent {
  final int vehicleId;
  final double latitude;
  final double longitude;

  /// Ordered list of image file paths: [front, back, left, right, top, bottom]
  final List<String> imagePaths;

  const DropOffVehicle({
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
    required this.imagePaths,
  });

  @override
  List<Object?> get props => [vehicleId, latitude, longitude, imagePaths];
}
