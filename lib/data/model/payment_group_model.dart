import 'package:json_annotation/json_annotation.dart';
import 'payments_installments_model.dart';

part 'payment_group_model.g.dart';

@JsonSerializable()
class PaymentGroupModel {
  @JsonKey(defaultValue: [])
  final List<PaymentInstallmentModel> cash;
  
  @JsonKey(defaultValue: [])
  final List<PaymentInstallmentModel> cheque;
  
  @JsonKey(defaultValue: [])
  final List<PaymentInstallmentModel> bank;
  
  @JsonKey(defaultValue: [])
  final List<PaymentInstallmentModel> other;

  PaymentGroupModel({
    required this.cash,
    required this.cheque,
    required this.bank,
    required this.other,
  });

  factory PaymentGroupModel.fromJson(Map<String, dynamic> json) {
    // Manual parsing with null safety
    return PaymentGroupModel(
      cash: _parseInstallmentList(json['cash']),
      cheque: _parseInstallmentList(json['cheque']),
      bank: _parseInstallmentList(json['bank']),
      other: _parseInstallmentList(json['other']),
    );
  }

  static List<PaymentInstallmentModel> _parseInstallmentList(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    
    return data
        .where((item) => item != null)
        .map((item) => PaymentInstallmentModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() => _$PaymentGroupModelToJson(this);
}