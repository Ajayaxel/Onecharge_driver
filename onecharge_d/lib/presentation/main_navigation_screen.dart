import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/services/background_location_service.dart';
import 'package:onecharge_d/core/services/ticket_polling_service.dart';
import 'package:onecharge_d/presentation/home/home_screen.dart';
import 'package:onecharge_d/presentation/pending/pending_tasks_screen.dart';
import 'package:onecharge_d/presentation/service/service_history_screen.dart';
import 'package:onecharge_d/presentation/profile/profile_screen.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_bloc.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_state.dart';
import 'package:onecharge_d/widgets/modern_bottom_nav_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final BackgroundLocationService _locationService = BackgroundLocationService();
  final TicketPollingService _ticketPollingService = TicketPollingService();

  final List<Widget> _screens = [
    const HomeScreen(),
    const PendingTasksScreen(),
    const ServiceHistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Keep services running in both background and foreground
    switch (state) {
      case AppLifecycleState.resumed:
        // App came to foreground - ensure services are running
        _locationService.start();
        _ticketPollingService.start(
          ticketBloc: context.read<TicketBloc>(),
        );
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App is in background - keep location service running
        // Location service continues in background for auto-assignment
        // Ticket polling can pause to save battery
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is being terminated - services will stop automatically
        break;
    }
  }

  Future<void> _initializeServices() async {
    // Start background location tracking
    await _locationService.start();
    
    // Start ticket polling service
    await _ticketPollingService.start(
      ticketBloc: context.read<TicketBloc>(),
    );
  }

  int _getPendingCount(TicketState state) {
    if (state is TicketLoaded) {
      return state.tickets.where((t) => t.status != 'completed').length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          final pendingCount = _getPendingCount(state);
          return ModernBottomNavBar(
            currentIndex: _currentIndex,
            pendingCount: pendingCount > 0 ? pendingCount : null,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          );
        },
      ),
    );
  }
}

