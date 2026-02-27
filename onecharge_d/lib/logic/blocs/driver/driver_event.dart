import 'package:equatable/equatable.dart';

abstract class DriverEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FetchDriverProfile extends DriverEvent {}

class UpdateDriverLocal extends DriverEvent {
  final Map<String, dynamic> driverData;
  UpdateDriverLocal(this.driverData);

  @override
  List<Object?> get props => [driverData];
}
