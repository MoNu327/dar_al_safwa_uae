import 'package:json_annotation/json_annotation.dart';

part 'agreement_response_model.g.dart';

@JsonSerializable(explicitToJson: true)
class AgreementResponse {
  final bool success;
  final Message message;
  final List<AgreementData> data;

  AgreementResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory AgreementResponse.fromJson(Map<String, dynamic> json) =>
      _$AgreementResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AgreementResponseToJson(this);
}

@JsonSerializable()
class Message {
  final String en;
  final String ar;

  Message({required this.en, required this.ar});

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class AgreementData {
  final String id;
  final String uid;
  final String property_id;
  final String unit_id;
  final String unit_address_id;
  final String notification_title;
  final String notification_body;
  final String created_at;
  final String updated_at;
  final String property_title;
  final String unit_type_title;
  final String unit_number;
  final String created_at_formatted;
  final String updated_at_formatted;
  final String user_display_name;

  AgreementData({
    required this.id,
    required this.uid,
    required this.property_id,
    required this.unit_id,
    required this.unit_address_id,
    required this.notification_title,
    required this.notification_body,
    required this.created_at,
    required this.updated_at,
    required this.property_title,
    required this.unit_type_title,
    required this.unit_number,
    required this.created_at_formatted,
    required this.updated_at_formatted,
    required this.user_display_name,
  });

  factory AgreementData.fromJson(Map<String, dynamic> json) =>
      _$AgreementDataFromJson(json);
  Map<String, dynamic> toJson() => _$AgreementDataToJson(this);
}
