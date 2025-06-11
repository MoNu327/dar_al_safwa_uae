// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_dropdown_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationDropdownResponse _$LocationDropdownResponseFromJson(
        Map<String, dynamic> json) =>
    LocationDropdownResponse(
      success: json['success'] as bool?,
      message: json['message'] == null
          ? null
          : Message.fromJson(json['message'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map(
              (e) => LocationDropdownModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LocationDropdownResponseToJson(
        LocationDropdownResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

LocationDropdownModel _$LocationDropdownModelFromJson(
        Map<String, dynamic> json) =>
    LocationDropdownModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] == null
          ? null
          : Message.fromJson(json['name'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LocationDropdownModelToJson(
        LocationDropdownModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };
