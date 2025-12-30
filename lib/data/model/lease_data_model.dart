import 'package:json_annotation/json_annotation.dart';
import 'payment_group_model.dart';

part 'lease_data_model.g.dart';

@JsonSerializable()
class LeaseDataModel {
  @JsonKey(fromJson: _toStringOrNull)
  final String? id;
  
  final String? email;
  final String? mobile;
  final String? confirmation_uid;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? bookingid;
  
  final String? rent_amount;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? payment_plan_id;
  
  final String? start_date;
  final String? end_date;
  final String? security_deposit_amount;
  final String? security_deposit_due_date;
  final String? govt_fees_amount;
  final String? additional_fees_amount;
  final String? additional_fees_description;
  final String? notes;
  final String? confirmation_status;
  final String? created_at;
  final String? updated_at;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? leaseversion;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? rental_duration;
  
  final String? payable_rent_amount;
  final String? rent_type;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? include_security_in_total;
  
  final String? created_at_formatted;
  final String? updated_at_formatted;
  final String? property_title;
  final String? unit_type_title;
  final String? unit_title;
  final PaymentGroupModel? payment_groups;

  LeaseDataModel({
    this.id,
    this.email,
    this.mobile,
    this.confirmation_uid,
    this.bookingid,
    this.rent_amount,
    this.payment_plan_id,
    this.start_date,
    this.end_date,
    this.security_deposit_amount,
    this.security_deposit_due_date,
    this.govt_fees_amount,
    this.additional_fees_amount,
    this.additional_fees_description,
    this.notes,
    this.confirmation_status,
    this.created_at,
    this.updated_at,
    this.leaseversion,
    this.rental_duration,
    this.payable_rent_amount,
    this.rent_type,
    this.include_security_in_total,
    this.created_at_formatted,
    this.updated_at_formatted,
    this.property_title,
    this.unit_type_title,
    this.unit_title,
    this.payment_groups,
  });

  // Helper function to convert any value to String or null
  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  factory LeaseDataModel.fromJson(Map<String, dynamic> json) =>
      _$LeaseDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$LeaseDataModelToJson(this);
}