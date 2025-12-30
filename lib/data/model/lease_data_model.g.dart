// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lease_data_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LeaseDataModel _$LeaseDataModelFromJson(Map<String, dynamic> json) =>
    LeaseDataModel(
      id: LeaseDataModel._toStringOrNull(json['id']),
      email: json['email'] as String?,
      mobile: json['mobile'] as String?,
      confirmation_uid: json['confirmation_uid'] as String?,
      bookingid: LeaseDataModel._toStringOrNull(json['bookingid']),
      rent_amount: json['rent_amount'] as String?,
      payment_plan_id: LeaseDataModel._toStringOrNull(json['payment_plan_id']),
      start_date: json['start_date'] as String?,
      end_date: json['end_date'] as String?,
      security_deposit_amount: json['security_deposit_amount'] as String?,
      security_deposit_due_date: json['security_deposit_due_date'] as String?,
      govt_fees_amount: json['govt_fees_amount'] as String?,
      additional_fees_amount: json['additional_fees_amount'] as String?,
      additional_fees_description:
          json['additional_fees_description'] as String?,
      notes: json['notes'] as String?,
      confirmation_status: json['confirmation_status'] as String?,
      created_at: json['created_at'] as String?,
      updated_at: json['updated_at'] as String?,
      leaseversion: LeaseDataModel._toStringOrNull(json['leaseversion']),
      rental_duration: LeaseDataModel._toStringOrNull(json['rental_duration']),
      payable_rent_amount: json['payable_rent_amount'] as String?,
      rent_type: json['rent_type'] as String?,
      include_security_in_total:
          LeaseDataModel._toStringOrNull(json['include_security_in_total']),
      created_at_formatted: json['created_at_formatted'] as String?,
      updated_at_formatted: json['updated_at_formatted'] as String?,
      property_title: json['property_title'] as String?,
      unit_type_title: json['unit_type_title'] as String?,
      unit_title: json['unit_title'] as String?,
      payment_groups: json['payment_groups'] == null
          ? null
          : PaymentGroupModel.fromJson(
              json['payment_groups'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LeaseDataModelToJson(LeaseDataModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'mobile': instance.mobile,
      'confirmation_uid': instance.confirmation_uid,
      'bookingid': instance.bookingid,
      'rent_amount': instance.rent_amount,
      'payment_plan_id': instance.payment_plan_id,
      'start_date': instance.start_date,
      'end_date': instance.end_date,
      'security_deposit_amount': instance.security_deposit_amount,
      'security_deposit_due_date': instance.security_deposit_due_date,
      'govt_fees_amount': instance.govt_fees_amount,
      'additional_fees_amount': instance.additional_fees_amount,
      'additional_fees_description': instance.additional_fees_description,
      'notes': instance.notes,
      'confirmation_status': instance.confirmation_status,
      'created_at': instance.created_at,
      'updated_at': instance.updated_at,
      'leaseversion': instance.leaseversion,
      'rental_duration': instance.rental_duration,
      'payable_rent_amount': instance.payable_rent_amount,
      'rent_type': instance.rent_type,
      'include_security_in_total': instance.include_security_in_total,
      'created_at_formatted': instance.created_at_formatted,
      'updated_at_formatted': instance.updated_at_formatted,
      'property_title': instance.property_title,
      'unit_type_title': instance.unit_type_title,
      'unit_title': instance.unit_title,
      'payment_groups': instance.payment_groups,
    };
