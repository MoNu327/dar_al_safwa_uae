// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintDetailsModel _$ComplaintDetailsModelFromJson(
        Map<String, dynamic> json) =>
    ComplaintDetailsModel(
      success: json['success'] as bool,
      message: Message.fromJson(json['message'] as Map<String, dynamic>),
      data: ComplaintData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComplaintDetailsModelToJson(
        ComplaintDetailsModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message.toJson(),
      'data': instance.data.toJson(),
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      en: json['en'] as String,
      ar: json['ar'] as String,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

ComplaintData _$ComplaintDataFromJson(Map<String, dynamic> json) =>
    ComplaintData(
      complaintId: json['complaint_id'] as String,
      complaintNumber: json['complaint_number'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      description: json['description'] as String,
      reply: json['reply'] as String,
      amountPaid: json['amount_paid'] as String,
      amountPaidStatus: json['amount_paid_status'] as String,
      status: Status.fromJson(json['status'] as Map<String, dynamic>),
      lastUpdated: json['last_updated'] as String,
      property: Property.fromJson(json['property'] as Map<String, dynamic>),
      images: ComplaintImages.fromJson(json['images'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComplaintDataToJson(ComplaintData instance) =>
    <String, dynamic>{
      'complaint_id': instance.complaintId,
      'complaint_number': instance.complaintNumber,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'description': instance.description,
      'reply': instance.reply,
      'amount_paid': instance.amountPaid,
      'amount_paid_status': instance.amountPaidStatus,
      'status': instance.status.toJson(),
      'last_updated': instance.lastUpdated,
      'property': instance.property.toJson(),
      'images': instance.images.toJson(),
    };

Status _$StatusFromJson(Map<String, dynamic> json) => Status(
      en: json['en'] as String,
    );

Map<String, dynamic> _$StatusToJson(Status instance) => <String, dynamic>{
      'en': instance.en,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      title: json['title'] as String,
      unitNumber: json['unit_number'] as String,
      addressFormat: json['address_format'] as String,
      unitType: json['unit_type'] as String,
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'title': instance.title,
      'unit_number': instance.unitNumber,
      'address_format': instance.addressFormat,
      'unit_type': instance.unitType,
    };

ComplaintImages _$ComplaintImagesFromJson(Map<String, dynamic> json) =>
    ComplaintImages(
      tenantImages: (json['tenant_images'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      technicianImages: (json['technician_images'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ComplaintImagesToJson(ComplaintImages instance) =>
    <String, dynamic>{
      'tenant_images': instance.tenantImages,
      'technician_images': instance.technicianImages,
    };
