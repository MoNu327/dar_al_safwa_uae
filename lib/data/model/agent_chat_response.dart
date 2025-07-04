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
  final String en;
  final String ar;

  Message({
    required this.en,
    required this.ar,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ChatData {
  final List<Interest> interests;
  @JsonKey(name: 'property_counts')
  final List<PropertyCount> propertyCounts;
  @JsonKey(name: 'unreplied_count')
  final int unrepliedCount;
  @JsonKey(name: 'agent_details')
  final AgentDetails agentDetails;

  ChatData({
    required this.interests,
    required this.propertyCounts,
    required this.unrepliedCount,
    required this.agentDetails,
  });

  factory ChatData.fromJson(Map<String, dynamic> json) =>
      _$ChatDataFromJson(json);

  Map<String, dynamic> toJson() => _$ChatDataToJson(this);
}

@JsonSerializable()
class Interest {
  final String id;
  @JsonKey(name: 'firebase_chat_id')
  final String firebaseChatId;
  @JsonKey(name: 'agent_id')
  final String agentId;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'property_id')
  final String propertyId;
  @JsonKey(name: 'unit_id')
  final String unitId;
  @JsonKey(name: 'unit_title')
  final String unitTitle;
  @JsonKey(name: 'property_title')
  final String propertyTitle;
  @JsonKey(name: 'last_message')
  final String lastMessage;
  @JsonKey(name: 'last_message_at')
  final String lastMessageAt;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'user_photo')
  final String? userPhoto;
  @JsonKey(name: 'agent_name')
  final String agentName;
  @JsonKey(name: 'agent_photo')
  final String? agentPhoto;
  final String status;
  @JsonKey(name: 'firebase_created_at')
  final String firebaseCreatedAt;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final String? propstatus;
  final bool unreplied;

  Interest({
    required this.id,
    required this.firebaseChatId,
    required this.agentId,
    required this.userId,
    required this.propertyId,
    required this.unitId,
    required this.unitTitle,
    required this.propertyTitle,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.userName,
    required this.userPhoto,
    required this.agentName,
    required this.agentPhoto,
    required this.status,
    required this.firebaseCreatedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.propstatus,
    required this.unreplied,
  });

  factory Interest.fromJson(Map<String, dynamic> json) =>
      _$InterestFromJson(json);

  Map<String, dynamic> toJson() => _$InterestToJson(this);
}

@JsonSerializable()
class PropertyCount {
  @JsonKey(name: 'property_id')
  final String propertyId;
  @JsonKey(name: 'property_title')
  final String propertyTitle;
  final String count;
  @JsonKey(name: 'sold_count')
  final String soldCount;

  PropertyCount({
    required this.propertyId,
    required this.propertyTitle,
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
  final String agentId;
  @JsonKey(name: 'agent_name')
  final String agentName;

  AgentDetails({
    required this.agentId,
    required this.agentName,
  });

  factory AgentDetails.fromJson(Map<String, dynamic> json) =>
      _$AgentDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$AgentDetailsToJson(this);
}
