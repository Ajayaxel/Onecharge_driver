import 'package:onecharge_d/core/models/attachment.dart';
import 'package:onecharge_d/core/models/brand.dart';
import 'package:onecharge_d/core/models/customer.dart';
import 'package:onecharge_d/core/models/issue_category.dart';
import 'package:onecharge_d/core/models/model.dart';
import 'package:onecharge_d/core/models/vehicle_type.dart';
import 'package:onecharge_d/core/models/work_time.dart';

class Ticket {
  final int id;
  final String ticketId;
  final Customer customer;
  final IssueCategory issueCategory;
  final VehicleType vehicleType;
  final Brand brand;
  final Model model;
  final String numberPlate;
  final String? description;
  final String location;
  final String? latitude;
  final String? longitude;
  final String status;
  final List<Attachment> beforeWorkAttachments;
  final List<Attachment> afterWorkAttachments;
  final List<Attachment> customerAttachments;
  final WorkTime? workTime;
  final String createdAt;
  final String updatedAt;

  Ticket({
    required this.id,
    required this.ticketId,
    required this.customer,
    required this.issueCategory,
    required this.vehicleType,
    required this.brand,
    required this.model,
    required this.numberPlate,
    this.description,
    required this.location,
    this.latitude,
    this.longitude,
    required this.status,
    required this.beforeWorkAttachments,
    required this.afterWorkAttachments,
    required this.customerAttachments,
    this.workTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? 0,
      ticketId: json['ticket_id'] ?? '',
      customer: Customer.fromJson(json['customer'] ?? {}),
      issueCategory: IssueCategory.fromJson(json['issue_category'] ?? {}),
      vehicleType: VehicleType.fromJson(json['vehicle_type'] ?? {}),
      brand: Brand.fromJson(json['brand'] ?? {}),
      model: Model.fromJson(json['model'] ?? {}),
      numberPlate: json['number_plate'] ?? '',
      description: json['description'],
      location: json['location'] ?? '',
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      status: json['status'] ?? '',
      beforeWorkAttachments: (json['before_work_attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      afterWorkAttachments: (json['after_work_attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      customerAttachments: (json['customer_attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      workTime: json['work_time'] != null
          ? WorkTime.fromJson(json['work_time'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'customer': customer.toJson(),
      'issue_category': issueCategory.toJson(),
      'vehicle_type': vehicleType.toJson(),
      'brand': brand.toJson(),
      'model': model.toJson(),
      'number_plate': numberPlate,
      'description': description,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'before_work_attachments': beforeWorkAttachments.map((e) => e.toJson()).toList(),
      'after_work_attachments': afterWorkAttachments.map((e) => e.toJson()).toList(),
      'customer_attachments': customerAttachments.map((e) => e.toJson()).toList(),
      'work_time': workTime?.toJson(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
