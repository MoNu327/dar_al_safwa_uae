class TicketModel {
  final String complaintId;
  final String complaintNumber;
  final String category;
  final String subcategory;
  final String description;
  final String? reply;
  final String? replyByAdmin;
  final String? amountPaid;
  final String? amountPaidStatus;
  final TicketStatus status;
  final String createdAt;
  final String? lastUpdated;
  final String? lastUpdatedByAdmin;
  final bool addedByAdmin;
  final PropertyDetails property;
  final TicketImages images;
  final AdminInfo adminInfo;

  TicketModel({
    required this.complaintId,
    required this.complaintNumber,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.reply,
    required this.replyByAdmin,
    required this.amountPaid,
    required this.amountPaidStatus,
    required this.status,
    required this.createdAt,
    required this.lastUpdated,
    required this.lastUpdatedByAdmin,
    required this.addedByAdmin,
    required this.property,
    required this.images,
    required this.adminInfo,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final complaintData = json['complaint'] ?? {};
    final propertyData = json['property'] ?? {};
    final imagesData = json['images'] ?? {};
    final adminInfoData = json['admin_info'] ?? {};

    return TicketModel(
      complaintId: complaintData['id'] ?? '',
      complaintNumber: complaintData['complaint_number'] ?? '',
      category: complaintData['category'] ?? '',
      subcategory: complaintData['subcategory'] ?? '',
      description: complaintData['description'] ?? '',
      reply: complaintData['reply'],
      replyByAdmin: complaintData['reply_by_admin'],
      amountPaid: complaintData['amount_paid'],
      amountPaidStatus: complaintData['amount_paid_status'],
      status: TicketStatusHelper.fromString(complaintData['status']?['en'] ?? ''),
      createdAt: complaintData['created_at'] ?? '',
      lastUpdated: complaintData['last_updated'],
      lastUpdatedByAdmin: complaintData['last_updated_by_admin'],
      addedByAdmin: complaintData['added_by_admin'] ?? false,
      property: PropertyDetails.fromJson(propertyData),
      images: TicketImages.fromJson(imagesData),
      adminInfo: AdminInfo.fromJson(adminInfoData),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint': {
        'id': complaintId,
        'complaint_number': complaintNumber,
        'category': category,
        'subcategory': subcategory,
        'description': description,
        'reply': reply,
        'reply_by_admin': replyByAdmin,
        'amount_paid': amountPaid,
        'amount_paid_status': amountPaidStatus,
        'status': {'en': status.name},
        'created_at': createdAt,
        'last_updated': lastUpdated,
        'last_updated_by_admin': lastUpdatedByAdmin,
        'added_by_admin': addedByAdmin,
      },
      'property': property.toJson(),
      'images': images.toJson(),
      'admin_info': adminInfo.toJson(),
    };
  }
}

class PropertyDetails {
  final String id;
  final String title;
  final PropertyUnit unit;
  final List<Technician> assignedTechnicians;
  final Technician? currentTechnician;

  PropertyDetails({
    required this.id,
    required this.title,
    required this.unit,
    required this.assignedTechnicians,
    required this.currentTechnician,
  });

  factory PropertyDetails.fromJson(Map<String, dynamic> json) {
    final unitData = json['unit'] ?? {};
    final technicians = (json['assigned_technicians'] as List<dynamic>? ?? [])
        .map((e) => Technician.fromJson(e))
        .toList();

    return PropertyDetails(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      unit: PropertyUnit.fromJson(unitData),
      assignedTechnicians: technicians,
      currentTechnician: json['current_technician'] != null 
          ? Technician.fromJson(json['current_technician']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'unit': unit.toJson(),
      'assigned_technicians': assignedTechnicians.map((e) => e.toJson()).toList(),
      'current_technician': currentTechnician?.toJson(),
    };
  }
}

class PropertyUnit {
  final String number;
  final String addressFormat;
  final String type;

  PropertyUnit({
    required this.number,
    required this.addressFormat,
    required this.type,
  });

  factory PropertyUnit.fromJson(Map<String, dynamic> json) {
    return PropertyUnit(
      number: json['number'] ?? '',
      addressFormat: json['address_format'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'address_format': addressFormat,
      'type': type,
    };
  }
}

class Technician {
  final String assignmentId;
  final String uid;
  final String? name;
  final String email;
  final String phone;
  final String? photo;
  final String assignedAt;
  final String status;
  final bool isCurrent;

