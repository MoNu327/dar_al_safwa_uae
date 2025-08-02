// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_categories_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintCategoriesResponse _$ComplaintCategoriesResponseFromJson(
        Map<String, dynamic> json) =>
    ComplaintCategoriesResponse(
      status: json['status'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => ComplaintCategory.fromJson(e as Map<String, dynamic>))
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
      id: _stringToInt(json['id']),
      name: json['name'] as String,
      flag: _stringToInt(json['flag']),
    );

Map<String, dynamic> _$ComplaintCategoryToJson(ComplaintCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'flag': instance.flag,
    };
