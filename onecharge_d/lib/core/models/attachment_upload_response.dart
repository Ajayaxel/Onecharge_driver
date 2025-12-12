import 'package:onecharge_d/core/models/ticket.dart';

class AttachmentUploadResponse {
  final bool success;
  final String? message;
  final Ticket? ticket;

  AttachmentUploadResponse({
    required this.success,
    this.message,
    this.ticket,
  });

  factory AttachmentUploadResponse.fromJson(Map<String, dynamic> json) {
    return AttachmentUploadResponse(
      success: json['success'] ?? false,
      message: json['message'],
      ticket: json['data'] != null && json['data']['ticket'] != null
          ? Ticket.fromJson(json['data']['ticket'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': ticket != null ? {'ticket': ticket!.toJson()} : null,
    };
  }
}

