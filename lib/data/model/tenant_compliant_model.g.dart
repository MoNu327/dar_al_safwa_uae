// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_compliant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintCategoriesResponse _$ComplaintCategoriesResponseFromJson(
        Map<String, dynamic> json) =>
    ComplaintCategoriesResponse(
      status: json['status'] as bool?,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ComplaintCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ComplaintCategoriesResponseToJson(
        ComplaintCategoriesResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

ComplaintCategory _$ComplaintCategoryFromJson(Map<String, dynamic> json) =>
    ComplaintCategory(
      id: ComplaintCategory._toInt(json['id']),
      name: json['name'] as String,
      flag: ComplaintCategory._toIntNullable(json['flag']),
    );

Map<String, dynamic> _$ComplaintCategoryToJson(ComplaintCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'flag': instance.flag,
    };
