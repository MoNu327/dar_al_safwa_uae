import 'package:json_annotation/json_annotation.dart';

part 'agent_chat_response.g.dart';

@JsonSerializable(explicitToJson: true)
class AgentChatResponse {
  final bool success;
  final Message message;
  final ChatData data;

  AgentChatResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AgentChatResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentChatResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AgentChatResponseToJson(this);
}

@JsonSerializable()
class Message {
  final String? en; // ✅ made nullable
  final String? ar; // ✅ made nullable

  Message({
    this.en,
    this.ar,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatData {
  final List<Interest>? interests; // ✅ nullable list
  @JsonKey(name: 'property_counts')
  final List<PropertyCount>? propertyCounts; // ✅ nullable list
  @JsonKey(name: 'unreplied_count', defaultValue: 0)
  final int unrepliedCount;
  @JsonKey(name: 'agent_details')
  final AgentDetails? agentDetails; // ✅ nullable

  ChatData({
    this.interests,
    this.propertyCounts,
    required this.unrepliedCount,
    this.agentDetails,
  });

  factory ChatData.fromJson(Map<String, dynamic> json) =>
      _$ChatDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChatDataToJson(this);
}

@JsonSerializable()
class Interest {
  final String id;
  @JsonKey(name: 'firebase_chat_id')
  final String? firebaseChatId;
  @JsonKey(name: 'agent_id')
  final String? agentId;
  @JsonKey(name: 'user_id')
  final String? userId;
  @JsonKey(name: 'property_id')
  final String? propertyId;
  @JsonKey(name: 'unit_id')
  final String? unitId;
  @JsonKey(name: 'unit_title')
  final String? unitTitle;
  @JsonKey(name: 'property_title')
  final String? propertyTitle;
  @JsonKey(name: 'last_message')
  final String? lastMessage;
  @JsonKey(name: 'last_message_at')
  final String? lastMessageAt;
  @JsonKey(name: 'user_name')
  final String? userName;
  @JsonKey(name: 'user_photo')
  final String? userPhoto;
  @JsonKey(name: 'agent_name')
  final String? agentName;
  @JsonKey(name: 'agent_photo')
  final String? agentPhoto;
  final String? status;
  @JsonKey(name: 'firebase_created_at')
  final String? firebaseCreatedAt;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  final String? propstatus;
  final bool unreplied;

  Interest({
    required this.id,
    this.firebaseChatId,
    this.agentId,
    this.userId,
    this.propertyId,
    this.unitId,
    this.unitTitle,
    this.propertyTitle,
    this.lastMessage,
    this.lastMessageAt,
    this.userName,
    this.userPhoto,
    this.agentName,
    this.agentPhoto,
    this.status,
    this.firebaseCreatedAt,
    this.createdAt,
    this.updatedAt,
    this.propstatus,
    required this.unreplied,
  });

  factory Interest.fromJson(Map<String, dynamic> json) =>
      _$InterestFromJson(json);

  Map<String, dynamic> toJson() => _$InterestToJson(this);
}

@JsonSerializable()
class PropertyCount {
  @JsonKey(name: 'property_id')
  final String? propertyId;
  @JsonKey(name: 'property_title')
  final String? propertyTitle;

  @JsonKey(defaultValue: "0")
  final String count;

  @JsonKey(name: 'sold_count', defaultValue: "0")
  final String soldCount;

  PropertyCount({
    this.propertyId,
    this.propertyTitle,
    required this.count,
    required this.soldCount,
  });

  factory PropertyCount.fromJson(Map<String, dynamic> json) =>
      _$PropertyCountFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyCountToJson(this);
}

@JsonSerializable()
class AgentDetails {
  @JsonKey(name: 'agent_id')
  final String? agentId;
  @JsonKey(name: 'agent_name')
  final String? agentName;

  AgentDetails({
    this.agentId,
    this.agentName,
  });

  factory AgentDetails.fromJson(Map<String, dynamic> json) =>
      _$AgentDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$AgentDetailsToJson(this);
}
