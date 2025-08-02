import 'dart:convert';

class ComplaintDetailsResponse {
  final bool success;
  final LocalizedMessage message;
  final ComplaintData data;

  ComplaintDetailsResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory ComplaintDetailsResponse.fromJson(Map<String, dynamic> json) {
    return ComplaintDetailsResponse(
      success: json['success'] as bool? ?? false,
      message: LocalizedMessage.fromJson(json['message'] ?? {}),
      data: ComplaintData.fromJson(json['data'] ?? {}),
    );
  }

  factory ComplaintDetailsResponse.fromRawJson(String str) =>
      ComplaintDetailsResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message.toJson(),
        'data': data.toJson(),
      };
}

class LocalizedMessage {
  final String en;
  final String ar;

  LocalizedMessage({
    required this.en,
    required this.ar,
  });

  factory LocalizedMessage.fromJson(Map<String, dynamic> json) {
    return LocalizedMessage(
      en: json['en']?.toString() ?? '',
      ar: json['ar']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'en': en,
        'ar': ar,
      };
}

class ComplaintData {
  final String complaintId;
  final String complaintNumber;
  final String category;
  final String subcategory;
  final String description;
  final String? reply;
  final String? replyByAdmin;
  final String? amountPaid;
  final String? amountPaidStatus;
  final Status status;
  final String createdAt;
  final String? lastUpdated;
  final String? lastUpdatedByAdmin;
  final bool addedByAdmin;
  final Property property;
  final ComplaintImages images;

  ComplaintData({
    required this.complaintId,
    required this.complaintNumber,
    required this.category,
    required this.subcategory,
    required this.description,
    this.reply,
    this.replyByAdmin,
    this.amountPaid,
    this.amountPaidStatus,
    required this.status,
    required this.createdAt,
    this.lastUpdated,
    this.lastUpdatedByAdmin,
    required this.addedByAdmin,
    required this.property,
    required this.images,
  });

  factory ComplaintData.fromJson(Map<String, dynamic> json) {
    return ComplaintData(
      complaintId: json['complaint_id']?.toString() ?? '',
      complaintNumber: json['complaint_number']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subcategory: json['subcategory']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      reply: json['reply']?.toString(),
      replyByAdmin: json['reply_by_admin']?.toString(),
      amountPaid: json['amount_paid']?.toString(),
      amountPaidStatus: json['amount_paid_status']?.toString(),
      status: Status.fromJson(json['status'] ?? {}),
      createdAt: json['created_at']?.toString() ?? '',
      lastUpdated: json['last_updated']?.toString(),
      lastUpdatedByAdmin: json['last_updated_by_admin']?.toString(),
      addedByAdmin: json['added_by_admin'] as bool? ?? false,
      property: Property.fromJson(json['property'] ?? {}),
      images: ComplaintImages.fromJson(json['images'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'complaint_id': complaintId,
        'complaint_number': complaintNumber,
        'category': category,
        'subcategory': subcategory,
        'description': description,
        'reply': reply,
        'reply_by_admin': replyByAdmin,
        'amount_paid': amountPaid,
        'amount_paid_status': amountPaidStatus,
        'status': status.toJson(),
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'last_updated_by_admin': lastUpdatedByAdmin,
        'added_by_admin': addedByAdmin,
        'property': property.toJson(),
        'images': images.toJson(),
      };
}

class Status {
  final String en;

  Status({
    required this.en,
  });

  factory Status.fromJson(Map<String, dynamic> json) {
    return Status(
      en: json['en']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'en': en,
      };
}

class Property {
  final String id;
  final String title;
  final String unitNumber;
  final String addressFormat;
  final String unitType;
  final List<AssignedTechnician> assignedTechnicians;

  Property({
    required this.id,
    required this.title,
    required this.unitNumber,
    required this.addressFormat,
    required this.unitType,
    required this.assignedTechnicians,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      unitNumber: json['unit_number']?.toString() ?? '',
      addressFormat: json['address_format']?.toString() ?? '',
      unitType: json['unit_type']?.toString() ?? '',
      assignedTechnicians: (json['assigned_technicians'] as List<dynamic>? ?? [])
          .map((e) => AssignedTechnician.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'unit_number': unitNumber,
        'address_format': addressFormat,
        'unit_type': unitType,
        'assigned_technicians':
            assignedTechnicians.map((e) => e.toJson()).toList(),
      };
}

class AssignedTechnician {
  final String technicianId;
  final String name;
  final String email;
  final String phone;
  final String? photo;
  final String assignedAt;

  AssignedTechnician({
    required this.technicianId,
    required this.name,
    required this.email,
    required this.phone,
    this.photo,
    required this.assignedAt,
  });

  factory AssignedTechnician.fromJson(Map<String, dynamic> json) {
    return AssignedTechnician(
      technicianId: json['technician_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photo: json['photo']?.toString(),
      assignedAt: json['assigned_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'technician_id': technicianId,
        'name': name,
        'email': email,
        'phone': phone,
        'photo': photo,
        'assigned_at': assignedAt,
      };
}

class ComplaintImages {
  final List<String> tenantUploaded;
  final List<String> adminUploaded;
  final List<String> technicianUploaded;
  final List<String> adminTechnicianUploaded;

  ComplaintImages({
    required this.tenantUploaded,
    required this.adminUploaded,
    required this.technicianUploaded,
    required this.adminTechnicianUploaded,
  });

  factory ComplaintImages.fromJson(Map<String, dynamic> json) {
    return ComplaintImages(
      tenantUploaded:
          (json['tenant_uploaded'] as List<dynamic>? ?? []).cast<String>(),
      adminUploaded:
          (json['admin_uploaded'] as List<dynamic>? ?? []).cast<String>(),
      technicianUploaded:
          (json['technician_uploaded'] as List<dynamic>? ?? []).cast<String>(),
      adminTechnicianUploaded: (json['admin_technician_uploaded'] as List<dynamic>? ?? [])
          .cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'tenant_uploaded': tenantUploaded,
        'admin_uploaded': adminUploaded,
        'technician_uploaded': technicianUploaded,
        'admin_technician_uploaded': adminTechnicianUploaded,
      };
}