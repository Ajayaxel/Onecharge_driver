import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/models/vehicle.dart';
import 'package:onecharge_d/core/repository/vehicle_repository.dart';
import 'package:onecharge_d/presentation/home/bloc/vehicle_event.dart';
import 'package:onecharge_d/presentation/home/bloc/vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository vehicleRepository;

  VehicleBloc({required this.vehicleRepository}) : super(VehicleInitial()) {
    on<FetchVehicles>(_onFetchVehicles);
    on<SelectVehicle>(_onSelectVehicle);
    on<DropOffVehicle>(_onDropOffVehicle);
  }

  Future<void> _onFetchVehicles(
    FetchVehicles event,
    Emitter<VehicleState> emit,
  ) async {
    // Don't fetch if already loaded
    if (state is VehicleLoaded) {
      return;
    }

    emit(VehicleLoading());

    try {
      final response = await vehicleRepository.getVehicles();

      if (response.success) {
        emit(VehicleLoaded(vehicles: response.vehicles));
      } else {
        emit(VehicleError(
            message: response.message ?? 'Failed to fetch vehicles'));
      }
    } catch (e) {
      emit(VehicleError(
          message: 'An unexpected error occurred: ${e.toString()}'));
    }
  }

  Future<void> _onSelectVehicle(
    SelectVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    final currentState = state;
    List<Vehicle> currentVehicles = [];

    if (currentState is VehicleLoaded) {
      currentVehicles = currentState.vehicles;
    } else {
      emit(VehicleSelectError(
        message: 'Please load vehicles first',
        vehicles: [],
      ));
      return;
    }

    emit(VehicleSelecting(vehicles: currentVehicles));

    try {
      final response = await vehicleRepository.selectVehicle(
        event.vehicleId,
        event.request,
      );

      if (response.success && response.vehicle != null) {
        // Update the vehicle in the list with the new status
        final updatedVehicles = currentVehicles.map<Vehicle>((vehicle) {
          if (vehicle.id == response.vehicle!.id) {
            return response.vehicle!;
          }
          return vehicle;
        }).toList();

        emit(VehicleSelected(
          vehicles: updatedVehicles,
          message: response.message ?? 'Vehicle selected successfully',
        ));

        // After a short delay, emit VehicleLoaded to return to normal state
        await Future.delayed(const Duration(milliseconds: 100));
        emit(VehicleLoaded(vehicles: updatedVehicles));
      } else {
        emit(VehicleSelectError(
          message: response.message ?? 'Failed to select vehicle',
          vehicles: currentVehicles,
        ));
        // Return to loaded state after error
        await Future.delayed(const Duration(milliseconds: 100));
        emit(VehicleLoaded(vehicles: currentVehicles));
      }
    } catch (e) {
      emit(VehicleSelectError(
        message: 'An unexpected error occurred: ${e.toString()}',
        vehicles: currentVehicles,
      ));
      // Return to loaded state after error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(VehicleLoaded(vehicles: currentVehicles));
    }
  }

  Future<void> _onDropOffVehicle(
    DropOffVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    final currentState = state;
    List<Vehicle> currentVehicles = [];

    if (currentState is VehicleLoaded) {
      currentVehicles = currentState.vehicles;
    } else {
      emit(VehicleDropOffError(
        message: 'Please load vehicles first',
        vehicles: [],
      ));
      return;
    }

    emit(VehicleDroppingOff(vehicles: currentVehicles));

    try {
      final response = await vehicleRepository.dropOffVehicle(
        event.vehicleId,
        event.request,
      );

      if (response.success && response.vehicle != null) {
        // Update the vehicle in the list with the new status
        final updatedVehicles = currentVehicles.map<Vehicle>((vehicle) {
          if (vehicle.id == response.vehicle!.id) {
            return response.vehicle!;
          }
          return vehicle;
        }).toList();

        emit(VehicleDroppedOff(
          vehicles: updatedVehicles,
          message: response.message ?? 'Vehicle returned successfully',
        ));

        // After a short delay, emit VehicleLoaded to return to normal state
        await Future.delayed(const Duration(milliseconds: 100));
        emit(VehicleLoaded(vehicles: updatedVehicles));
      } else {
        emit(VehicleDropOffError(
          message: response.message ?? 'Failed to return vehicle',
          vehicles: currentVehicles,
        ));
        // Return to loaded state after error
        await Future.delayed(const Duration(milliseconds: 100));
        emit(VehicleLoaded(vehicles: currentVehicles));
      }
    } catch (e) {
      emit(VehicleDropOffError(
        message: 'An unexpected error occurred: ${e.toString()}',
        vehicles: currentVehicles,
      ));
      // Return to loaded state after error
      await Future.delayed(const Duration(milliseconds: 100));
      emit(VehicleLoaded(vehicles: currentVehicles));
    }
  }
}

