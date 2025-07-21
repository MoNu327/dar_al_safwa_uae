class TicketModel {
  final String complaintId;
  final String complaintNumber;
  final String category;
  final String subcategory;
  final String description;
  final String reply;
  final String amountPaid;
  final String amountPaidStatus;
  final TicketStatus status;
  final String lastUpdated;
  // final String property;
  final List<String> images;

  TicketModel({
    required this.complaintId,
    required this.complaintNumber,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.reply,
    required this.amountPaid,
    required this.amountPaidStatus,
    required this.status,
    required this.lastUpdated,
    // required this.property,
    required this.images,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      complaintId: json['complaint_id'] ?? '',
      complaintNumber: json['complaint_number'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      description: json['description'] ?? '',
      reply: json['reply'] ?? '',
      amountPaid: json['amount_paid'] ?? '0',
      amountPaidStatus: json['amount_paid_status'] ?? '0',
      status: TicketStatusHelper.fromString(json['status']?['en'] ?? ''),
      lastUpdated: json['last_updated'] ?? '',
      // property: PropertyDetails.fromJson(json['property'] ?? {}),
      images: json['images'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint_id': complaintId,
      'complaint_number': complaintNumber,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'reply': reply,
      'amount_paid': amountPaid,
      'amount_paid_status': amountPaidStatus,
      'status': status.name,
      'last_updated': lastUpdated,
      // 'property': property.toJson(),
      'images': images,
    };
  }
}

class PropertyDetails {
  final String title;
  final String unitNumber;
  final String addressFormat;
  final String unitType;

  PropertyDetails({
    required this.title,
    required this.unitNumber,
    required this.addressFormat,
    required this.unitType,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    return PropertyDetails(
      title: json['title'] ?? '',
      unitNumber: json['unit_number'] ?? '',
      addressFormat: json['address_format'] ?? '',
      unitType: json['unit_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'unit_number': unitNumber,
      'address_format': addressFormat,
      'unit_type': unitType,
    };
  }
}

class TicketImages {
  final List<String> tenantImages;
  final List<String> technicianImages;

  TicketImages({
    required this.tenantImages,
    required this.technicianImages,
  });

  factory TicketImages.fromJson(Map<String, dynamic> json) {
    return TicketImages(
      tenantImages: (json['tenant_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      technicianImages: (json['technician_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_images': tenantImages,
      'technician_images': technicianImages,
    };
  }
}

enum TicketStatus { pending, rectified, inProgress, completed }

class TicketStatusHelper {
  static TicketStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return TicketStatus.pending;
      case 'rectified':
        return TicketStatus.rectified;
      case 'in progress':
        return TicketStatus.inProgress;
      case 'resolved':
      case 'completed':
        return TicketStatus.completed;
      default:
        return TicketStatus.pending;
    }
  }
}
