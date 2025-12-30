// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lease_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaseResponseModel _$LeaseResponseModelFromJson(Map<String, dynamic> json) =>
    LeaseResponseModel(
      success: json['success'] as bool,
      message: json['message'] == null
          ? null
          : MessageModel.fromJson(json['message'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => LeaseDataModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$LeaseResponseModelToJson(LeaseResponseModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };
