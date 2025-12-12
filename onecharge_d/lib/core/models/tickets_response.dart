import 'package:onecharge_d/core/models/ticket.dart';

class TicketsResponse {
  final bool success;
  final String? message;
  final List<Ticket> tickets;

  TicketsResponse({
    required this.success,
    this.message,
    required this.tickets,
  });

  factory TicketsResponse.fromJson(Map<String, dynamic> json) {
    List<Ticket> ticketsList = [];
    
    if (json['data'] != null && json['data']['tickets'] != null) {
      final ticketsData = json['data']['tickets'] as List<dynamic>;
      ticketsList = ticketsData
          .map((e) => Ticket.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return TicketsResponse(
      success: json['success'] ?? false,
      message: json['message'],
      tickets: ticketsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': {
        'tickets': tickets.map((e) => e.toJson()).toList(),
      },
    };
  }
}
