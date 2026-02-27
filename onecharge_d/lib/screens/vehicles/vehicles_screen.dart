import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:onecharge_d/data/models/vehicle_model.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_bloc.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_event.dart';
import 'package:onecharge_d/logic/blocs/vehicle/vehicle_state.dart';
import 'package:onecharge_d/widgets/home_header_widgets.dart';
import 'package:onecharge_d/widgets/custom_toast.dart';
import 'package:onecharge_d/screens/vehicles/drop_off_modal.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key});

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // ── Only fetch if not already loaded (e.g. from app startup) ───────────
    // bootmnav.dart also guards the tab-switch trigger, so this ensures
    // first-launch loads while preventing duplicate calls on re-navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<VehicleBloc>().state;
      if (!state.grid.isLoaded) {
        context.read<VehicleBloc>().add(const FetchVehicles());
      }
      if (!state.banner.isLoaded) {
        context.read<VehicleBloc>().add(const FetchCurrentVehicle());
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Triggers next-page load when user scrolls near the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final offset = _scrollController.offset;
    if (offset >= maxExtent - 250) {
      final grid = context.read<VehicleBloc>().state.grid;
      if (grid.hasMore && !grid.isLoadingMore) {
        context.read<VehicleBloc>().add(
          FetchVehiclesPage(grid.currentPage + 1),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            // ── Select listener ──────────────────────────────────────────────
            BlocListener<VehicleBloc, VehicleState>(
              listenWhen: (prev, curr) => prev.select != curr.select,
              listener: (context, state) {
                if (state.select.status == SelectStatus.selected) {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  CustomToast.show(
                    context,
                    state.select.message ?? 'Vehicle activated',
                    alignRight: true,
                  );
                } else if (state.select.status == SelectStatus.error) {
                  CustomToast.show(
                    context,
                    state.select.message ?? 'Failed',
                    isError: true,
                    alignRight: true,
                  );
                }
              },
            ),
            // ── Drop-off listener ────────────────────────────────────────────
            BlocListener<VehicleBloc, VehicleState>(
              listenWhen: (prev, curr) => prev.dropOff != curr.dropOff,
              listener: (context, state) {
                if (state.dropOff.status == DropOffStatus.droppedOff) {
                  CustomToast.show(
                    context,
                    state.dropOff.message ?? 'Vehicle dropped off',
                    alignRight: true,
                  );
                } else if (state.dropOff.status == DropOffStatus.error) {
                  CustomToast.show(
                    context,
                    state.dropOff.message ?? 'Failed',
                    isError: true,
                    alignRight: true,
                  );
                }
              },
            ),
          ],
          child: RefreshIndicator(
            color: Colors.black,
            onRefresh: () async {
              context.read<VehicleBloc>()
                ..add(const FetchVehicles())
                ..add(const FetchCurrentVehicle());
              await Future.delayed(const Duration(milliseconds: 700));
            },
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header & search ─────────────────────────────────────────
                const SliverToBoxAdapter(child: HomeHeader()),
                const SliverToBoxAdapter(child: HomeSearchBar()),

                // ── Active vehicle banner — independent BlocBuilder ──────────
                SliverToBoxAdapter(child: _BannerSection()),

                // ── "Vehicles N" header ─────────────────────────────────────
                SliverToBoxAdapter(child: _GridSectionTitle()),

                // ── Vehicle grid ─────────────────────────────────────────────
                _GridSection(scrollController: _scrollController),

                // ── Bottom loader / padding ──────────────────────────────────
                SliverToBoxAdapter(child: _BottomLoader()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────── Banner ───────────────────────────────────

/// Listens ONLY to banner sub-state — never rebuilds because of grid changes.
class _BannerSection extends StatelessWidget {
  const _BannerSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      buildWhen: (prev, curr) =>
          prev.banner != curr.banner || prev.dropOff != curr.dropOff,
      builder: (context, state) {
        final banner = state.banner;

        // ── Shimmer while loading ──────────────────────────────────────────
        if (banner.isLoading) return const _BannerShimmer();

        // ── Error or no active vehicle → hide banner ───────────────────────
        if (!banner.hasVehicle) return const SizedBox.shrink();

        final vehicle = banner.vehicle!;
        final droppingOff = state.dropOff.status == DropOffStatus.droppingOff;

        return Container(
          margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.car_fill,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vehicle.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lufga',
                      ),
                    ),
                    Text(
                      vehicle.numberPlate,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'Lufga',
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Lufga',
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: droppingOff
                    ? null
                    : () => showDropOffModal(context, vehicle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: droppingOff
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Drop Off',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Lufga',
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerShimmer extends StatelessWidget {
  const _BannerShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE0E0E0),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, top: 16),
        height: 90,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 14, width: 120, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 80, color: Colors.white),
                  ],
                ),
              ),
              Container(
                width: 80,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Grid section title ───────────────────────────────

/// Shows "Vehicles N" — updates only when grid totalCount changes.
class _GridSectionTitle extends StatelessWidget {
  const _GridSectionTitle();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      buildWhen: (prev, curr) =>
          prev.grid.totalCount != curr.grid.totalCount ||
          prev.grid.status != curr.grid.status,
      builder: (context, state) {
        final count = state.grid.totalCount;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                'Vehicles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Lufga',
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    key: ValueKey(count),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'Lufga',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────── Grid (SliverGrid) ───────────────────────────────

/// Listens ONLY to grid sub-state — banner changes don't rebuild this.
class _GridSection extends StatelessWidget {
  final ScrollController scrollController;

  const _GridSection({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      buildWhen: (prev, curr) =>
          prev.grid != curr.grid || prev.banner != curr.banner,
      builder: (context, state) {
        final grid = state.grid;
        final activeVehicleId = state.banner.vehicle?.id ?? -1;

        // ── First-load shimmer ─────────────────────────────────────────────
        if (grid.isFirstLoad) {
          // Use totalCount if already known (e.g. from cache), else 6
          final shimmerCount = grid.totalCount > 0 ? grid.totalCount : 6;
          return _VehicleShimmerGrid(itemCount: shimmerCount);
        }

        // ── Error (no data) ────────────────────────────────────────────────
        if (grid.status == GridStatus.error && grid.vehicles.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      grid.error ?? 'Failed to load vehicles',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'Lufga',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ── Empty ──────────────────────────────────────────────────────────
        if (grid.vehicles.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.car_fill,
                      size: 56,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No vehicles found',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                        fontFamily: 'Lufga',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ── Loaded grid ────────────────────────────────────────────────────
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 171 / 174,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _VehicleCard(
                key: ValueKey(grid.vehicles[index].id),
                vehicle: grid.vehicles[index],
                activeVehicleId: activeVehicleId,
                hasActiveVehicle: state.banner.hasVehicle,
                isSelecting: state.select.status == SelectStatus.selecting,
              ),
              childCount: grid.vehicles.length,
            ),
          ),
        );
      },
    );
  }
}

// ──────────────────────────── Bottom loader ───────────────────────────────────

class _BottomLoader extends StatelessWidget {
  const _BottomLoader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleBloc, VehicleState>(
      buildWhen: (prev, curr) =>
          prev.grid.isLoadingMore != curr.grid.isLoadingMore,
      builder: (context, state) {
        if (state.grid.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                strokeWidth: 2.5,
              ),
            ),
          );
        }
        return const SizedBox(height: 100);
      },
    );
  }
}

// ──────────────────────────── Vehicle card ────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final VehicleModel vehicle;
  final int activeVehicleId;
  final bool hasActiveVehicle;
  final bool isSelecting;

  const _VehicleCard({
    super.key,
    required this.vehicle,
    required this.activeVehicleId,
    required this.hasActiveVehicle,
    required this.isSelecting,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = activeVehicleId == vehicle.id;
    // A vehicle is "Occupied" only when another driver's data is present
    // in the driver field. is_active=true just means the vehicle is
    // operational/enabled in the fleet — it does NOT mean occupied.
    final bool isOccupied = !isActive && vehicle.driver != null;
    final int battery = (vehicle.id * 17 + 40) % 61 + 40; // 40–100%

    Color batteryColor;
    if (battery >= 80) {
      batteryColor = const Color(0xFF4CAF50);
    } else if (battery >= 60) {
      batteryColor = const Color(0xFF8BC34A);
    } else {
      batteryColor = const Color(0xFFFF9800);
    }

    return GestureDetector(
      onTap: () {
        if (isOccupied) return; // occupied by another driver
        if (hasActiveVehicle && !isActive) {
          // Show top-right toast
          CustomToast.show(
            context,
            'Please drop off your current vehicle first!',
            isError: true,
            alignRight: true,
          );
          return;
        }
        _showConfirm(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.black : Colors.transparent,
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Stack(
          children: [
            // Status badge (top-left)
            if (isActive || isOccupied)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Occupied',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Lufga',
                      color: isActive
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE57373),
                    ),
                  ),
                ),
              ),

            // Card body
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Vehicle image / icon
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: vehicle.image != null
                        ? Image.network(
                            vehicle.image!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Icon(
                              CupertinoIcons.car_fill,
                              size: 48,
                              color: Colors.black.withValues(alpha: 0.85),
                            ),
                          )
                        : Icon(
                            CupertinoIcons.car_fill,
                            size: 48,
                            color: Colors.black.withValues(alpha: 0.85),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Lufga',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.numberPlate,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                      fontFamily: 'Lufga',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: batteryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$battery%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: batteryColor,
                        fontFamily: 'Lufga',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _ConfirmSheet(vehicle: vehicle),
    );
  }
}

// ────────────────────────── Confirm sheet ─────────────────────────────────────

class _ConfirmSheet extends StatelessWidget {
  final VehicleModel vehicle;

  const _ConfirmSheet({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'Confirm Active Your Vehicle',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Lufga',
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Are you sure you want to activate\n'
            '${vehicle.name} (${vehicle.numberPlate})?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontFamily: 'Lufga',
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BlocBuilder<VehicleBloc, VehicleState>(
                  buildWhen: (p, c) => p.select.status != c.select.status,
                  builder: (context, state) {
                    final selecting =
                        state.select.status == SelectStatus.selecting;
                    // Auto-close sheet on success
                    if (state.select.status == SelectStatus.selected) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      });
                    }
                    return ElevatedButton(
                      onPressed: selecting
                          ? null
                          : () => context.read<VehicleBloc>().add(
                              SelectVehicle(vehicle.id),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: selecting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Confirm',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// ───────────────────────── Shimmer grid ──────────────────────────────────────

class _VehicleShimmerGrid extends StatelessWidget {
  final int itemCount;
  const _VehicleShimmerGrid({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 171 / 174,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => const _ShimmerCard(),
          childCount: itemCount,
        ),
      ),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEEEEE),
      highlightColor: const Color(0xFFF5F5F5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
