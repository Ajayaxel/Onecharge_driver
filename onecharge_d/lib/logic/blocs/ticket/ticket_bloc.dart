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
    on<FetchTickets>(_onFetchTickets, transformer: sequential());
    on<AcceptTicket>(_onAcceptTicket, transformer: droppable());
    on<UploadAttachments>(_onUploadAttachments, transformer: droppable());
    on<FetchHistory>(_onFetchHistory, transformer: droppable());
    on<RejectTicket>(_onRejectTicket, transformer: droppable());
    on<RealTimeTicketUpdate>(_onRealTimeTicketUpdate);
    on<ClearTickets>((event, emit) => emit(TicketInitial()));
  }

  Future<void> _onRealTimeTicketUpdate(
    RealTimeTicketUpdate event,
    Emitter<TicketState> emit,
  ) async {
    print('TicketBloc: [RealTime] Status: ${event.eventName}');
    print('TicketBloc: [RealTime] Data: ${jsonEncode(event.data)}');

    final bool isOfferedEvent =
        event.eventName == 'offered' || event.eventName == 'ticket.offered';

    // Handle nested ticket object if present
    final Map<String, dynamic> ticketData = event.data.containsKey('ticket')
        ? event.data['ticket']
        : event.data;

    int ticketId = ticketData['ticket_id'] is int
        ? ticketData['ticket_id']
        : int.tryParse(ticketData['ticket_id']?.toString() ?? '0') ?? 0;

    if (event.eventName == 'cancelled' ||
        event.eventName == 'ticket.cancelled' ||
        event.eventName == 'deleted') {
      print('TicketBloc: [RealTime] Ticket $ticketId cancelled/deleted.');
      if (state is TicketLoaded) {
        final List<TicketModel> currentTickets = List.from(
          (state as TicketLoaded).tickets,
        );
        currentTickets.removeWhere(
          (t) =>
              t.id == ticketId ||
              t.ticketId == ticketId.toString() ||
              t.id.toString() == ticketId.toString(),
        );
        emit(TicketLoaded(currentTickets));
      }
      return;
    }

    try {
      // Ensure we have current tickets list to check against
      List<TicketModel> currentTickets = [];
      if (state is TicketLoaded) {
        currentTickets = List.from((state as TicketLoaded).tickets);
      }

      String newStatus = ticketData['status']?.toString() ?? '';

      // 1. Find if ticket exists
      int index = currentTickets.indexWhere(
        (t) =>
            t.id == ticketId ||
            t.ticketId == ticketId.toString() ||
            t.id.toString() == ticketId.toString(),
      );

      // 2. If it exists and we have a status update
      if (index != -1 && newStatus.isNotEmpty) {
        final List<TicketModel> updatedList = List.from(currentTickets);
        final ticket = updatedList
            .removeAt(index)
            .copyWith(
              status: newStatus,
              latitude:
                  (!ticketData.containsKey('driver_id') &&
                      ticketData.containsKey('latitude'))
                  ? ticketData['latitude'].toString()
                  : currentTickets[index].latitude,
              longitude:
                  (!ticketData.containsKey('driver_id') &&
                      ticketData.containsKey('longitude'))
                  ? ticketData['longitude'].toString()
                  : currentTickets[index].longitude,
              location:
                  ticketData['location']?.toString() ??
                  currentTickets[index].location,
              description:
                  ticketData['message']?.toString() ??
                  currentTickets[index].description,
              updatedAt: DateTime.now(),
            );

        updatedList.add(ticket); // Add back to list, sorting will fix position

        // Sort by Priority first, then by updatedAt descending
        updatedList.sort((a, b) {
          final pA = _getStatusPriority(a.status);
          final pB = _getStatusPriority(b.status);
          if (pA != pB) return pB.compareTo(pA);
          return b.updatedAt.compareTo(a.updatedAt);
        });

        print(
          'TicketBloc: [RealTime] 🔄 Updated ticket $ticketId status to $newStatus',
        );

        if (isOfferedEvent || newStatus.toLowerCase() == 'offered') {
          emit(TicketOffered(updatedList, ticket));
        } else {
          emit(TicketLoaded(updatedList));
        }
        return;
      }

      // 3. Handle partial data or new tickets
      final bool isPartial =
          !ticketData.containsKey('customer') ||
          !ticketData.containsKey('number_plate');

      if (isPartial) {
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

        // Sort by Priority first, then by updatedAt descending
        currentTickets.sort((a, b) {
          final pA = _getStatusPriority(a.status);
          final pB = _getStatusPriority(b.status);
          if (pA != pB) return pB.compareTo(pA);
          return b.updatedAt.compareTo(a.updatedAt);
        });

        if (isOfferedEvent) {
          emit(TicketOffered(currentTickets, newTicket));
        } else {
          emit(TicketLoaded(currentTickets));
        }
        return;
      }

      // 4. Fallback for completely valid payload
      final ticket = TicketModel.fromJson(ticketData);
      if (index != -1) {
        currentTickets[index] = ticket;
      } else {
        currentTickets.insert(0, ticket);
      }

      // Sort by Priority first, then by updatedAt descending
      currentTickets.sort((a, b) {
        final pA = _getStatusPriority(a.status);
        final pB = _getStatusPriority(b.status);
        if (pA != pB) return pB.compareTo(pA);
        return b.updatedAt.compareTo(a.updatedAt);
      });

      if (isOfferedEvent) {
        emit(TicketOffered(currentTickets, ticket));
      } else {
        emit(TicketLoaded(currentTickets));
      }
    } catch (e) {
      print('TicketBloc: [RealTime] ❌ Error: $e');
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

      final response = await _apiService.postMultipart(
        ApiConstants.uploadAttachments(event.ticketId),
        {
          'attachment_type': event.type,
          if (event.workTime != null) 'work_time': event.workTime!,
        },
        files,
        token: token,
      );

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
        {},
        token: token,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        emit(
          TicketAccepted(
            tickets,
            data['message'] ?? 'Ticket accepted successfully',
          ),
        );
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

        // Sort by Priority first, then by updatedAt descending
        tickets.sort((a, b) {
          final pA = _getStatusPriority(a.status);
          final pB = _getStatusPriority(b.status);
          if (pA != pB) return pB.compareTo(pA);
          return b.updatedAt.compareTo(a.updatedAt);
        });

        emit(TicketLoaded(tickets));
      } else {
        emit(TicketError(data['message'] ?? 'Failed to fetch tickets'));
      }
    } catch (e) {
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

    if (!isRefresh && currentState is TicketHistoryLoaded) {
      if (currentState.hasReachedMax) return;
      return;
    }

    List<TicketModel> currentTickets = [];
    if (currentState is TicketHistoryLoaded && !isRefresh) {
      currentTickets = currentState.tickets;
    }

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

      final outcomes = await Future.wait([
        _apiService
            .get(ApiConstants.getCompletedTickets, token: token)
            .timeout(const Duration(seconds: 45)),
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

      allHistoryTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      emit(
        TicketHistoryLoaded(
          tickets: allHistoryTickets,
          hasReachedMax: true,
          totalCount: totalCount,
        ),
      );
    } catch (e) {
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
      emit(
        TicketRejectError(tickets, 'Network error. Failed to reject ticket.'),
      );
    }
  }

  // Define priority weights for statuses
  // Working/In Progress > Accepted > Offered > Others
  int _getStatusPriority(String status) {
    status = status.toLowerCase();
    if (status == 'working' || status == 'in_progress') return 3;
    if (status == 'accepted' ||
        status == 'on_the_way' ||
        status == 'assigned') {
      return 2;
    }
    if (status == 'offered') return 1;
    return 0;
  }
}
