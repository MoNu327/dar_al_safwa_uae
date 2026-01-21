// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'add_user_comments_complaints.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintResponse _$ComplaintResponseFromJson(Map<String, dynamic> json) =>
    ComplaintResponse(
      success: json['success'] as bool,
      message: json['message'] == null
          ? null
          : Message.fromJson(json['message'] as Map<String, dynamic>),
      data: json['data'] == null
          ? null
          : ComplaintData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComplaintResponseToJson(ComplaintResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

ComplaintData _$ComplaintDataFromJson(Map<String, dynamic> json) =>
    ComplaintData(
      complaint: json['complaint'] == null
          ? null
          : Complaint.fromJson(json['complaint'] as Map<String, dynamic>),
      conversation: (json['conversation'] as List<dynamic>?)
          ?.map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList(),
      commentPosted: json['comment_posted'] as bool?,
      totalComments: (json['total_comments'] as num?)?.toInt(),
      currentUser: json['current_user'] == null
          ? null
          : CurrentUser.fromJson(json['current_user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComplaintDataToJson(ComplaintData instance) =>
    <String, dynamic>{
      'complaint': instance.complaint,
      'conversation': instance.conversation,
      'comment_posted': instance.commentPosted,
      'total_comments': instance.totalComments,
      'current_user': instance.currentUser,
    };

Complaint _$ComplaintFromJson(Map<String, dynamic> json) => Complaint(
      id: json['id'] as String?,
      complaintNumber: json['complaint_number'] as String?,
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      description: json['description'] as String?,
      propertyName: json['property_name'] as String?,
      unitNumber: json['unit_number'] as String?,
      fullAddress: json['full_address'] as String?,
      status: json['status'] == null
          ? null
          : Status.fromJson(json['status'] as Map<String, dynamic>),
      createdAt: json['created_at'] as String?,
      originalImages: (json['original_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      technicianReply: json['technician_reply'] as String?,
      adminReply: json['admin_reply'] as String?,
      technicianImages: (json['technician_images'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ComplaintToJson(Complaint instance) => <String, dynamic>{
      'id': instance.id,
      'complaint_number': instance.complaintNumber,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'description': instance.description,
      'property_name': instance.propertyName,
      'unit_number': instance.unitNumber,
      'full_address': instance.fullAddress,
      'status': instance.status,
      'created_at': instance.createdAt,
      'original_images': instance.originalImages,
      'technician_reply': instance.technicianReply,
      'admin_reply': instance.adminReply,
      'technician_images': instance.technicianImages,
    };

Status _$StatusFromJson(Map<String, dynamic> json) => Status(
      en: json['en'] as String?,
    );

Map<String, dynamic> _$StatusToJson(Status instance) => <String, dynamic>{
      'en': instance.en,
    };

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      timestamp: json['timestamp'] as String?,
      role: json['role'] as String?,
      name: json['name'] as String?,
      message: json['message'] as String?,
      type: json['type'] as String?,
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'role': instance.role,
      'name': instance.name,
      'message': instance.message,
      'type': instance.type,
    };

CurrentUser _$CurrentUserFromJson(Map<String, dynamic> json) => CurrentUser(
      uid: json['uid'] as String?,
      role: json['role'] as String?,
      name: json['name'] as String?,
      isTenant: json['is_tenant'] as bool?,
      isTechnician: json['is_technician'] as bool?,
    );

Map<String, dynamic> _$CurrentUserToJson(CurrentUser instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'role': instance.role,
      'name': instance.name,
      'is_tenant': instance.isTenant,
      'is_technician': instance.isTechnician,
    };
