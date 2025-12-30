// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PaymentGroupModel _$PaymentGroupModelFromJson(Map<String, dynamic> json) =>
    PaymentGroupModel(
      cash: (json['cash'] as List<dynamic>?)
              ?.map((e) =>
                  PaymentInstallmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cheque: (json['cheque'] as List<dynamic>?)
              ?.map((e) =>
                  PaymentInstallmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bank: (json['bank'] as List<dynamic>?)
              ?.map((e) =>
                  PaymentInstallmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      other: (json['other'] as List<dynamic>?)
              ?.map((e) =>
                  PaymentInstallmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$PaymentGroupModelToJson(PaymentGroupModel instance) =>
    <String, dynamic>{
      'cash': instance.cash,
      'cheque': instance.cheque,
      'bank': instance.bank,
      'other': instance.other,
    };
