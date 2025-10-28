// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agent_properties_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgentPropertyResponse _$AgentPropertyResponseFromJson(
        Map<String, dynamic> json) =>
    AgentPropertyResponse(
      success: json['success'] as bool?,
      message: json['message'] == null
          ? null
          : LocalizedMessage.fromJson(json['message'] as Map<String, dynamic>),
      locationId: json['location_id'] as String?,
      agentUid: json['agent_uid'] as String?,
      properties: (json['properties'] as List<dynamic>?)
          ?.map((e) => AgentProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$AgentPropertyResponseToJson(
        AgentPropertyResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'location_id': instance.locationId,
      'agent_uid': instance.agentUid,
      'properties': instance.properties,
      'count': instance.count,
    };

AgentProperty _$AgentPropertyFromJson(Map<String, dynamic> json) =>
    AgentProperty(
      propertyId: json['property_id'] as String?,
      address: json['address'] == null
          ? null
          : LocalizedText.fromJson(json['address'] as Map<String, dynamic>),
      price: json['price'] == null
          ? null
          : AgentPropertyPrice.fromJson(json['price'] as Map<String, dynamic>),
      status: json['status'] == null
          ? null
          : LocalizedText.fromJson(json['status'] as Map<String, dynamic>),
      assignedDate: json['assigned_date'] as String?,
      image: json['image'] as String?,
      title: json['title'] as String?,
    );

Map<String, dynamic> _$AgentPropertyToJson(AgentProperty instance) =>
    <String, dynamic>{
      'property_id': instance.propertyId,
      'address': instance.address,
      'image': instance.image,
      'title': instance.title,
      'price': instance.price,
      'status': instance.status,
      'assigned_date': instance.assignedDate,
    };

AgentPropertyPrice _$AgentPropertyPriceFromJson(Map<String, dynamic> json) =>
    AgentPropertyPrice(
      formatted: json['formatted'] == null
          ? null
          : FormattedPrice.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AgentPropertyPriceToJson(AgentPropertyPrice instance) =>
    <String, dynamic>{
      'formatted': instance.formatted,
    };

FormattedPrice _$FormattedPriceFromJson(Map<String, dynamic> json) =>
    FormattedPrice(
      raw: json['raw'] as String?,
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$FormattedPriceToJson(FormattedPrice instance) =>
    <String, dynamic>{
      'raw': instance.raw,
      'en': instance.en,
      'ar': instance.ar,
    };

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) =>
    LocalizedText(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$LocalizedTextToJson(LocalizedText instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

LocalizedMessage _$LocalizedMessageFromJson(Map<String, dynamic> json) =>
    LocalizedMessage(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$LocalizedMessageToJson(LocalizedMessage instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };
