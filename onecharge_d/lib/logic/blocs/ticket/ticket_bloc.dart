import 'dart:convert';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../data/models/ticket_model.dart';
import 'ticket_event.dart';
import 'ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final ApiService _apiService;

  TicketBloc(this._apiService) : super(TicketInitial()) {
    // sequential() ensures FetchTickets calls never run in parallel —
    // if one is already running, the next one waits for it to finish.
    // This prevents duplicate HTTP requests from RealTime events + initState.
    on<FetchTickets>(_onFetchTickets, transformer: sequential());
    on<AcceptTicket>(_onAcceptTicket, transformer: droppable());
    on<UploadAttachments>(_onUploadAttachments, transformer: droppable());
    on<FetchHistory>(_onFetchHistory, transformer: droppable());
    on<RejectTicket>(_onRejectTicket, transformer: droppable());
    on<RealTimeTicketUpdate>(_onRealTimeTicketUpdate);
  }

  Future<void> _onRealTimeTicketUpdate(
    RealTimeTicketUpdate event,
    Emitter<TicketState> emit,
  ) async {
    print('TicketBloc: [RealTime] Status: ${event.eventName}');
    print('TicketBloc: [RealTime] Data: ${jsonEncode(event.data)}');

    if (event.eventName == 'cancelled' ||
        event.eventName == 'ticket.cancelled') {
      print('TicketBloc: [RealTime] Ticket cancelled, clearing UI.');
      emit(const TicketLoaded([]));
      return;
    }

    try {
      // Handle nested ticket object if present
      final Map<String, dynamic> ticketData = event.data.containsKey('ticket')
          ? event.data['ticket']
          : event.data;

      // Ensure we have current tickets list to check against
      List<TicketModel> currentTickets = [];
      if (state is TicketLoaded) {
        currentTickets = List.from((state as TicketLoaded).tickets);
      }

      int ticketId = ticketData['ticket_id'] is int
          ? ticketData['ticket_id']
          : int.tryParse(ticketData['ticket_id']?.toString() ?? '0') ?? 0;
      String newStatus = ticketData['status']?.toString() ?? '';

      // 1. If we already have the ticket loaded, just update it in place
      int index = currentTickets.indexWhere(
        (t) =>
            t.id == ticketId ||
            t.ticketId == ticketId.toString() ||
            t.id.toString() == ticketId.toString(),
      );

      if (index != -1 && newStatus.isNotEmpty) {
        currentTickets[index] = currentTickets[index].copyWith(
          status: newStatus,
          latitude:
              ticketData['latitude']?.toString() ??
              currentTickets[index].latitude,
          longitude:
              ticketData['longitude']?.toString() ??
              currentTickets[index].longitude,
          location:
              ticketData['location']?.toString() ??
              currentTickets[index].location,
          description:
              ticketData['message']?.toString() ??
              currentTickets[index].description,
        );
        print(
          'TicketBloc: [RealTime] 🔄 Updated existing ticket $ticketId status to $newStatus',
        );
        emit(TicketLoaded(currentTickets));
        return;
      }

      // Check if data is partial (missing required UI fields like customer or number_plate)
      final bool isPartial =
          !ticketData.containsKey('customer') ||
          !ticketData.containsKey('number_plate');

      if (isPartial) {
        // Create new from partial data securely WITHOUT calling API
        print(
          'TicketBloc: [RealTime] Partial data detected. Building model dynamically...',
        );

        String ticketRef =
            ticketData['ticket_reference']?.toString() ?? ticketId.toString();

        final newTicket = TicketModel(
          id: ticketId,
          ticketId: ticketRef,
          customer: Customer(
            id: 0,
            name: ticketData['customer_name']?.toString() ?? 'Customer',
            phone: ticketData['phone']?.toString() ?? '',
          ),
          issueCategory: IssueCategory(
            id: 0,
            name: ticketData['issue_category']?.toString() ?? 'General',
          ),
          vehicleType: VehicleType(
            id: 0,
            name: ticketData['vehicle_type']?.toString() ?? 'Vehicle',
          ),
          brand: Brand(id: 0, name: ''),
          model: Model(id: 0, name: ''),
          numberPlate: ticketData['number_plate']?.toString() ?? '',
          description: ticketData['message']?.toString(),
          location: ticketData['location']?.toString() ?? '',
          latitude: ticketData['latitude']?.toString() ?? '0.0',
          longitude: ticketData['longitude']?.toString() ?? '0.0',
          status: newStatus.isNotEmpty ? newStatus : 'offered',
          beforeWorkAttachments: [],
          afterWorkAttachments: [],
          customerAttachments: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (index == -1) {
          currentTickets.insert(0, newTicket);
        } else {
          currentTickets[index] = newTicket;
        }

        print('-----------------------------------------');
        print('🚀 NEW REALTIME TICKET CONSTRUCTED');
        print('-----------------------------------------');
        emit(TicketLoaded(currentTickets));
        return;
      }

      // 3. Fallback for completely valid payload
      final ticket = TicketModel.fromJson(ticketData);
      print('-----------------------------------------');
      print('🚀 TICKET STATUS: ${ticket.status.toUpperCase()}');
      print('🆔 TICKET ID: ${ticket.ticketId}');
      print('-----------------------------------------');

      if (index != -1) {
        currentTickets[index] = ticket;
      } else {
        currentTickets.insert(0, ticket);
      }

      // Emit loaded state with the new ticket from socket
      emit(TicketLoaded(currentTickets));
    } catch (e) {
      print(
        'TicketBloc: [RealTime] ❌ Parse Error: $e. Ignoring to prevent UI disruption.',
      );
    }
  }

  Future<void> _onUploadAttachments(
    UploadAttachments event,
    Emitter<TicketState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TicketLoaded) return;

    final tickets = currentState.tickets;
    emit(TicketAttachmentUploading(tickets));

    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        emit(TicketAttachmentUploadError(tickets, 'Auth token not found'));
        return;
      }

      final List<http.MultipartFile> files = [];
      for (String path in event.filePaths) {
        files.add(await http.MultipartFile.fromPath('attachments[]', path));
      }

      print('Calling Upload Attachments API at: ${DateTime.now()}');
      print('Attachment Type: ${event.type}');

      final response = await _apiService.postMultipart(
        ApiConstants.uploadAttachments(event.ticketId),
        {
          'attachment_type': event.type,
          if (event.workTime != null) 'work_time': event.workTime!,
        },
        files,
        token: token,
      );

      print('Upload Attachments API Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        emit(
          TicketAttachmentUploaded(
            tickets,
            data['message'] ?? 'Attachments uploaded successfully',
            event.type,
          ),
        );
        add(FetchTickets());
      } else {
        emit(
          TicketAttachmentUploadError(
            tickets,
            data['message'] ?? 'Failed to upload attachments',
          ),
        );
      }
    } catch (e) {
      print('Upload Attachments Error: $e');
      emit(
        TicketAttachmentUploadError(
          tickets,
          'Network error. Failed to upload attachments.',
        ),
      );
    }
  }

  Future<void> _onAcceptTicket(
    AcceptTicket event,
    Emitter<TicketState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TicketLoaded) return;

    final tickets = currentState.tickets;
    emit(TicketAccepting(tickets));
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        emit(TicketAcceptError(tickets, 'Authentication token not found'));
        return;
      }

      final response = await _apiService.post(
        ApiConstants.acceptTicket(event.ticketId),
        {}, // Empty body for accept POST
        token: token,
      );

      print('Accept Ticket API Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        emit(
          TicketAccepted(
            tickets,
            data['message'] ?? 'Ticket accepted successfully',
          ),
        );
        // Refresh tickets after acceptance
        add(FetchTickets());
      } else {
        emit(
          TicketAcceptError(
            tickets,
            data['message'] ?? 'Failed to accept ticket',
          ),
        );
      }
    } catch (e) {
      emit(
        TicketAcceptError(tickets, 'Network error. Failed to accept ticket.'),
      );
    }
  }

  Future<void> _onFetchTickets(
    FetchTickets event,
    Emitter<TicketState> emit,
  ) async {
    final currentState = state;
    // Avoid emitting loading if already loading — prevents shimmer flicker
    if (currentState is! TicketLoaded && currentState is! TicketLoading) {
      emit(TicketLoading());
    }
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        emit(const TicketError('Authentication token not found'));
        return;
      }

      final response = await _apiService
          .get(ApiConstants.getTickets, token: token)
          .timeout(const Duration(seconds: 45));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final List<dynamic> ticketsJson = data['data']['tickets'];
        final tickets = ticketsJson
            .map((json) => TicketModel.fromJson(json))
            .toList();
        emit(TicketLoaded(tickets));
      } else {
        emit(TicketError(data['message'] ?? 'Failed to fetch tickets'));
      }
    } catch (e) {
      // On timeout or network error, keep existing data if available
      if (state is! TicketLoaded) {
        emit(const TicketError('Network error. Please check your connection.'));
      }
    }
  }

  Future<void> _onFetchHistory(
    FetchHistory event,
    Emitter<TicketState> emit,
  ) async {
    final currentState = state;
    bool isRefresh = event.isRefresh;

    // 1. Super Fast API Calling: Fetch data only when necessary
    if (!isRefresh && currentState is TicketHistoryLoaded) {
      // If we already have data and it's not a refresh, don't re-fetch unless we're paginating
      // In this simple implementation, we check if we've reached max or if we just want to avoid re-fetching
      if (currentState.hasReachedMax) return;
      // If you want to implement true pagination, you'd check scroll position or a specific 'LoadMore' event.
      // For now, let's allow re-fetch if explicitly requested or if it's the first time.
      return;
    }

    // Determine current tickets to maintain state during loading
    List<TicketModel> currentTickets = [];
    if (currentState is TicketHistoryLoaded && !isRefresh) {
      currentTickets = currentState.tickets;
    }

    // Emit loading state with old tickets to avoid UI jump (if not refresh)
    emit(
      TicketHistoryLoading(
        oldTickets: currentTickets,
        isFirstFetch: isRefresh || currentState is! TicketHistoryLoaded,
      ),
    );

    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        emit(const TicketHistoryError('Authentication token not found'));
        return;
      }

      // 1. Parallel API calls to avoid blocking
      final outcomes = await Future.wait([
        _apiService
            .get(ApiConstants.getCompletedTickets, token: token)
            .timeout(const Duration(seconds: 45)), // Proper timeouts
        _apiService
            .get(ApiConstants.getRejectedTickets, token: token)
            .timeout(const Duration(seconds: 45)),
      ]);

      final completedResponse = outcomes[0];
      final rejectedResponse = outcomes[1];

      List<TicketModel> allHistoryTickets = [];
      int totalCount = 0;

      if (completedResponse.statusCode == 200) {
        final data = jsonDecode(completedResponse.body);
        if (data['success'] == true) {
          final List<dynamic> ticketsJson = data['data']['tickets'];
          // Use total_count from API if available
          totalCount +=
              (data['data']['total_count'] as num?)?.toInt() ??
              ticketsJson.length;
          allHistoryTickets.addAll(
            ticketsJson.map((json) {
              return TicketModel.fromJson(json).copyWith(status: 'completed');
            }),
          );
        }
      }

      if (rejectedResponse.statusCode == 200) {
        final data = jsonDecode(rejectedResponse.body);
        if (data['success'] == true) {
          final List<dynamic> ticketsJson = data['data']['tickets'];
          totalCount +=
              (data['data']['total_count'] as num?)?.toInt() ??
              ticketsJson.length;
          allHistoryTickets.addAll(
            ticketsJson.map((json) {
              return TicketModel.fromJson(json).copyWith(status: 'rejected');
            }),
          );
        }
      }

      // Sort by date (newest first)
      allHistoryTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 5. State Management Optimization: Emit only when changed or new data
      emit(
        TicketHistoryLoaded(
          tickets: allHistoryTickets,
          hasReachedMax:
              true, // For now, we fetch all. If true pagination is added, this would be dynamic.
          totalCount: totalCount,
        ),
      );
    } catch (e) {
      print('Fetch History Error: $e');
      // If we had data, maybe we keep it and show an error toast instead?
      // But requirement says keep it smooth.
      if (currentTickets.isNotEmpty) {
        emit(
          TicketHistoryLoaded(
            tickets: currentTickets,
            hasReachedMax: true,
            totalCount: currentTickets.length,
          ),
        );
      } else {
        emit(
          const TicketHistoryError(
            'Network error. Please check your connection.',
          ),
        );
      }
    }
  }

  Future<void> _onRejectTicket(
    RejectTicket event,
    Emitter<TicketState> emit,
  ) async {
    final currentState = state;
    if (currentState is! TicketLoaded) return;

    final tickets = currentState.tickets;
    emit(TicketRejecting(tickets));

    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        emit(TicketRejectError(tickets, 'Authentication token not found'));
        return;
      }

      final response = await _apiService.post(
        ApiConstants.rejectTicket(event.ticketId),
        {'reason': event.reason},
        token: token,
      );

      print('Reject Ticket API Response: ${response.body}');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        emit(
          TicketRejected(
            tickets,
            data['message'] ?? 'Ticket rejected successfully',
          ),
        );
        add(FetchTickets());
      } else {
        emit(
          TicketRejectError(
            tickets,
            data['message'] ?? 'Failed to reject ticket',
          ),
        );
      }
    } catch (e) {
      print('Reject Ticket Error: $e');
      emit(
        TicketRejectError(tickets, 'Network error. Failed to reject ticket.'),
      );
    }
  }
}
