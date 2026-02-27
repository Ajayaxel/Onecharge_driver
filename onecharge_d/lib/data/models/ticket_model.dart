class TicketModel {
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
  final String latitude;
  final String longitude;
  final String status;
  final List<dynamic> beforeWorkAttachments;
  final List<dynamic> afterWorkAttachments;
  final List<dynamic> customerAttachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
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
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.beforeWorkAttachments,
    required this.afterWorkAttachments,
    required this.customerAttachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      ticketId: json['ticket_id']?.toString() ?? '',
      customer: Customer.fromJson(json['customer'] ?? {}),
      issueCategory: IssueCategory.fromJson(json['issue_category'] ?? {}),
      vehicleType: VehicleType.fromJson(json['vehicle_type'] ?? {}),
      brand: Brand.fromJson(json['brand'] ?? {}),
      model: Model.fromJson(json['model'] ?? {}),
      numberPlate: json['number_plate']?.toString() ?? '',
      description: json['description']?.toString(),
      location: json['location']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '0.0',
      longitude: json['longitude']?.toString() ?? '0.0',
      status: json['status']?.toString() ?? '',
      beforeWorkAttachments: json['before_work_attachments'] ?? [],
      afterWorkAttachments: json['after_work_attachments'] ?? [],
      customerAttachments: json['customer_attachments'] ?? [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  TicketModel copyWith({
    int? id,
    String? ticketId,
    Customer? customer,
    IssueCategory? issueCategory,
    VehicleType? vehicleType,
    Brand? brand,
    Model? model,
    String? numberPlate,
    String? description,
    String? location,
    String? latitude,
    String? longitude,
    String? status,
    List<dynamic>? beforeWorkAttachments,
    List<dynamic>? afterWorkAttachments,
    List<dynamic>? customerAttachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketModel(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      customer: customer ?? this.customer,
      issueCategory: issueCategory ?? this.issueCategory,
      vehicleType: vehicleType ?? this.vehicleType,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      numberPlate: numberPlate ?? this.numberPlate,
      description: description ?? this.description,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      beforeWorkAttachments:
          beforeWorkAttachments ?? this.beforeWorkAttachments,
      afterWorkAttachments: afterWorkAttachments ?? this.afterWorkAttachments,
      customerAttachments: customerAttachments ?? this.customerAttachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Customer {
  final int id;
  final String name;
  final String phone;

  Customer({required this.id, required this.name, required this.phone});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }
}

class IssueCategory {
  final int id;
  final String name;

  IssueCategory({required this.id, required this.name});

  factory IssueCategory.fromJson(Map<String, dynamic> json) {
    return IssueCategory(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class VehicleType {
  final int id;
  final String name;

  VehicleType({required this.id, required this.name});

  factory VehicleType.fromJson(Map<String, dynamic> json) {
    return VehicleType(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class Brand {
  final int id;
  final String name;

  Brand({required this.id, required this.name});

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}

class Model {
  final int id;
  final String name;

  Model({required this.id, required this.name});

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
    );
  }
}
