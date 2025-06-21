import 'package:json_annotation/json_annotation.dart';

part 'agent_properties_response_model.g.dart';

@JsonSerializable()
class AgentPropertyResponse {
  @JsonKey(name: 'success')
  final bool? success;

  @JsonKey(name: 'message')
  final LocalizedMessage? message;

  @JsonKey(name: 'location_id')
  final String? locationId;

  @JsonKey(name: 'agent_uid')
  final String? agentUid;

  @JsonKey(name: 'properties')
  final List<AgentProperty>? properties;

  @JsonKey(name: 'count')
  final int? count;

  AgentPropertyResponse({
    this.success,
    this.message,
    this.locationId,
    this.agentUid,
    this.properties,
    this.count,
  });

  factory AgentPropertyResponse.fromJson(Map<String, dynamic> json) =>
      _$AgentPropertyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AgentPropertyResponseToJson(this);
}

@JsonSerializable()
class AgentProperty {
  @JsonKey(name: 'property_id')
  final String? propertyId;

  @JsonKey(name: 'address')
  final LocalizedText? address;

  @JsonKey(name: 'image')
  final String? image;

  @JsonKey(name: 'title')
  final String? title;

  @JsonKey(name: 'price')
  final AgentPropertyPrice? price;

  @JsonKey(name: 'status')
  final LocalizedText? status;

  @JsonKey(name: 'assigned_date')
  final String? assignedDate;

  AgentProperty({
    this.propertyId,
    this.address,
    this.price,
    this.status,
    this.assignedDate,
    this.image,
    this.title,
  });

  factory AgentProperty.fromJson(Map<String, dynamic> json) =>
      _$AgentPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$AgentPropertyToJson(this);
}

@JsonSerializable()
class AgentPropertyPrice {
  @JsonKey(name: 'raw')
  final String? raw;

  @JsonKey(name: 'formatted')
  final LocalizedText? formatted;

  AgentPropertyPrice({
    this.raw,
    this.formatted,
  });

  factory AgentPropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$AgentPropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$AgentPropertyPriceToJson(this);
}

@JsonSerializable()
class LocalizedText {
  @JsonKey(name: 'en')
  final String? en;

  @JsonKey(name: 'ar')
  final String? ar;

  LocalizedText({
    this.en,
    this.ar,
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);
}

@JsonSerializable()
class LocalizedMessage {
  @JsonKey(name: 'en')
  final String? en;

  @JsonKey(name: 'ar')
  final String? ar;

  LocalizedMessage({
    this.en,
    this.ar,
  });

  factory LocalizedMessage.fromJson(Map<String, dynamic> json) =>
      _$LocalizedMessageFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedMessageToJson(this);
}
