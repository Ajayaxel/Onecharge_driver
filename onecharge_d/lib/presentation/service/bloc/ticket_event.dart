import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class TicketEvent extends Equatable {
  const TicketEvent();

  @override
  List<Object> get props => [];
}

class FetchTickets extends TicketEvent {
  const FetchTickets();
}

class UploadAttachments extends TicketEvent {
  final int ticketId;
  final List<XFile> files;
  final String attachmentType; // 'before_work' or 'after_work'

  const UploadAttachments({
    required this.ticketId,
    required this.files,
    required this.attachmentType,
  });

  @override
  List<Object> get props => [ticketId, files, attachmentType];
}

class CompleteWork extends TicketEvent {
  final int ticketId;

  const CompleteWork({
    required this.ticketId,
  });

  @override
  List<Object> get props => [ticketId];
}

class StartWork extends TicketEvent {
  final int ticketId;

  const StartWork({
    required this.ticketId,
  });

  @override
  List<Object> get props => [ticketId];
}
