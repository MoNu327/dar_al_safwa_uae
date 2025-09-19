// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_chat_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentChatResponse _$AgentChatResponseFromJson(Map<String, dynamic> json) =>
    AgentChatResponse(
      success: json['success'] as bool,
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
      data: ChatData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AgentChatResponseToJson(AgentChatResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message.toJson(),
      'data': instance.data.toJson(),
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

ChatData _$ChatDataFromJson(Map<String, dynamic> json) => ChatData(
      interests: (json['interests'] as List<dynamic>?)
          ?.map((e) => Interest.fromJson(e as Map<String, dynamic>))
          .toList(),
      propertyCounts: (json['property_counts'] as List<dynamic>?)
          ?.map((e) => PropertyCount.fromJson(e as Map<String, dynamic>))
          .toList(),
      unrepliedCount: (json['unreplied_count'] as num?)?.toInt() ?? 0,
      agentDetails: json['agent_details'] == null
          ? null
          : AgentDetails.fromJson(
              json['agent_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatDataToJson(ChatData instance) => <String, dynamic>{
      'interests': instance.interests?.map((e) => e.toJson()).toList(),
      'property_counts':
          instance.propertyCounts?.map((e) => e.toJson()).toList(),
      'unreplied_count': instance.unrepliedCount,
      'agent_details': instance.agentDetails?.toJson(),
    };

Interest _$InterestFromJson(Map<String, dynamic> json) => Interest(
      id: json['id'] as String,
      firebaseChatId: json['firebase_chat_id'] as String?,
      agentId: json['agent_id'] as String?,
      userId: json['user_id'] as String?,
      propertyId: json['property_id'] as String?,
      unitId: json['unit_id'] as String?,
      unitTitle: json['unit_title'] as String?,
      propertyTitle: json['property_title'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] as String?,
      userName: json['user_name'] as String?,
      userPhoto: json['user_photo'] as String?,
      agentName: json['agent_name'] as String?,
      agentPhoto: json['agent_photo'] as String?,
      status: json['status'] as String?,
      firebaseCreatedAt: json['firebase_created_at'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      propstatus: json['propstatus'] as String?,
      unreplied: json['unreplied'] as bool,
    );

Map<String, dynamic> _$InterestToJson(Interest instance) => <String, dynamic>{
      'id': instance.id,
      'firebase_chat_id': instance.firebaseChatId,
      'agent_id': instance.agentId,
      'user_id': instance.userId,
      'property_id': instance.propertyId,
      'unit_id': instance.unitId,
      'unit_title': instance.unitTitle,
      'property_title': instance.propertyTitle,
      'last_message': instance.lastMessage,
      'last_message_at': instance.lastMessageAt,
      'user_name': instance.userName,
      'user_photo': instance.userPhoto,
      'agent_name': instance.agentName,
      'agent_photo': instance.agentPhoto,
      'status': instance.status,
      'firebase_created_at': instance.firebaseCreatedAt,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'propstatus': instance.propstatus,
      'unreplied': instance.unreplied,
    };

PropertyCount _$PropertyCountFromJson(Map<String, dynamic> json) =>
    PropertyCount(
      propertyId: json['property_id'] as String?,
      propertyTitle: json['property_title'] as String?,
      count: json['count'] as String? ?? '0',
      soldCount: json['sold_count'] as String? ?? '0',
    );

Map<String, dynamic> _$PropertyCountToJson(PropertyCount instance) =>
    <String, dynamic>{
      'property_id': instance.propertyId,
      'property_title': instance.propertyTitle,
      'count': instance.count,
      'sold_count': instance.soldCount,
    };

AgentDetails _$AgentDetailsFromJson(Map<String, dynamic> json) => AgentDetails(
      agentId: json['agent_id'] as String?,
      agentName: json['agent_name'] as String?,
    );

Map<String, dynamic> _$AgentDetailsToJson(AgentDetails instance) =>
    <String, dynamic>{
      'agent_id': instance.agentId,
      'agent_name': instance.agentName,
    };
