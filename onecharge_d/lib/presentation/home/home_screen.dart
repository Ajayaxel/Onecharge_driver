import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/models/select_vehicle_request.dart';
import 'package:onecharge_d/core/models/ticket.dart';
import 'package:onecharge_d/core/models/vehicle.dart';
import 'package:onecharge_d/core/services/background_location_service.dart';
import 'package:onecharge_d/presentation/home/bloc/vehicle_bloc.dart';
import 'package:onecharge_d/presentation/home/bloc/vehicle_event.dart';
import 'package:onecharge_d/presentation/home/bloc/vehicle_state.dart';
import 'package:onecharge_d/presentation/home/vehicle_drop_off_bottom_sheet.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_bloc.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_event.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_state.dart';
import 'package:onecharge_d/presentation/service/service_request_screen.dart';
import 'package:onecharge_d/presentation/map/nearby_drivers_map_screen.dart';
import 'package:onecharge_d/widgets/reusable_button.dart';
import 'package:onecharge_d/widgets/ticket_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int? _selectedVehicleId;
  final TextEditingController _vehicleNumberController = TextEditingController();
  String? _errorMessage;
  final BackgroundLocationService _locationService = BackgroundLocationService();

  @override
  void initState() {
    super.initState();
    // Fetch tickets and vehicles when screen loads
    context.read<TicketBloc>().add(const FetchTickets());
    context.read<VehicleBloc>().add(const FetchVehicles());
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekdays[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  int _getTodayCompletedCount(List<Ticket> completedTickets) {
    final today = DateTime.now();
    return completedTickets.where((ticket) {
      try {
        final date = DateTime.parse(ticket.createdAt);
        return date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;
      } catch (e) {
        return false;
      }
    }).length;
  }

  /// Check if driver has an active task (assigned or in_progress)
  bool _hasActiveTask(List<Ticket> tickets) {
    return tickets.any((ticket) => 
      ticket.status == 'assigned' || ticket.status == 'in_progress'
    );
  }

  /// Get count of active tasks
  int _getActiveTaskCount(List<Ticket> tickets) {
    return tickets.where((ticket) => 
      ticket.status == 'assigned' || ticket.status == 'in_progress'
    ).length;
  }

  /// Check if driver completed daily work (no active tasks)
  bool _hasCompletedDailyWork(List<Ticket> tickets) {
    return !_hasActiveTask(tickets);
  }

  /// Show drop-off bottom sheet for vehicle return
  void _showDropOffBottomSheet(BuildContext context, Vehicle vehicle) {
    // Check if driver has completed daily work (no active tasks)
    final ticketState = context.read<TicketBloc>().state;
    bool canReturnVehicle = false;
    
    if (ticketState is TicketLoaded) {
      canReturnVehicle = _hasCompletedDailyWork(ticketState.tickets);
    }
    
    // Show bottom sheet only if:
    // 1. Vehicle is inactive AND currently running (has driver assigned), OR
    // 2. Driver has completed daily work (no active tasks)
    if (canReturnVehicle || vehicle.driver != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => VehicleDropOffBottomSheet(vehicle: vehicle),
      );
    } else {
      // Show message if driver still has active tasks
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all active tasks before returning the vehicle'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: BlocConsumer<TicketBloc, TicketState>(
          listener: (context, state) {
            if (state is TicketError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.black,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is TicketLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }

            if (state is TicketError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Error: ${state.message}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TicketBloc>().add(const FetchTickets());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is TicketLoaded) {
              final tickets = state.tickets;
              final pendingTickets = tickets
                  .where((t) => t.status != 'completed')
                  .toList();
              final completedTickets = tickets
                  .where((t) => t.status == 'completed')
                  .toList();
              final todayCompleted = _getTodayCompletedCount(completedTickets);
              final hasActiveTask = _hasActiveTask(tickets);
              final activeTaskCount = _getActiveTaskCount(tickets);

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<TicketBloc>().add(const FetchTickets());
                },
                color: Colors.black,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header Section
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _getGreeting(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getFormattedDate(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_errorMessage != null)
                                      Flexible(
                                        child: Container(
                                          margin: const EdgeInsets.only(right: 8),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          constraints: const BoxConstraints(
                                            maxWidth: 200,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.error_outline,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  _errorMessage!,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.refresh_rounded,
                                          color: Colors.black,
                                        ),
                                        onPressed: () {
                                          context.read<TicketBloc>().add(
                                            const FetchTickets(),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Availability Status Card (One Task Per Driver)
                    if (hasActiveTask)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF4E6),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFFA500),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFA500).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    color: Color(0xFFFFA500),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Active Task Limit Reached',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFFFA500),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You have $activeTaskCount active task${activeTaskCount > 1 ? 's' : ''}. Complete it to receive new assignments.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Statistics Cards ui....

                    // Today's Summary Card
                    if (completedTickets.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.today_rounded,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Today\'s Summary',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$todayCompleted tasks completed today',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    // Driver details UI
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            const Text(
                              "Service Vehicle Type",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                            BlocBuilder<VehicleBloc, VehicleState>(
                              builder: (context, vehicleState) {
                                if (vehicleState is VehicleLoading) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                      ),
                                    ),
                                  );
                                }

                                if (vehicleState is VehicleError) {
                                  return Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Error loading vehicles: ${vehicleState.message}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(
                                            onPressed: () {
                                              context
                                                  .read<VehicleBloc>()
                                                  .add(const FetchVehicles());
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.black,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Retry'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                List<Vehicle> vehicles = [];
                                bool isLoading = false;

                                if (vehicleState is VehicleLoaded) {
                                  vehicles = vehicleState.vehicles;
                                } else if (vehicleState is VehicleSelecting) {
                                  vehicles = vehicleState.vehicles;
                                  isLoading = true;
                                } else if (vehicleState is VehicleSelectError) {
                                  vehicles = vehicleState.vehicles;
                                } else if (vehicleState is VehicleSelected) {
                                  vehicles = vehicleState.vehicles;
                                }

                                if (vehicles.isEmpty && vehicleState is! VehicleLoading) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Text(
                                        'No vehicles available',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (vehicles.isNotEmpty) {
                                  return Stack(
                                    children: [
                                      GridView.builder(
                                        itemCount: vehicles.length,
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: 3,
                                              crossAxisSpacing: 12,
                                              mainAxisSpacing: 12,
                                              childAspectRatio: 108 / 102,
                                            ),
                                        itemBuilder: (context, index) {
                                          final vehicle = vehicles[index];
                                          final isSelected = _selectedVehicleId == vehicle.id;
                                          
                                          // Check if this is the currently running vehicle
                                          // A vehicle is "currently running" if it has a driver assigned
                                          final isCurrentlyRunning = vehicle.driver != null;
                                          
                                          return GestureDetector(
                                            onTap: isLoading
                                                ? null
                                                : () {
                                                    // If vehicle is inactive and currently running, show drop-off bottom sheet
                                                    if (!vehicle.isActive && isCurrentlyRunning) {
                                                      _showDropOffBottomSheet(context, vehicle);
                                                    } else if (!vehicle.isActive) {
                                                      // Inactive but not currently running - just select it
                                                      setState(() {
                                                        _selectedVehicleId = isSelected ? null : vehicle.id;
                                                      });
                                                    } else {
                                                      // Active vehicle - normal selection
                                                      setState(() {
                                                        _selectedVehicleId = isSelected ? null : vehicle.id;
                                                      });
                                                    }
                                                  },
                                            child: Opacity(
                                              opacity: isLoading ? 0.6 : 1.0,
                                              child: _buildVehicleCard(
                                                vehicle.image,
                                                vehicle.driverVehicleType?.name ?? 'N/A',
                                                vehicle.isActive,
                                                isSelected,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      if (isLoading)
                                        Positioned.fill(
                                          child: Container(
                                            color: Colors.white.withOpacity(0.3),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                }

                                return const SizedBox.shrink();
                              },
                            ),
                            SizedBox(height: 20),
                            TextField(
                              controller: _vehicleNumberController,
                              decoration: InputDecoration(
                                hintText: 'Enter your vehicle number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.black,
                                    width: 2,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            BlocConsumer<VehicleBloc, VehicleState>(
                              listener: (context, state) {
                                if (state is VehicleSelected) {
                                  setState(() {
                                    _errorMessage = null;
                                  });
                                  
                                  // Start location tracking after vehicle selection
                                  // This ensures driver location is updated for auto-assignment
                                  _locationService.start().then((success) {
                                    if (success) {
                                      print('✅ Location tracking started after vehicle selection');
                                    } else {
                                      print('⚠️ Failed to start location tracking');
                                    }
                                  });
                                  
                                  // Navigate to next screen after successful selection
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ServiceRequestScreen(),
                                    ),
                                  );
                                } else if (state is VehicleSelectError) {
                                  setState(() {
                                    _errorMessage = state.message;
                                  });
                                  // Clear error after 5 seconds
                                  Future.delayed(const Duration(seconds: 5), () {
                                    if (mounted) {
                                      setState(() {
                                        _errorMessage = null;
                                      });
                                    }
                                  });
                                }
                              },
                              builder: (context, state) {
                                final isSelecting = state is VehicleSelecting;
                                return ReusableButton(
                                  text: isSelecting ? 'Selecting...' : 'Save Details',
                                  onPressed: isSelecting
                                      ? null
                                      : () {
                                          setState(() {
                                            _errorMessage = null;
                                          });

                                          if (_selectedVehicleId == null) {
                                            setState(() {
                                              _errorMessage = 'Please select a vehicle';
                                            });
                                            return;
                                          }

                                          if (_vehicleNumberController
                                                  .text.isEmpty) {
                                            setState(() {
                                              _errorMessage = 'Please enter vehicle number';
                                            });
                                            return;
                                          }

                                          context.read<VehicleBloc>().add(
                                                SelectVehicle(
                                                  vehicleId: _selectedVehicleId!,
                                                  request:
                                                      SelectVehicleRequest(
                                                    vehicleNumber:
                                                        _vehicleNumberController
                                                            .text,
                                                  ),
                                                ),
                                              );
                                        },
                                );
                              },
                            ),
                            SizedBox(height: 20),
                            ReusableButton(
                              text: 'See nearby drivers & cars',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NearbyDriversMapScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Pending Work Section
                    if (pendingTickets.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Pending Work',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${pendingTickets.length}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Pending Tickets List
                    if (pendingTickets.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
                            child: TicketCard(
                              ticket: pendingTickets[index],
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ServiceRequestScreen(),
                                  ),
                                );
                              },
                            ),
                          );
                        }, childCount: pendingTickets.length),
                      ),

                    // Empty State
                    if (pendingTickets.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: SizedBox.shrink(),
                      ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              );
            }

            return const Center(
              child: CircularProgressIndicator(color: Colors.black),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVehicleCard(
      String imageUrl, String vehicleType, bool isActive, bool isSelected) {
    return Container(
      height: 102,
      width: 108,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.black : Colors.grey.shade400,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.black.withOpacity(0.05) : Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Center(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        height: 28,
                        width: 60,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.directions_car,
                            size: 28,
                            color: Colors.grey.shade400,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                      )
                    : Icon(
                        Icons.directions_car,
                        size: 28,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vehicleType,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.circle,
                  size: 14,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
