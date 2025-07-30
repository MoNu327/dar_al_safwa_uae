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
  final Complaint? complaint;
  final Property? property;
  final ComplaintImages? images;
  final AdminInfo? adminInfo;

  ComplaintResponseData({
    this.complaint,
    this.property,
    this.images,
    this.adminInfo,
  });

  factory ComplaintResponseData.fromJson(Map<String, dynamic> json) =>
      _$ComplaintResponseDataFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintResponseDataToJson(this);
}

@JsonSerializable()
class Complaint {
  // Accepts either "complaint_id" (list shape) or "id" (single-complaint shape)
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

  // API list shape provides numeric "status", text is under "status_text.en"
  @JsonKey(name: 'status', fromJson: _statusCodeFromJson)
final int? statusCode;


  // Keep your Status { en } model, but map it from "status_text"
  @JsonKey(name: 'status_text')
  final Status? status;

  // Accepts either "created_at" (single) or "date" (list)
  @JsonKey(readValue: _readCreatedAt)
  final String? createdAt;

  @JsonKey(name: 'last_updated')
  final String? lastUpdated;

  @JsonKey(name: 'last_updated_by_admin')
  final String? lastUpdatedByAdmin;

  @JsonKey(name: 'added_by_admin')
  final bool? addedByAdmin;

  // Extra fields present only in the list response (safe to keep optional)
  @JsonKey(name: 'property_name')
  final String? propertyName;

  @JsonKey(name: 'unit_number')
  final String? unitNumber;

  @JsonKey(name: 'full_address')
  final String? fullAddress;

  @JsonKey(name: 'flatno_id')
  final String? flatnoId;

  Complaint({
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

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintToJson(this);

  // --- helpers for readValue ---

  static Object? _readComplaintId(Map json, String _) {
    final v = json['complaint_id'] ?? json['id'];
    return v?.toString();
    // handles int ids as well
  }
  static int? _statusCodeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}


  static Object? _readCreatedAt(Map json, String _) {
    // prefer created_at if present; otherwise fall back to date
    return json['created_at'] ?? json['date'];
  }

  // Your existing getters can remain the same:
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
class ComplaintImages {
  @JsonKey(name: 'tenant_uploads', defaultValue: [])
  final List<String>? tenantUploads;
  
  @JsonKey(name: 'admin_uploads', defaultValue: [])
  final List<String>? adminUploads;
  
  @JsonKey(name: 'technician_uploads', defaultValue: [])
  final List<String>? technicianUploads;

  ComplaintImages({
    this.tenantUploads,
    this.adminUploads,
    this.technicianUploads,
  });

  factory ComplaintImages.fromJson(Map<String, dynamic> json) =>
      _$ComplaintImagesFromJson(json);
  Map<String, dynamic> toJson() => _$ComplaintImagesToJson(this);
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