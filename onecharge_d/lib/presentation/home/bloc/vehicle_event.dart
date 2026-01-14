import 'package:equatable/equatable.dart';
import 'package:onecharge_d/core/models/drop_off_vehicle_request.dart';
import 'package:onecharge_d/core/models/select_vehicle_request.dart';

abstract class VehicleEvent extends Equatable {
  const VehicleEvent();

  @override
  List<Object> get props => [];
}

class FetchVehicles extends VehicleEvent {
  const FetchVehicles();
}

class SelectVehicle extends VehicleEvent {
  final int vehicleId;
  final SelectVehicleRequest request;

  const SelectVehicle({
    required this.vehicleId,
    required this.request,
  });

  @override
  List<Object> get props => [vehicleId, request];
}

class DropOffVehicle extends VehicleEvent {
  final int vehicleId;
  final DropOffVehicleRequest request;

  const DropOffVehicle({
    required this.vehicleId,
    required this.request,
  });

  @override
  List<Object> get props => [vehicleId, request];
}

