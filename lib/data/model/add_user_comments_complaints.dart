import 'package:json_annotation/json_annotation.dart';

part 'add_user_comments_complaints.g.dart';

@JsonSerializable()
class ComplaintResponse {
  final bool success;
  final Message? message;
  final ComplaintData? data;

  ComplaintResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory ComplaintResponse.fromJson(Map<String, dynamic> json) =>
      _$ComplaintResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintResponseToJson(this);
}

@JsonSerializable()
class Message {
  final String? en;
  final String? ar;

  Message({this.en, this.ar});

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class ComplaintData {
  final Complaint? complaint;
  final List<Conversation>? conversation;

  @JsonKey(name: "comment_posted")
  final bool? commentPosted;

  @JsonKey(name: "total_comments")
  final int? totalComments;

  @JsonKey(name: "current_user")
  final CurrentUser? currentUser;

  ComplaintData({
    this.complaint,
    this.conversation,
    this.commentPosted,
    this.totalComments,
    this.currentUser,
  });

  factory ComplaintData.fromJson(Map<String, dynamic> json) =>
      _$ComplaintDataFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintDataToJson(this);
}

@JsonSerializable()
class Complaint {
  final String? id;
  @JsonKey(name: "complaint_number")
  final String? complaintNumber;
  final String? category;
  final String? subcategory;
  final String? description;
  @JsonKey(name: "property_name")
  final String? propertyName;
  @JsonKey(name: "unit_number")
  final String? unitNumber;
  @JsonKey(name: "full_address")
  final String? fullAddress;
  final Status? status;
  @JsonKey(name: "created_at")
  final String? createdAt;
  @JsonKey(name: "original_images")
  final List<String>? originalImages;
  @JsonKey(name: "technician_reply")
  final String? technicianReply;
  @JsonKey(name: "admin_reply")
  final String? adminReply;
  @JsonKey(name: "technician_images")
  final List<String>? technicianImages;

  Complaint({
    this.id,
    this.complaintNumber,
    this.category,
    this.subcategory,
    this.description,
    this.propertyName,
    this.unitNumber,
    this.fullAddress,
    this.status,
    this.createdAt,
    this.originalImages,
    this.technicianReply,
    this.adminReply,
    this.technicianImages,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) =>
      _$ComplaintFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintToJson(this);
}

@JsonSerializable()
class Status {
  final String? en;

  Status({this.en});

  factory Status.fromJson(Map<String, dynamic> json) =>
      _$StatusFromJson(json);

  Map<String, dynamic> toJson() => _$StatusToJson(this);
}

@JsonSerializable()
class Conversation {
  final String? timestamp;
  final String? role;
  final String? name;
  final String? message;
  final String? type;

  Conversation({
    this.timestamp,
    this.role,
    this.name,
    this.message,
    this.type,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}

@JsonSerializable()
class CurrentUser {
  final String? uid;
  final String? role;
  final String? name;

  @JsonKey(name: "is_tenant")
  final bool? isTenant;

  @JsonKey(name: "is_technician")
  final bool? isTechnician;

  CurrentUser({
    this.uid,
    this.role,
    this.name,
    this.isTenant,
    this.isTechnician,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) =>
      _$CurrentUserFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentUserToJson(this);
}
