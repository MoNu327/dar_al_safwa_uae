// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_complaint_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateComplaintRequest _$UpdateComplaintRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateComplaintRequest(
      complaintId: (json['complaint_id'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      reply: json['reply'] as String,
      amountPaid: (json['amount_paid'] as num).toInt(),
      amountStatus: (json['amount_status'] as num).toInt(),
      images:
          (json['images'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$UpdateComplaintRequestToJson(
        UpdateComplaintRequest instance) =>
    <String, dynamic>{
      'complaint_id': instance.complaintId,
      'status': instance.status,
      'reply': instance.reply,
      'amount_paid': instance.amountPaid,
      'amount_status': instance.amountStatus,
      'images': instance.images,
    };
