import 'package:equatable/equatable.dart';
import '../../../data/models/ticket_model.dart';

abstract class TicketState extends Equatable {
  const TicketState();

  @override
  List<Object?> get props => [];
}

class TicketInitial extends TicketState {}

class TicketLoading extends TicketState {}

class TicketLoaded extends TicketState {
  final List<TicketModel> tickets;

  const TicketLoaded(this.tickets);

  @override
  List<Object?> get props => [tickets];
}

class TicketError extends TicketState {
  final String message;

  const TicketError(this.message);

  @override
  List<Object?> get props => [message];
}

class TicketAccepting extends TicketLoaded {
  const TicketAccepting(super.tickets);
}

class TicketAccepted extends TicketLoaded {
  final String message;

  const TicketAccepted(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketAcceptError extends TicketLoaded {
  final String message;

  const TicketAcceptError(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketAttachmentUploading extends TicketLoaded {
  const TicketAttachmentUploading(super.tickets);
}

class TicketAttachmentUploaded extends TicketLoaded {
  final String message;
  final String type;
  const TicketAttachmentUploaded(super.tickets, this.message, this.type);

  @override
  List<Object?> get props => [super.tickets, message, type];
}

class TicketAttachmentUploadError extends TicketLoaded {
  final String message;
  const TicketAttachmentUploadError(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketWorkStarted extends TicketLoaded {
  final String message;
  const TicketWorkStarted(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketWorkStartError extends TicketLoaded {
  final String message;
  const TicketWorkStartError(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketWorkCompleted extends TicketLoaded {
  final String message;
  const TicketWorkCompleted(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketWorkCompleteError extends TicketLoaded {
  final String message;
  const TicketWorkCompleteError(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketHistoryLoading extends TicketState {
  final List<TicketModel> oldTickets;
  final bool isFirstFetch;

  const TicketHistoryLoading({
    this.oldTickets = const [],
    this.isFirstFetch = true,
  });

  @override
  List<Object?> get props => [oldTickets, isFirstFetch];
}

class TicketHistoryLoaded extends TicketState {
  final List<TicketModel> tickets;
  final bool hasReachedMax;
  final int totalCount;

  const TicketHistoryLoaded({
    required this.tickets,
    this.hasReachedMax = false,
    this.totalCount = 0,
  });

  TicketHistoryLoaded copyWith({
    List<TicketModel>? tickets,
    bool? hasReachedMax,
    int? totalCount,
  }) {
    return TicketHistoryLoaded(
      tickets: tickets ?? this.tickets,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [tickets, hasReachedMax, totalCount];
}

class TicketHistoryError extends TicketState {
  final String message;

  const TicketHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class TicketRejecting extends TicketLoaded {
  const TicketRejecting(super.tickets);
}

class TicketRejected extends TicketLoaded {
  final String message;
  const TicketRejected(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}

class TicketRejectError extends TicketLoaded {
  final String message;
  const TicketRejectError(super.tickets, this.message);

  @override
  List<Object?> get props => [super.tickets, message];
}
