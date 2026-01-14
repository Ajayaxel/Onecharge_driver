import 'package:equatable/equatable.dart';
import 'package:onecharge_d/core/models/vehicle.dart';

abstract class VehicleState extends Equatable {
  const VehicleState();

  @override
  List<Object> get props => [];
}

class VehicleInitial extends VehicleState {}

class VehicleLoading extends VehicleState {}

class VehicleLoaded extends VehicleState {
  final List<Vehicle> vehicles;

  const VehicleLoaded({required this.vehicles});

  @override
  List<Object> get props => [vehicles];
}

class VehicleError extends VehicleState {
  final String message;

  const VehicleError({required this.message});

  @override
  List<Object> get props => [message];
}

class VehicleSelecting extends VehicleState {
  final List<Vehicle> vehicles;

  const VehicleSelecting({required this.vehicles});

  @override
  List<Object> get props => [vehicles];
}

class VehicleSelected extends VehicleState {
  final List<Vehicle> vehicles;
  final String message;

  const VehicleSelected({
    required this.vehicles,
    required this.message,
  });

  @override
  List<Object> get props => [vehicles, message];
}

class VehicleSelectError extends VehicleState {
  final String message;
  final List<Vehicle> vehicles;

  const VehicleSelectError({
    required this.message,
    required this.vehicles,
  });

  @override
  List<Object> get props => [message, vehicles];
}

class VehicleDroppingOff extends VehicleState {
  final List<Vehicle> vehicles;

  const VehicleDroppingOff({required this.vehicles});

  @override
  List<Object> get props => [vehicles];
}

class VehicleDroppedOff extends VehicleState {
  final List<Vehicle> vehicles;
  final String message;

  const VehicleDroppedOff({
    required this.vehicles,
    required this.message,
  });

  @override
  List<Object> get props => [vehicles, message];
}

class VehicleDropOffError extends VehicleState {
  final String message;
  final List<Vehicle> vehicles;

  const VehicleDropOffError({
    required this.message,
    required this.vehicles,
  });

  @override
  List<Object> get props => [message, vehicles];
}

