import 'package:equatable/equatable.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object> get props => [];
}

class FetchTickets extends TicketEvent {}

class AcceptTicket extends TicketEvent {
  final String ticketId;

  const AcceptTicket(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}

class UploadAttachments extends TicketEvent {
  final String ticketId;
  final String type; // 'before_work' or 'after_work'
  final List<String> filePaths;
  final String? workTime;

  const UploadAttachments({
    required this.ticketId,
    required this.type,
    required this.filePaths,
    this.workTime,
  });

  @override
  List<Object> get props => [
    ticketId,
    type,
    filePaths,
    if (workTime != null) workTime!,
  ];
}

class StartWork extends TicketEvent {
  final String ticketId;

  const StartWork(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}

class CompleteWork extends TicketEvent {
  final String ticketId;

  const CompleteWork(this.ticketId);

  @override
  List<Object> get props => [ticketId];
}

class FetchHistory extends TicketEvent {
  final bool isRefresh;
  const FetchHistory({this.isRefresh = false});

  @override
  List<Object> get props => [isRefresh];
}

class RejectTicket extends TicketEvent {
  final String ticketId;
  final String reason;

  const RejectTicket({required this.ticketId, required this.reason});

  @override
  List<Object> get props => [ticketId, reason];
}

class RealTimeTicketUpdate extends TicketEvent {
  final String eventName;
  final Map<String, dynamic> data;

  const RealTimeTicketUpdate(this.eventName, this.data);

  @override
  List<Object> get props => [eventName, data];
}
