import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../data/repositories/vehicle_repository.dart';
import 'vehicle_event.dart';
import 'vehicle_state.dart';

class VehicleBloc extends Bloc<VehicleEvent, VehicleState> {
  final VehicleRepository _repo;

  VehicleBloc(this._repo) : super(VehicleState.initial()) {
    // ── Each event type is processed concurrently with others ────────────────
    // This means FetchVehicles and FetchCurrentVehicle run in parallel.
    on<FetchVehicles>(_onFetchVehicles, transformer: concurrent());
    on<FetchVehiclesPage>(_onFetchVehiclesPage, transformer: droppable());
    on<FetchCurrentVehicle>(_onFetchCurrentVehicle, transformer: concurrent());
    on<SelectVehicle>(_onSelectVehicle, transformer: droppable());
    on<DropOffVehicle>(_onDropOffVehicle, transformer: droppable());
  }

  // ─── Fetch page 1 (reset) ──────────────────────────────────────────────────

  Future<void> _onFetchVehicles(
    FetchVehicles event,
    Emitter<VehicleState> emit,
  ) async {
    // Only show shimmer if we don't already have data
    if (!state.grid.isLoaded) {
      emit(state.copyWith(grid: const GridState.loading()));
    }

    try {
      // forceRefresh=true so pull-to-refresh always hits network
      final result = await _repo.fetchPage(1, forceRefresh: true);
      emit(
        state.copyWith(
          grid: GridState.loaded(
            vehicles: result.vehicles,
            totalCount: result.totalCount,
            currentPage: result.currentPage,
            lastPage: result.lastPage,
          ),
        ),
      );
    } catch (e) {
      // On error, keep any cached data visible; only show error if empty
      if (!state.grid.isLoaded || state.grid.vehicles.isEmpty) {
        emit(state.copyWith(grid: GridState.error(e.toString())));
      }
    }
  }

  // ─── Fetch next page (append) ──────────────────────────────────────────────

  Future<void> _onFetchVehiclesPage(
    FetchVehiclesPage event,
    Emitter<VehicleState> emit,
  ) async {
    final grid = state.grid;

    // Guard: already fetching or no more pages
    if (grid.isLoadingMore || !grid.hasMore) return;
    if (event.page <= grid.currentPage) return; // already fetched this page

    emit(state.copyWith(grid: GridState.loadingMore(grid)));

    try {
      final result = await _repo.fetchPage(event.page);
      emit(
        state.copyWith(
          grid: GridState.loaded(
            vehicles: [...grid.vehicles, ...result.vehicles],
            totalCount: result.totalCount,
            currentPage: result.currentPage,
            lastPage: result.lastPage,
          ),
        ),
      );
    } catch (_) {
      // Silently revert to previous state (don't lose existing data)
      emit(
        state.copyWith(
          grid: GridState.loaded(
            vehicles: grid.vehicles,
            totalCount: grid.totalCount,
            currentPage: grid.currentPage,
            lastPage: grid.lastPage,
          ),
        ),
      );
    }
  }

  // ─── Banner: current vehicle ───────────────────────────────────────────────

  Future<void> _onFetchCurrentVehicle(
    FetchCurrentVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    // Only show banner shimmer if not already loaded
    if (!state.banner.isLoaded) {
      emit(state.copyWith(banner: const BannerState.loading()));
    }

    try {
      final vehicle = await _repo.fetchCurrentVehicle();
      emit(state.copyWith(banner: BannerState.loaded(vehicle)));
    } catch (e) {
      // Banner failure → hide it gracefully (don't crash or block grid)
      emit(state.copyWith(banner: BannerState.error(e.toString())));
    }
  }

  // ─── Select vehicle ────────────────────────────────────────────────────────

  Future<void> _onSelectVehicle(
    SelectVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(select: const SelectState.selecting()));

    try {
      final message = await _repo.selectVehicle(event.vehicleId);

      // Find selected vehicle from cache
      final cached =
          _repo.findCachedVehicleById(event.vehicleId) ??
          VehicleModel(
            id: event.vehicleId,
            name: 'Selected Vehicle',
            numberPlate: '',
            status: true,
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            vehicleType: const DriverVehicleType(id: 0, name: 'Unknown'),
          );

      emit(
        state.copyWith(
          select: SelectState.selected(cached, message),
          banner: BannerState.loaded(cached), // update banner immediately
        ),
      );

      // Refresh full list in background (don't await)
      add(const FetchVehicles());
    } catch (e) {
      emit(state.copyWith(select: SelectState.error(e.toString())));
    }
  }

  // ─── Drop-off vehicle ──────────────────────────────────────────────────────

  Future<void> _onDropOffVehicle(
    DropOffVehicle event,
    Emitter<VehicleState> emit,
  ) async {
    emit(state.copyWith(dropOff: const DropOffState.droppingOff()));

    try {
      final message = await _repo.dropOffVehicle(
        event.vehicleId,
        latitude: event.latitude,
        longitude: event.longitude,
        imagePaths: event.imagePaths,
      );
      emit(
        state.copyWith(
          dropOff: DropOffState.droppedOff(message),
          banner: const BannerState.loaded(null), // clear banner immediately
        ),
      );

      // Refresh grid in background
      add(const FetchVehicles());
    } catch (e) {
      emit(state.copyWith(dropOff: DropOffState.error(e.toString())));
    }
  }
}
