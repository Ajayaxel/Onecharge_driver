import 'package:equatable/equatable.dart';
import '../../../data/models/vehicle_model.dart';

// ─── Banner sub-state ─────────────────────────────────────────────────────────

enum BannerStatus { initial, loading, loaded, error }

class BannerState extends Equatable {
  final BannerStatus status;
  final VehicleModel? vehicle;
  final String? error;

  const BannerState._({required this.status, this.vehicle, this.error});

  const BannerState.initial() : this._(status: BannerStatus.initial);
  const BannerState.loading() : this._(status: BannerStatus.loading);
  const BannerState.loaded(VehicleModel? v)
    : this._(status: BannerStatus.loaded, vehicle: v);
  const BannerState.error(String msg)
    : this._(status: BannerStatus.error, error: msg);

  bool get isLoading => status == BannerStatus.loading;
  bool get isLoaded => status == BannerStatus.loaded;
  bool get hasVehicle => isLoaded && vehicle != null;

  @override
  List<Object?> get props => [status, vehicle?.id, error];
}

// ─── Grid sub-state ───────────────────────────────────────────────────────────

enum GridStatus { initial, loading, loadingMore, loaded, error }

class GridState extends Equatable {
  final GridStatus status;
  final List<VehicleModel> vehicles;
  final int totalCount;
  final int currentPage;
  final int lastPage;
  final String? error;

  const GridState._({
    required this.status,
    this.vehicles = const [],
    this.totalCount = 0,
    this.currentPage = 1,
    this.lastPage = 1,
    this.error,
  });

  const GridState.initial() : this._(status: GridStatus.initial);
  const GridState.loading() : this._(status: GridStatus.loading);

  /// Loading more pages — preserves existing vehicles.
  GridState.loadingMore(GridState prev)
    : this._(
        status: GridStatus.loadingMore,
        vehicles: prev.vehicles,
        totalCount: prev.totalCount,
        currentPage: prev.currentPage,
        lastPage: prev.lastPage,
      );

  const GridState.loaded({
    required List<VehicleModel> vehicles,
    required int totalCount,
    required int currentPage,
    required int lastPage,
  }) : this._(
         status: GridStatus.loaded,
         vehicles: vehicles,
         totalCount: totalCount,
         currentPage: currentPage,
         lastPage: lastPage,
       );

  const GridState.error(String msg)
    : this._(status: GridStatus.error, error: msg);

  bool get isFirstLoad => status == GridStatus.loading;
  bool get isLoadingMore => status == GridStatus.loadingMore;
  bool get isLoaded =>
      status == GridStatus.loaded || status == GridStatus.loadingMore;
  bool get hasMore => currentPage < lastPage;
  bool get isEmpty => isLoaded && vehicles.isEmpty;

  @override
  List<Object?> get props => [
    status,
    vehicles,
    totalCount,
    currentPage,
    lastPage,
    error,
  ];
}

// ─── Action sub-states ────────────────────────────────────────────────────────

enum SelectStatus { idle, selecting, selected, error }

class SelectState extends Equatable {
  final SelectStatus status;
  final VehicleModel? selected;
  final String? message;

  const SelectState._({required this.status, this.selected, this.message});

  const SelectState.idle() : this._(status: SelectStatus.idle);
  const SelectState.selecting() : this._(status: SelectStatus.selecting);
  const SelectState.selected(VehicleModel v, String msg)
    : this._(status: SelectStatus.selected, selected: v, message: msg);
  const SelectState.error(String msg)
    : this._(status: SelectStatus.error, message: msg);

  @override
  List<Object?> get props => [status, selected?.id, message];
}

enum DropOffStatus { idle, droppingOff, droppedOff, error }

class DropOffState extends Equatable {
  final DropOffStatus status;
  final String? message;

  const DropOffState._({required this.status, this.message});

  const DropOffState.idle() : this._(status: DropOffStatus.idle);
  const DropOffState.droppingOff() : this._(status: DropOffStatus.droppingOff);
  const DropOffState.droppedOff(String msg)
    : this._(status: DropOffStatus.droppedOff, message: msg);
  const DropOffState.error(String msg)
    : this._(status: DropOffStatus.error, message: msg);

  @override
  List<Object?> get props => [status, message];
}

// ─── Compound VehicleState ────────────────────────────────────────────────────

/// A single state object with independent fields for banner, grid, and actions.
/// Using `copyWith` allows only the changed slice to update — the BlocBuilder
/// `buildWhen` can then decide which widget rebuilds.
class VehicleState extends Equatable {
  final BannerState banner;
  final GridState grid;
  final SelectState select;
  final DropOffState dropOff;

  const VehicleState({
    required this.banner,
    required this.grid,
    required this.select,
    required this.dropOff,
  });

  /// Initial/blank state.
  factory VehicleState.initial() => VehicleState(
    banner: const BannerState.initial(),
    grid: const GridState.initial(),
    select: const SelectState.idle(),
    dropOff: const DropOffState.idle(),
  );

  VehicleState copyWith({
    BannerState? banner,
    GridState? grid,
    SelectState? select,
    DropOffState? dropOff,
  }) {
    return VehicleState(
      banner: banner ?? this.banner,
      grid: grid ?? this.grid,
      select: select ?? this.select,
      dropOff: dropOff ?? this.dropOff,
    );
  }

  @override
  List<Object?> get props => [banner, grid, select, dropOff];
}
