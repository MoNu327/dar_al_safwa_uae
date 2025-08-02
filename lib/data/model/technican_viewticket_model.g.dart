// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technican_viewticket_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ViewTicketResponse _$ViewTicketResponseFromJson(Map<String, dynamic> json) =>
    ViewTicketResponse(
      status: json['status'] as bool,
      data: (json['data'] as List<dynamic>)
          .map((e) => ViewTicketData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ViewTicketResponseToJson(ViewTicketResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'data': instance.data.map((e) => e.toJson()).toList(),
    };

ViewTicketData _$ViewTicketDataFromJson(Map<String, dynamic> json) =>
    ViewTicketData(
      complaintId: json['complaint_id'] as String,
      complaintNumber: json['complaint_number'] as String,
      description: json['description'] as String,
      reply: json['reply'] as String?,
      date: json['date'] as String,
      status: json['status'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      propertyName: json['property_name'] as String,
      unitNumber: json['unit_number'] as String,
      fullAddress: json['full_address'] as String,
      flatnoId: json['flatno_id'] as String,
      images:
          (json['images'] as List<dynamic>).map((e) => e as String).toList(),
      statusText: ViewTicketData._statusTextFromJson(
          json['status_text'] as Map<String, dynamic>?),
    );

Map<String, dynamic> _$ViewTicketDataToJson(ViewTicketData instance) =>
    <String, dynamic>{
      'complaint_id': instance.complaintId,
      'complaint_number': instance.complaintNumber,
      'description': instance.description,
      'reply': instance.reply,
      'date': instance.date,
      'status': instance.status,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'property_name': instance.propertyName,
      'unit_number': instance.unitNumber,
      'full_address': instance.fullAddress,
      'flatno_id': instance.flatnoId,
      'images': instance.images,
      'status_text': ViewTicketData._statusTextToJson(instance.statusText),
    };
