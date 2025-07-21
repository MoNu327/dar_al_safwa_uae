// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_complaints_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianComplaintsResponse _$TechnicianComplaintsResponseFromJson(
        Map<String, dynamic> json) =>
    TechnicianComplaintsResponse(
      status: TechnicianComplaintsResponse._statusFromJson(json['status']),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => ComplaintData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TechnicianComplaintsResponseToJson(
        TechnicianComplaintsResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'data': instance.data,
    };

ComplaintData _$ComplaintDataFromJson(Map<String, dynamic> json) =>
    ComplaintData(
      complaintId: json['complaint_id'] as String?,
      complaintNumber: json['complaint_number'] as String?,
      description: json['description'] as String?,
      reply: json['reply'] as String?,
      date: json['last_updated'] as String?,
      status: json['status'] as String?,
      statusText: json['status_text'] == null
          ? null
          : StatusText.fromJson(json['status_text'] as Map<String, dynamic>),
      category: json['category'] as String?,
      subcategory: json['subcategory'] as String?,
      propertyName: json['property_name'] as String?,
      unitNumber: json['unit_number'] as String?,
      fullAddress: json['full_address'] as String?,
      flatnoId: json['flatno_id'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$ComplaintDataToJson(ComplaintData instance) =>
    <String, dynamic>{
      'complaint_id': instance.complaintId,
      'complaint_number': instance.complaintNumber,
      'description': instance.description,
      'reply': instance.reply,
      'last_updated': instance.date,
      'status': instance.status,
      'status_text': instance.statusText,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'property_name': instance.propertyName,
      'unit_number': instance.unitNumber,
      'full_address': instance.fullAddress,
      'flatno_id': instance.flatnoId,
      'images': instance.images,
    };

StatusText _$StatusTextFromJson(Map<String, dynamic> json) => StatusText(
      en: json['en'] as String?,
    );

Map<String, dynamic> _$StatusTextToJson(StatusText instance) =>
    <String, dynamic>{
      'en': instance.en,
    };
