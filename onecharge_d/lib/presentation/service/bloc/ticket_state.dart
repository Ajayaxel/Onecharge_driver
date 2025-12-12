import 'package:equatable/equatable.dart';
import 'package:onecharge_d/core/models/ticket.dart';

abstract class TicketState extends Equatable {
  const TicketState();

  @override
  List<Object> get props => [];
}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketLoaded extends TicketState {
  final List<Ticket> tickets;
  final bool isUploading;

  const TicketLoaded({
    required this.tickets,
    this.isUploading = false,
  });

  @override
  List<Object> get props => [tickets, isUploading];
}

class TicketError extends TicketState {
  final String message;

  const TicketError({required this.message});

  @override
  List<Object> get props => [message];
}

class TicketUploading extends TicketState {
  const TicketUploading();
}

class TicketUploadSuccess extends TicketState {
  final String message;
  final List<Ticket> tickets; // Updated tickets list

  const TicketUploadSuccess({
    required this.message,
    required this.tickets,
  });

  @override
  List<Object> get props => [message, tickets];
}

class TicketUploadError extends TicketState {
  final String message;

  const TicketUploadError({required this.message});

  @override
  List<Object> get props => [message];
}

class CompleteWorkSuccess extends TicketState {
  final String message;
  final Ticket ticket; // Updated ticket with completed status

  const CompleteWorkSuccess({
    required this.message,
    required this.ticket,
  });

  @override
  List<Object> get props => [message, ticket];
}

class CompleteWorkError extends TicketState {
  final String message;

  const CompleteWorkError({required this.message});

  @override
  List<Object> get props => [message];
}

class StartWorkSuccess extends TicketState {
  final String message;
  final Ticket ticket; // Updated ticket with active status

  const StartWorkSuccess({
    required this.message,
    required this.ticket,
  });

  @override
  List<Object> get props => [message, ticket];
}

class StartWorkError extends TicketState {
  final String message;

  const StartWorkError({required this.message});

  @override
  List<Object> get props => [message];
}
