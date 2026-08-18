import 'package:json_annotation/json_annotation.dart';

part 'payments_installments_model.g.dart';

@JsonSerializable()
class PaymentInstallmentModel {
  @JsonKey(fromJson: _toStringOrNull)
  final String? id;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? segment_id;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? installment_number;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? amount;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? received_amount;
  
  final String? payment_status;
  final String? expected_date;
  final String? actual_payment_date;

  @JsonKey(fromJson: _toStringOrNull)
  final String? cheque_number;
  final String? cheque_date;
  final String? cheque_bank_name;
  final String? cheque_image;

  @JsonKey(fromJson: _toStringOrNull)
  final String? transaction_reference;
  final String? transfer_bank_name;
  final String? transfer_date;
  final String? transfer_proof;

  @JsonKey(fromJson: _toStringOrNull)
  final String? receipt_number;
  final String? cash_payment_date;
  final String? receipt_image;
  final String? payment_description;

  @JsonKey(fromJson: _toStringOrNull)
  final String? payment_reference;
  final String? payment_image;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? docstatus;
  
  final String? payment_notes;
  final String? otherpaymentdate;
  
  @JsonKey(fromJson: _toStringOrNull)
  final String? installment_created_at;
  
  final String? installment_updated_at;
  
  @JsonKey(fromJson: _toBoolOrFalse)
  final bool upcoming;

  PaymentInstallmentModel({
    this.id,
    this.segment_id,
    this.installment_number,
    this.amount,
    this.received_amount,
    this.payment_status,
    this.expected_date,
    this.actual_payment_date,
    this.cheque_number,
    this.cheque_date,
    this.cheque_bank_name,
    this.cheque_image,
    this.transaction_reference,
    this.transfer_bank_name,
    this.transfer_date,
    this.transfer_proof,
    this.receipt_number,
    this.cash_payment_date,
    this.receipt_image,
    this.payment_description,
    this.payment_reference,
    this.payment_image,
    this.docstatus,
    this.payment_notes,
    this.otherpaymentdate,
    this.installment_created_at,
    this.installment_updated_at,
    this.upcoming = false,
  });

  // Helper function to convert any value to String or null
  static String? _toStringOrNull(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  // Helper function to convert any value to bool
  static bool _toBoolOrFalse(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
    }
    return false;
  }

  factory PaymentInstallmentModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentInstallmentModelFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentInstallmentModelToJson(this);
}