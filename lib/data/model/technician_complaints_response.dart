import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

part 'technician_complaints_response.g.dart';

@JsonSerializable()
class TechnicianComplaintsResponse {
  @JsonKey(name: 'success', fromJson: statusFromJson)
  final bool? status;

  final Message? message;
  final ComplaintResponseData? data;

  TechnicianComplaintsResponse({
    this.status,
    this.message,
    this.data,
  });

  factory TechnicianComplaintsResponse.fromJson(Map<String, dynamic> json) =>
      _$TechnicianComplaintsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianComplaintsResponseToJson(this);

  static bool statusFromJson(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value == 1;
    return false;
  }
}

@JsonSerializable()
class Message {
  final String? en;
  final String? ar;

  Message({this.en, this.ar});

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class ComplaintResponseData {
  final Complaints? complaint;
  final Property? property;

  @JsonKey(name: 'images')
  final List<String>? directImages;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final TechnicianImages? images;

  final AdminInfo? adminInfo;

  ComplaintResponseData({
    this.complaint,
    this.property,
    this.directImages,
    this.images,
    this.adminInfo,
  });

  List<String> get allImages {
    if (directImages != null && directImages!.isNotEmpty) {
      return directImages!;
    }
    return images?.allImages ?? [];
  }

  factory ComplaintResponseData.fromJson(Map<String, dynamic> json) {
    if (json['images'] is List) {
      return ComplaintResponseData(
        complaint: Complaints.fromJson(json['complaint'] ?? {}),
        property: json['property'] != null
            ? Property.fromJson(json['property'])
            : null,
        directImages: List<String>.from(json['images'] ?? []),
        images: TechnicianImages(images: List<String>.from(json['images'] ?? [])),
        adminInfo: json['adminInfo'] != null
            ? AdminInfo.fromJson(json['adminInfo'])
            : null,
      );
    }
    return _$ComplaintResponseDataFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ComplaintResponseDataToJson(this);
}

@JsonSerializable()
class Complaints {
  @JsonKey(readValue: _readComplaintId)
  final String? complaintId;

  @JsonKey(name: 'complaint_number')
  final String? complaintNumber;

  final String? category;
  final String? subcategory;
  final String? description;
  final String? reply;

  @JsonKey(name: 'reply_by_admin')
  final String? replyByAdmin;

  @JsonKey(name: 'amount_paid')
  final String? amountPaid;

  @JsonKey(name: 'amount_paid_status')
  final String? amountPaidStatus;

  @JsonKey(name: 'status', fromJson: _statusCodeFromJson)
  final int? statusCode;

  @JsonKey(name: 'status_text')
  final Status? status;

  @JsonKey(readValue: _readCreatedAt)
  final String? createdAt;

  @JsonKey(name: 'last_updated')
  final String? lastUpdated;

  @JsonKey(name: 'last_updated_by_admin')
  final String? lastUpdatedByAdmin;

  @JsonKey(name: 'added_by_admin')
  final bool? addedByAdmin;

  @JsonKey(name: 'property_name')
  final String? propertyName;

  @JsonKey(name: 'unit_number')
  final String? unitNumber;

  @JsonKey(name: 'full_address')
  final String? fullAddress;

  @JsonKey(name: 'flatno_id')
  final String? flatnoId;

  Complaints({
    this.complaintId,
    this.complaintNumber,
    this.category,
    this.subcategory,
    this.description,
    this.reply,
    this.replyByAdmin,
    this.amountPaid,
    this.amountPaidStatus,
    this.statusCode,
    this.status,
    this.createdAt,
    this.lastUpdated,
    this.lastUpdatedByAdmin,
    this.addedByAdmin,
    this.propertyName,
    this.unitNumber,
    this.fullAddress,
    this.flatnoId,
  });

  factory Complaints.fromJson(Map<String, dynamic> json) =>
      _$ComplaintsFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintsToJson(this);

  static Object? _readComplaintId(Map json, String _) {
    final v = json['complaint_id'] ?? json['id'];
    return v?.toString();
  }

  static int? _statusCodeFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static Object? _readCreatedAt(Map json, String _) {
    return json['created_at'] ?? json['date'];
  }

  String get formattedDate {
    if (createdAt == null) return 'No date';
    try {
      return DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(createdAt!));
    } catch (_) {
      return createdAt!;
    }
  }

  String get displayStatus {
    return status?.en?.replaceAll('in progres', 'in progress') ?? 'Unknown';
  }

  Color get statusColor {
    switch (displayStatus.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rectified':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

@JsonSerializable()
class Status {
  final String? en;

  Status({this.en});

  factory Status.fromJson(Map<String, dynamic> json) => _$StatusFromJson(json);
  Map<String, dynamic> toJson() => _$StatusToJson(this);
}

@JsonSerializable()
class Property {
  final String? id;
  final String? title;
  final PropertyUnit? unit;
  
  @JsonKey(name: 'assigned_technicians')
  final List<Technician>? assignedTechnicians;
  
  @JsonKey(name: 'current_technician')
  final Technician? currentTechnician;

  Property({
    this.id,
    this.title,
    this.unit,
    this.assignedTechnicians,
    this.currentTechnician,
  });

  factory Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

@JsonSerializable()
class PropertyUnit {
  final String? number;
  
  @JsonKey(name: 'address_format')
  final String? addressFormat;
  
  @JsonKey(name: 'type')
  final String? unitType;

  PropertyUnit({
    this.number,
    this.addressFormat,
    this.unitType,
  });

  factory PropertyUnit.fromJson(Map<String, dynamic> json) =>
      _$PropertyUnitFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyUnitToJson(this);
}

@JsonSerializable()
class Technician {
  @JsonKey(name: 'assignment_id')
  final String? assignmentId;
  
  final String? uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? photo;
  
  @JsonKey(name: 'assigned_at')
  final String? assignedAt;
  
  final String? status;
  
  @JsonKey(name: 'is_current')
  final bool? isCurrent;

  Technician({
    this.assignmentId,
    this.uid,
    this.name,
    this.email,
    this.phone,
    this.photo,
    this.assignedAt,
    this.status,
    this.isCurrent,
  });

  factory Technician.fromJson(Map<String, dynamic> json) =>
      _$TechnicianFromJson(json);
  Map<String, dynamic> toJson() => _$TechnicianToJson(this);
}

@JsonSerializable()
class TechnicianImages {
  @JsonKey(name: 'tenant_uploads', defaultValue: [])
  final List<String> tenantUploads;
  
  @JsonKey(name: 'admin_uploads', defaultValue: [])
  final List<String> adminUploads;
  
  @JsonKey(name: 'technician_uploads', defaultValue: [])
  final List<String> technicianUploads;

  @JsonKey(defaultValue: [])
  final List<String> images;

  TechnicianImages({
    this.tenantUploads = const [],
    this.adminUploads = const [],
    this.technicianUploads = const [],
    this.images = const [],
  });

  List<String> get allImages => [
    ...images,
    ...tenantUploads,
    ...adminUploads,
    ...technicianUploads,
  ];

  factory TechnicianImages.fromJson(Map<String, dynamic> json) =>
      _$TechnicianImagesFromJson(json);
  Map<String, dynamic> toJson() => _$TechnicianImagesToJson(this);
}

@JsonSerializable()
class AdminInfo {
  @JsonKey(name: 'added_by_admin')
  final bool? addedByAdmin;
  
  @JsonKey(name: 'last_updated_by_admin')
  final String? lastUpdatedByAdmin;
  
  @JsonKey(name: 'reply_by_admin')
  final String? replyByAdmin;
  
  @JsonKey(name: 'admin_uploaded_images_count')
  final int? adminUploadedImagesCount;
  
  @JsonKey(name: 'admin_technician_images_count')
  final int? adminTechnicianImagesCount;

  AdminInfo({
    this.addedByAdmin,
    this.lastUpdatedByAdmin,
    this.replyByAdmin,
    this.adminUploadedImagesCount,
    this.adminTechnicianImagesCount,
  });

  factory AdminInfo.fromJson(Map<String, dynamic> json) =>
      _$AdminInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AdminInfoToJson(this);
}