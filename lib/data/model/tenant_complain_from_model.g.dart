// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_complain_from_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TenantComplainFromModel _$TenantComplainFromModelFromJson(
        Map<String, dynamic> json) =>
    TenantComplainFromModel(
      complaintMasterId: (json['complaint_master_id'] as num).toInt(),
      complaintSubtitleId: (json['complaint_subtitle_id'] as num).toInt(),
      description: json['description'] as String,
      userId: json['user_id'] as String,
      propertyId: (json['property_id'] as num).toInt(),
      unitAddressId: (json['unit_address_id'] as num).toInt(),
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$TenantComplainFromModelToJson(
        TenantComplainFromModel instance) =>
    <String, dynamic>{
      'complaint_master_id': instance.complaintMasterId,
      'complaint_subtitle_id': instance.complaintSubtitleId,
      'description': instance.description,
      'user_id': instance.userId,
      'property_id': instance.propertyId,
      'unit_address_id': instance.unitAddressId,
      'images': instance.images,
    };
