// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'agreement_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AgreementResponse _$AgreementResponseFromJson(Map<String, dynamic> json) =>
    AgreementResponse(
      success: json['success'] as bool,
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>)
          .map((e) => AgreementData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AgreementResponseToJson(AgreementResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message.toJson(),
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      en: json['en'] as String,
      ar: json['ar'] as String,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

AgreementData _$AgreementDataFromJson(Map<String, dynamic> json) =>
    AgreementData(
      id: json['id'] as String,
      uid: json['uid'] as String,
      property_id: json['property_id'] as String,
      unit_id: json['unit_id'] as String,
      unit_address_id: json['unit_address_id'] as String,
      notification_title: json['notification_title'] as String,
      notification_body: json['notification_body'] as String,
      created_at: json['created_at'] as String,
      updated_at: json['updated_at'] as String,
      property_title: json['property_title'] as String,
      unit_type_title: json['unit_type_title'] as String,
      unit_number: json['unit_number'] as String,
      created_at_formatted: json['created_at_formatted'] as String,
      updated_at_formatted: json['updated_at_formatted'] as String,
      user_display_name: json['user_display_name'] as String,
    );

Map<String, dynamic> _$AgreementDataToJson(AgreementData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'uid': instance.uid,
      'property_id': instance.property_id,
      'unit_id': instance.unit_id,
      'unit_address_id': instance.unit_address_id,
      'notification_title': instance.notification_title,
      'notification_body': instance.notification_body,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'property_title': instance.property_title,
      'unit_type_title': instance.unit_type_title,
      'unit_number': instance.unit_number,
      'created_at_formatted': instance.created_at_formatted,
      'updated_at_formatted': instance.updated_at_formatted,
      'user_display_name': instance.user_display_name,
    };
