import 'package:onecharge_d/core/models/ticket.dart';

class CompleteWorkResponse {
  final bool success;
  final String? message;
  final Ticket? ticket;

  CompleteWorkResponse({
    required this.success,
    this.message,
    this.ticket,
  });

  factory CompleteWorkResponse.fromJson(Map<String, dynamic> json) {
    return CompleteWorkResponse(
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

