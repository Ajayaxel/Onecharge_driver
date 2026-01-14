import 'dart:async';
import 'package:onecharge_d/core/repository/ticket_repository.dart';
import 'package:onecharge_d/core/storage/token_storage.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_bloc.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_event.dart';

/// Service that periodically polls for new tickets
/// This ensures drivers receive auto-assigned tickets in real-time
class TicketPollingService {
  static final TicketPollingService _instance = TicketPollingService._internal();
  factory TicketPollingService() => _instance;
  TicketPollingService._internal();

  final TicketRepository _ticketRepository = TicketRepository();
  Timer? _pollingTimer;
  bool _isRunning = false;
  int _lastTicketCount = 0;

  /// Check if service is currently running
  bool get isRunning => _isRunning;

  /// Start polling for tickets
  /// Polls every 15 seconds to catch auto-assigned tickets quickly
  Future<bool> start({TicketBloc? ticketBloc}) async {
    if (_isRunning) {
      print('🎫 Ticket polling service is already running');
      return true;
    }

    print('\n🚀 [TICKET POLLING] Starting service...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Check if driver is logged in
    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (!isLoggedIn) {
      print('❌ Driver is not logged in. Cannot start ticket polling.');
      return false;
    }

    // Fetch initial tickets
    await _fetchTickets(ticketBloc);

    // Start periodic polling (every 15 seconds)
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) async {
        await _fetchTickets(ticketBloc);
      },
    );

    _isRunning = true;
    print('✅ Ticket polling service started successfully');
    print('   - Polls every 15 seconds');
    print('   - Detects new auto-assigned tickets');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    return true;
  }

  /// Stop polling for tickets
  void stop() {
    if (!_isRunning) {
      return;
    }

    print('\n🛑 [TICKET POLLING] Stopping service...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    _pollingTimer?.cancel();
    _pollingTimer = null;

    _isRunning = false;
    _lastTicketCount = 0;
    print('✅ Ticket polling service stopped');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  /// Fetch tickets and update bloc if provided
  Future<void> _fetchTickets(TicketBloc? ticketBloc) async {
    // Check if still logged in
    final isLoggedIn = await TokenStorage.isLoggedIn();
    if (!isLoggedIn) {
      print('⚠️ Driver logged out. Stopping ticket polling.');
      stop();
      return;
    }

    try {
      final response = await _ticketRepository.getTickets();

      if (response.success) {
        final currentTicketCount = response.tickets.length;
        
        // Check if new tickets were assigned
        if (currentTicketCount > _lastTicketCount && _lastTicketCount > 0) {
          final newTicketsCount = currentTicketCount - _lastTicketCount;
          print('🎉 [TICKET POLLING] $newTicketsCount new ticket(s) detected!');
          
          // Update bloc to refresh UI
          if (ticketBloc != null) {
            ticketBloc.add(const FetchTickets());
          }
        }

        _lastTicketCount = currentTicketCount;
      } else {
        print('❌ [TICKET POLLING] Failed to fetch tickets: ${response.message}');
      }
    } catch (e) {
      print('❌ [TICKET POLLING] Error fetching tickets: $e');
    }
  }

  /// Manually trigger ticket fetch
  Future<void> fetchNow({TicketBloc? ticketBloc}) async {
    await _fetchTickets(ticketBloc);
  }

  /// Restart the service
  Future<bool> restart({TicketBloc? ticketBloc}) async {
    stop();
    await Future.delayed(const Duration(milliseconds: 500));
    return await start(ticketBloc: ticketBloc);
  }
}

