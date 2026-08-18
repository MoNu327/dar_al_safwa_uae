import 'package:json_annotation/json_annotation.dart';

part 'complaint_details_model.g.dart';

/// Safely converts a JSON value (int, double, String, or null) to a String.
/// The backend sometimes returns numeric ids/amounts as ints instead of Strings.
String _stringFromJson(dynamic value) => value?.toString() ?? '';

@JsonSerializable(explicitToJson: true)
class ComplaintDetailsModel {
  final bool success;
  final Message? message;
  final ComplaintData data;

  ComplaintDetailsModel({
    required this.success,
    this.message,
    required this.data,
  });

  factory ComplaintDetailsModel.fromJson(Map<String, dynamic> json) =>
      _$ComplaintDetailsModelFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintDetailsModelToJson(this);
}

@JsonSerializable()
class Message {
  final String en;
  final String ar;

  Message({required this.en, required this.ar});

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ComplaintData {
  final Complaint complaint;
  final Property property;
  final List<Payment> payments;
  final List<ComplaintImage> images;

  @JsonKey(name: "user_comments_history")
  final List<UserCommentHistory> userCommentsHistory;

  final List<TimelineEvent> timeline;

  ComplaintData({
    required this.complaint,
    required this.property,
    List<Payment>? payments,
    List<ComplaintImage>? images,
    List<UserCommentHistory>? userCommentsHistory,
    List<TimelineEvent>? timeline,
  })  : payments = payments ?? [],
        images = images ?? [],
        userCommentsHistory = userCommentsHistory ?? [],
        timeline = timeline ?? [];

  factory ComplaintData.fromJson(Map<String, dynamic> json) =>
      _$ComplaintDataFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintDataToJson(this);
}

@JsonSerializable(explicitToJson: true)
class Complaint {
  @JsonKey(fromJson: _stringFromJson)
  final String id;

  @JsonKey(name: 'complaint_number', fromJson: _stringFromJson)
  final String complaintNumber;

  final String category;
  final String subcategory;
  final String description;
  final String status;

  @JsonKey(name: 'created_at')
  final String createdAt;

  @JsonKey(name: 'created_by')
  final UserBy? createdBy;

  Complaint({
    required this.id,
    required this.complaintNumber,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.status,
    required this.createdAt,
    this.createdBy,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintToJson(this);
}

@JsonSerializable()
class Property {
  @JsonKey(fromJson: _stringFromJson)
  final String id;
  final String title;
  final Unit unit;

  Property({
    required this.id,
    required this.title,
    required this.unit,
  });

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

@JsonSerializable()
class Unit {
  @JsonKey(fromJson: _stringFromJson)
  final String number;

  @JsonKey(name: 'address_format', fromJson: _stringFromJson)
  final String addressFormat;

  @JsonKey(fromJson: _stringFromJson)
  final String type;

  Unit({
    required this.number,
    required this.addressFormat,
    required this.type,
  });

  factory Unit.fromJson(Map<String, dynamic> json) =>
      _$UnitFromJson(json);

  Map<String, dynamic> toJson() => _$UnitToJson(this);
}

@JsonSerializable()
class Payment {
  final String timestamp;

  @JsonKey(fromJson: _stringFromJson)
  final String amount;
  final String status;
  final String method;

  Payment({
    required this.timestamp,
    required this.amount,
    required this.status,
    required this.method,
  });

  factory Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentToJson(this);
}

@JsonSerializable()
class ComplaintImage {
  @JsonKey(name: 'image_path')
  final String imagePath;
  final String timestamp;
  final String? type;
  final UserBy? by;

  ComplaintImage({
    required this.imagePath,
    required this.timestamp,
    this.type,
    this.by,
  });

  factory ComplaintImage.fromJson(Map<String, dynamic> json) =>
      _$ComplaintImageFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintImageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class UserCommentHistory {
  final String timestamp;
  final String message;
  final String type;
  final UserBy by;

  UserCommentHistory({
    required this.timestamp,
    required this.message,
    required this.type,
    required this.by,
  });

  factory UserCommentHistory.fromJson(Map<String, dynamic> json) =>
      _$UserCommentHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$UserCommentHistoryToJson(this);
}

// ✅ FIXED: Make critical fields nullable to prevent crashes
@JsonSerializable()
class UserBy {
  final String? type;   // ← changed to nullable
  final String? uid;    // ← changed to nullable
  final String? name;   // ← changed to nullable
  final String? email;
  final String? phone;
  final String? photo;
  final String? role;

  UserBy({
    this.type,
    this.uid,
    this.name,
    this.email,
    this.phone,
    this.photo,
    this.role,
  });

  factory UserBy.fromJson(Map<String, dynamic> json) =>
      _$UserByFromJson(json);

  Map<String, dynamic> toJson() => _$UserByToJson(this);

  // Optional helper for UI
  String get getDisplayName => (name?.trim().isNotEmpty == true) ? name! : 'Unknown';
  
  String getTypeDisplay() {
    if (type == null) return 'Unknown';
    switch (type!.toLowerCase()) {
      case 'tenant': return 'Tenant';
      case 'technician': return 'Technician';
      case 'admin': return 'Admin';
      default: return type!;
    }
  }
}

@JsonSerializable(explicitToJson: true)
class TimelineEvent {
  final String type;
  final String timestamp;
  final String? message;

  @JsonKey(name: 'old_status')
  final String? oldStatus;

  @JsonKey(name: 'new_status')
  final String? newStatus;

  final UserBy? by;
  final UserBy? technician;

  TimelineEvent({
    required this.type,
    required this.timestamp,
    this.message,
    this.oldStatus,
    this.newStatus,
    this.by,
    this.technician,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) =>
      _$TimelineEventFromJson(json);

  Map<String, dynamic> toJson() => _$TimelineEventToJson(this);
}