  Technician({
    required this.assignmentId,
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.photo,
    required this.assignedAt,
    required this.status,
    required this.isCurrent,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      assignmentId: json['assignment_id'] ?? '',
      uid: json['uid'] ?? '',
      name: json['name'],
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      photo: json['photo'],
      assignedAt: json['assigned_at'] ?? '',
      status: json['status'] ?? '',
      isCurrent: json['is_current'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assignment_id': assignmentId,
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'photo': photo,
      'assigned_at': assignedAt,
      'status': status,
      'is_current': isCurrent,
    };
  }
}

class TicketImages {
  final List<String> tenantUploads;
  final List<String> adminUploads;
  final List<String> technicianUploads;

  TicketImages({
    required this.tenantUploads,
    required this.adminUploads,
    required this.technicianUploads,
  });

  factory TicketImages.fromJson(Map<String, dynamic> json) {
    return TicketImages(
      tenantUploads: (json['tenant_uploads'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      adminUploads: (json['admin_uploads'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      technicianUploads: (json['technician_uploads'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenant_uploads': tenantUploads,
      'admin_uploads': adminUploads,
      'technician_uploads': technicianUploads,
    };
  }
}

class AdminInfo {
  final bool addedByAdmin;
  final String? lastUpdatedByAdmin;
  final String? replyByAdmin;
  final int adminUploadedImagesCount;
  final int adminTechnicianImagesCount;

  AdminInfo({
    required this.addedByAdmin,
    required this.lastUpdatedByAdmin,
    required this.replyByAdmin,
    required this.adminUploadedImagesCount,
    required this.adminTechnicianImagesCount,
  });

  factory AdminInfo.fromJson(Map<String, dynamic> json) {
    return AdminInfo(
      addedByAdmin: json['added_by_admin'] ?? false,
      lastUpdatedByAdmin: json['last_updated_by_admin'],
      replyByAdmin: json['reply_by_admin'],
      adminUploadedImagesCount: json['admin_uploaded_images_count'] ?? 0,
      adminTechnicianImagesCount: json['admin_technician_images_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'added_by_admin': addedByAdmin,
      'last_updated_by_admin': lastUpdatedByAdmin,
      'reply_by_admin': replyByAdmin,
      'admin_uploaded_images_count': adminUploadedImagesCount,
      'admin_technician_images_count': adminTechnicianImagesCount,
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

// class TicketModel {
//   final String complaintId;
//   final String complaintNumber;
//   final String category;
//   final String subcategory;
//   final String description;
//   final String? reply;
//   final String date;
//   final TicketStatus status;
//   final String statusText;
//   final PropertyDetails property;
//   final List<String> images;

//   TicketModel({
//     required this.complaintId,
//     required this.complaintNumber,
//     required this.category,
//     required this.subcategory,
//     required this.description,
//     required this.reply,
//     required this.date,
//     required this.status,
//     required this.statusText,
//     required this.property,
//     required this.images,
//   });

//   factory TicketModel.fromJson(Map<String, dynamic> json) {
//     return TicketModel(
//       complaintId: json['complaint_id'] ?? '',
//       complaintNumber: json['complaint_number'] ?? '',
//       category: json['category'] ?? '',
//       subcategory: json['subcategory'] ?? '',
//       description: json['description'] ?? '',
//       reply: json['reply'],
//       date: json['date'] ?? '',
//       status: TicketStatusHelper.fromString(json['status']?.toString() ?? '0'),
//       statusText: json['status_text']?['en'] ?? '',
//       property: PropertyDetails(
//         title: json['property_name'] ?? '',
//         unitNumber: json['unit_number'] ?? '',
//         addressFormat: json['full_address'] ?? '',
//         unitType: '', // Not available in the response
//       ),
//       images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'complaint_id': complaintId,
//       'complaint_number': complaintNumber,
//       'category': category,
//       'subcategory': subcategory,
//       'description': description,
//       'reply': reply,
//       'date': date,
//       'status': status.index.toString(),
//       'status_text': {'en': statusText},
//       'property_name': property.title,
//       'unit_number': property.unitNumber,
//       'full_address': property.addressFormat,
//       'images': images,
//     };
//   }
// }

// class PropertyDetails {
//   final String title;
//   final String unitNumber;
//   final String addressFormat;
//   final String unitType;

//   PropertyDetails({
//     required this.title,
//     required this.unitNumber,
//     required this.addressFormat,
//     required this.unitType,
//   });
// }

// enum TicketStatus { pending, rectified, inProgress, completed }

// class TicketStatusHelper {
//   static TicketStatus fromString(String status) {
//     switch (status.toLowerCase()) {
//       case '1':
//       case 'rectified':
//         return TicketStatus.rectified;
//       case '2':
//       case 'in progress':
//         return TicketStatus.inProgress;
//       case '3':
//       case 'completed':
//         return TicketStatus.completed;
//       case '0':
//       case 'pending':
//       default:
//         return TicketStatus.pending;
//     }
//   }
// }