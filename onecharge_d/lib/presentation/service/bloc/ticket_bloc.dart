import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:onecharge_d/core/repository/ticket_repository.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_event.dart';
import 'package:onecharge_d/presentation/service/bloc/ticket_state.dart';

class TicketBloc extends Bloc<TicketEvent, TicketState> {
  final TicketRepository ticketRepository;

  TicketBloc({required this.ticketRepository}) : super(TicketInitial()) {
    on<FetchTickets>(_onFetchTickets);
    on<UploadAttachments>(_onUploadAttachments);
    on<CompleteWork>(_onCompleteWork);
    on<StartWork>(_onStartWork);
  }

  Future<void> _onFetchTickets(
    FetchTickets event,
    Emitter<TicketState> emit,
  ) async {
    print('\n🔄 [BLOC EVENT] FetchTickets');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    emit(TicketLoading());
    print('📤 [STATE] TicketLoading');

    try {
      final response = await ticketRepository.getTickets();

      if (response.success) {
        emit(TicketLoaded(tickets: response.tickets));
        print('📤 [STATE] TicketLoaded - ${response.tickets.length} ticket(s)');
        
        // Print ticket details
        for (var ticket in response.tickets) {
          print('  🎫 Ticket ID: ${ticket.ticketId}');
          print('  📋 Status: ${ticket.status}');
          print('  🏷️  Issue Type: ${ticket.issueCategory.name}');
          print('  📍 Location: ${ticket.location}');
          print('  ──────────────────────────────────────');
        }
      } else {
        emit(TicketError(message: response.message ?? 'Failed to fetch tickets'));
        print('📤 [STATE] TicketError: ${response.message}');
      }
    } catch (e) {
      emit(TicketError(message: 'An unexpected error occurred: ${e.toString()}'));
      print('❌ [EXCEPTION] ${e.toString()}');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  Future<void> _onUploadAttachments(
    UploadAttachments event,
    Emitter<TicketState> emit,
  ) async {
    print('\n🔄 [BLOC EVENT] UploadAttachments');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎫 Ticket ID: ${event.ticketId}');
    print('📎 Attachment Type: ${event.attachmentType}');
    print('📁 Files Count: ${event.files.length}');
    
    // Preserve current state and set isUploading to true
    final currentState = state;
    if (currentState is TicketLoaded) {
      emit(TicketLoaded(tickets: currentState.tickets, isUploading: true));
      print('📤 [STATE] TicketLoaded (isUploading: true)');
    } else {
      emit(TicketUploading());
      print('📤 [STATE] TicketUploading');
    }

    try {
      final response = await ticketRepository.uploadAttachments(
        ticketId: event.ticketId,
        files: event.files,
        attachmentType: event.attachmentType,
      );

      if (response.success) {
        print('✅ Upload successful, refreshing tickets...');
        // Refresh tickets list after successful upload
        final ticketsResponse = await ticketRepository.getTickets();
        
        if (ticketsResponse.success) {
          // First emit success state for the listener
          emit(TicketUploadSuccess(
            message: response.message ?? 'Attachments uploaded successfully',
            tickets: ticketsResponse.tickets,
          ));
          print('📤 [STATE] TicketUploadSuccess');
          // Then emit loaded state with updated tickets and isUploading false
          emit(TicketLoaded(tickets: ticketsResponse.tickets, isUploading: false));
          print('📤 [STATE] TicketLoaded (isUploading: false)');
        } else {
          // Restore previous state on refresh failure
          if (currentState is TicketLoaded) {
            emit(TicketLoaded(tickets: currentState.tickets, isUploading: false));
          }
          // Emit error for listener
          emit(TicketUploadError(
            message: response.message ?? 'Attachments uploaded but failed to refresh tickets',
          ));
          print('❌ [ERROR] Upload succeeded but refresh failed');
          // Restore state after error
          if (currentState is TicketLoaded) {
            emit(TicketLoaded(tickets: currentState.tickets, isUploading: false));
          }
        }
      } else {
        print('❌ [ERROR] Upload failed: ${response.message}');
        // Restore previous state on upload failure
        if (currentState is TicketLoaded) {
          emit(TicketLoaded(tickets: currentState.tickets, isUploading: false));
        }
        // Emit error for listener
        emit(TicketUploadError(
          message: response.message ?? 'Failed to upload attachments',
        ));
        print('📤 [STATE] TicketUploadError');
        // Restore state after error
        if (currentState is TicketLoaded) {
          emit(TicketLoaded(tickets: currentState.tickets, isUploading: false));
        }
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      // Restore previous state on error
      if (currentState is TicketLoaded) {
        emit(TicketLoaded(tickets: currentState.tickets, isUploading: false));
      }
      // Emit error for listener
      emit(TicketUploadError(
        message: 'An unexpected error occurred: ${e.toString()}',
      ));
      print('📤 [STATE] TicketUploadError');
      // Restore state after error
      if (currentState is TicketLoaded) {
        emit(TicketLoaded(tickets: currentState.tickets, isUploading: false));
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  Future<void> _onCompleteWork(
    CompleteWork event,
    Emitter<TicketState> emit,
  ) async {
    print('\n🔄 [BLOC EVENT] CompleteWork');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎫 Ticket ID: ${event.ticketId}');
    
    final currentState = state;
    
    try {
      final response = await ticketRepository.completeWork(ticketId: event.ticketId);

      if (response.success && response.ticket != null) {
        print('✅ Complete work successful');
        print('📊 New Ticket Status: ${response.ticket!.status}');
        // Emit success state with the updated ticket
        emit(CompleteWorkSuccess(
          message: response.message ?? 'Work completed successfully',
          ticket: response.ticket!,
        ));
        print('📤 [STATE] CompleteWorkSuccess');
        
        // Wait a bit to ensure navigation happens before refreshing tickets
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Refresh tickets list after successful completion
        print('🔄 Refreshing tickets list...');
        final ticketsResponse = await ticketRepository.getTickets();
        
        if (ticketsResponse.success) {
          // Update to loaded state with refreshed tickets
          emit(TicketLoaded(tickets: ticketsResponse.tickets));
          print('📤 [STATE] TicketLoaded (refreshed)');
        } else {
          // Keep current state if refresh fails
          if (currentState is TicketLoaded) {
            emit(TicketLoaded(tickets: currentState.tickets));
            print('⚠️  Refresh failed, keeping previous state');
          }
        }
      } else {
        print('❌ [ERROR] Complete work failed: ${response.message}');
        // Emit error state for CompleteWork failure
        emit(CompleteWorkError(message: response.message ?? 'Failed to complete work'));
        print('📤 [STATE] CompleteWorkError');
        // Restore previous state after a delay
        if (currentState is TicketLoaded) {
          emit(TicketLoaded(tickets: currentState.tickets));
        }
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      emit(CompleteWorkError(message: 'An unexpected error occurred: ${e.toString()}'));
      print('📤 [STATE] CompleteWorkError');
      // Restore previous state after error
      if (currentState is TicketLoaded) {
        emit(TicketLoaded(tickets: currentState.tickets));
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }

  Future<void> _onStartWork(
    StartWork event,
    Emitter<TicketState> emit,
  ) async {
    print('\n🔄 [BLOC EVENT] StartWork');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🎫 Ticket ID: ${event.ticketId}');
    
    final currentState = state;
    
    try {
      final response = await ticketRepository.startWork(ticketId: event.ticketId);

      if (response.success && response.ticket != null) {
        print('✅ Start work successful');
        print('📊 New Ticket Status: ${response.ticket!.status}');
        // Emit success state with the updated ticket
        emit(StartWorkSuccess(
          message: response.message ?? 'Work started successfully',
          ticket: response.ticket!,
        ));
        print('📤 [STATE] StartWorkSuccess');
        
        // Wait a bit to ensure navigation happens before refreshing tickets
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Refresh tickets list after successful start
        print('🔄 Refreshing tickets list...');
        final ticketsResponse = await ticketRepository.getTickets();
        
        if (ticketsResponse.success) {
          // Update to loaded state with refreshed tickets
          emit(TicketLoaded(tickets: ticketsResponse.tickets));
          print('📤 [STATE] TicketLoaded (refreshed)');
        } else {
          // Keep current state if refresh fails
          if (currentState is TicketLoaded) {
            emit(TicketLoaded(tickets: currentState.tickets));
            print('⚠️  Refresh failed, keeping previous state');
          }
        }
      } else {
        print('❌ [ERROR] Start work failed: ${response.message}');
        // Emit error state for StartWork failure
        emit(StartWorkError(message: response.message ?? 'Failed to start work'));
        print('📤 [STATE] StartWorkError');
        // Restore previous state after a delay
        if (currentState is TicketLoaded) {
          emit(TicketLoaded(tickets: currentState.tickets));
        }
      }
    } catch (e) {
      print('❌ [EXCEPTION] ${e.toString()}');
      emit(StartWorkError(message: 'An unexpected error occurred: ${e.toString()}'));
      print('📤 [STATE] StartWorkError');
      // Restore previous state after error
      if (currentState is TicketLoaded) {
        emit(TicketLoaded(tickets: currentState.tickets));
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
  }
}
