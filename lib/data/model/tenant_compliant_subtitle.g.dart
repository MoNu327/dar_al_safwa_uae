// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_compliant_subtitle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintSubCategoriesResponse _$ComplaintSubCategoriesResponseFromJson(
        Map<String, dynamic> json) =>
    ComplaintSubCategoriesResponse(
      status: json['status'] as bool?,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ComplaintSubCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ComplaintSubCategoriesResponseToJson(
        ComplaintSubCategoriesResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

ComplaintSubCategory _$ComplaintSubCategoryFromJson(
        Map<String, dynamic> json) =>
    ComplaintSubCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      complaint_master_id: (json['complaint_master_id'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      flag: (json['flag'] as num?)?.toInt(),
      complaint_master_name: json['complaint_master_name'] as String,
    );

Map<String, dynamic> _$ComplaintSubCategoryToJson(
        ComplaintSubCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'complaint_master_id': instance.complaint_master_id,
      'status': instance.status,
      'flag': instance.flag,
      'complaint_master_name': instance.complaint_master_name,
    };
