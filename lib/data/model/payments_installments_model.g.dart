// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payments_installments_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentInstallmentModel _$PaymentInstallmentModelFromJson(
        Map<String, dynamic> json) =>
    PaymentInstallmentModel(
      id: PaymentInstallmentModel._toStringOrNull(json['id']),
      segment_id: PaymentInstallmentModel._toStringOrNull(json['segment_id']),
      installment_number:
          PaymentInstallmentModel._toStringOrNull(json['installment_number']),
      amount: PaymentInstallmentModel._toStringOrNull(json['amount']),
      received_amount:
          PaymentInstallmentModel._toStringOrNull(json['received_amount']),
      payment_status: json['payment_status'] as String?,
      expected_date: json['expected_date'] as String?,
      actual_payment_date: json['actual_payment_date'] as String?,
      cheque_number: json['cheque_number'] as String?,
      cheque_date: json['cheque_date'] as String?,
      cheque_bank_name: json['cheque_bank_name'] as String?,
      cheque_image: json['cheque_image'] as String?,
      transaction_reference: json['transaction_reference'] as String?,
      transfer_bank_name: json['transfer_bank_name'] as String?,
      transfer_date: json['transfer_date'] as String?,
      transfer_proof: json['transfer_proof'] as String?,
      receipt_number: json['receipt_number'] as String?,
      cash_payment_date: json['cash_payment_date'] as String?,
      receipt_image: json['receipt_image'] as String?,
      payment_description: json['payment_description'] as String?,
      payment_reference: json['payment_reference'] as String?,
      payment_image: json['payment_image'] as String?,
      docstatus: PaymentInstallmentModel._toStringOrNull(json['docstatus']),
      payment_notes: json['payment_notes'] as String?,
      otherpaymentdate: json['otherpaymentdate'] as String?,
      installment_created_at: PaymentInstallmentModel._toStringOrNull(
          json['installment_created_at']),
      installment_updated_at: json['installment_updated_at'] as String?,
      upcoming: json['upcoming'] == null
          ? false
          : PaymentInstallmentModel._toBoolOrFalse(json['upcoming']),
    );

Map<String, dynamic> _$PaymentInstallmentModelToJson(
        PaymentInstallmentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'segment_id': instance.segment_id,
      'installment_number': instance.installment_number,
      'amount': instance.amount,
      'received_amount': instance.received_amount,
      'payment_status': instance.payment_status,
      'expected_date': instance.expected_date,
      'actual_payment_date': instance.actual_payment_date,
      'cheque_number': instance.cheque_number,
      'cheque_date': instance.cheque_date,
      'cheque_bank_name': instance.cheque_bank_name,
      'cheque_image': instance.cheque_image,
      'transaction_reference': instance.transaction_reference,
      'transfer_bank_name': instance.transfer_bank_name,
      'transfer_date': instance.transfer_date,
      'transfer_proof': instance.transfer_proof,
      'receipt_number': instance.receipt_number,
      'cash_payment_date': instance.cash_payment_date,
      'receipt_image': instance.receipt_image,
      'payment_description': instance.payment_description,
      'payment_reference': instance.payment_reference,
      'payment_image': instance.payment_image,
      'docstatus': instance.docstatus,
      'payment_notes': instance.payment_notes,
      'otherpaymentdate': instance.otherpaymentdate,
      'installment_created_at': instance.installment_created_at,
      'installment_updated_at': instance.installment_updated_at,
      'upcoming': instance.upcoming,
    };
