import 'package:equatable/equatable.dart';

abstract class DriverState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DriverInitial extends DriverState {}

class DriverLoading extends DriverState {}

class DriverLoaded extends DriverState {
  final Map<String, dynamic> driverData;

  DriverLoaded(this.driverData);

  @override
  List<Object?> get props => [driverData];
}

class DriverError extends DriverState {
  final String message;

  DriverError(this.message);

  @override
  List<Object?> get props => [message];
}
