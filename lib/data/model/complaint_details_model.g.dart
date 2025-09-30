// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'complaint_details_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComplaintDetailsModel _$ComplaintDetailsModelFromJson(
        Map<String, dynamic> json) =>
    ComplaintDetailsModel(
      success: json['success'] as bool,
      message: json['message'] == null
          ? null
          : Message.fromJson(json['message'] as Map<String, dynamic>),
      data: ComplaintData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ComplaintDetailsModelToJson(
        ComplaintDetailsModel instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message?.toJson(),
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
      complaint: Complaint.fromJson(json['complaint'] as Map<String, dynamic>),
      property: Property.fromJson(json['property'] as Map<String, dynamic>),
      payments: (json['payments'] as List<dynamic>?)
          ?.map((e) => Payment.fromJson(e as Map<String, dynamic>))
          .toList(),
      images: (json['images'] as List<dynamic>?)
          ?.map((e) => ComplaintImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List<dynamic>?)
          ?.map((e) => TimelineEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ComplaintDataToJson(ComplaintData instance) =>
    <String, dynamic>{
      'complaint': instance.complaint.toJson(),
      'property': instance.property.toJson(),
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'images': instance.images.map((e) => e.toJson()).toList(),
      'timeline': instance.timeline.map((e) => e.toJson()).toList(),
    };

Complaint _$ComplaintFromJson(Map<String, dynamic> json) => Complaint(
      id: json['id'] as String,
      complaintNumber: json['complaint_number'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );

Map<String, dynamic> _$ComplaintToJson(Complaint instance) => <String, dynamic>{
      'id': instance.id,
      'complaint_number': instance.complaintNumber,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'description': instance.description,
      'status': instance.status,
      'created_at': instance.createdAt,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      id: json['id'] as String,
      title: json['title'] as String,
      unit: Unit.fromJson(json['unit'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'unit': instance.unit,
    };

Unit _$UnitFromJson(Map<String, dynamic> json) => Unit(
      number: json['number'] as String,
      addressFormat: json['address_format'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$UnitToJson(Unit instance) => <String, dynamic>{
      'number': instance.number,
      'address_format': instance.addressFormat,
      'type': instance.type,
    };

Payment _$PaymentFromJson(Map<String, dynamic> json) => Payment(
      timestamp: json['timestamp'] as String,
      amount: json['amount'] as String,
      status: json['status'] as String,
      method: json['method'] as String,
    );

Map<String, dynamic> _$PaymentToJson(Payment instance) => <String, dynamic>{
      'timestamp': instance.timestamp,
      'amount': instance.amount,
      'status': instance.status,
      'method': instance.method,
    };

ComplaintImage _$ComplaintImageFromJson(Map<String, dynamic> json) =>
    ComplaintImage(
      imagePath: json['image_path'] as String,
      timestamp: json['timestamp'] as String,
    );

Map<String, dynamic> _$ComplaintImageToJson(ComplaintImage instance) =>
    <String, dynamic>{
      'image_path': instance.imagePath,
      'timestamp': instance.timestamp,
    };

TimelineEvent _$TimelineEventFromJson(Map<String, dynamic> json) =>
    TimelineEvent(
      type: json['type'] as String,
      timestamp: json['timestamp'] as String,
      message: json['message'] as String?,
      oldStatus: json['oldStatus'] as String?,
      newStatus: json['newStatus'] as String?,
      by: json['by'] as Map<String, dynamic>?,
      technician: json['technician'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TimelineEventToJson(TimelineEvent instance) =>
    <String, dynamic>{
      'type': instance.type,
      'timestamp': instance.timestamp,
      'message': instance.message,
      'oldStatus': instance.oldStatus,
      'newStatus': instance.newStatus,
      'by': instance.by,
      'technician': instance.technician,
    };
