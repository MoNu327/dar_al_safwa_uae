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

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class AgreementData {
  final String id;
  final String uid;
  final String property_id;
  final String unit_address_id;
  final String from_date;
  final String to_date;
  final String pdf_path;
  final String status;
  final String created_at;
  final String updated_at;
  final String property_title;
  final String unit_number;
  final String created_at_formatted;
  final String updated_at_formatted;
  final String pdf_url;
  final String user_display_name;

  AgreementData({
    required this.id,
    required this.uid,
    required this.property_id,
    required this.unit_address_id,
    required this.from_date,
    required this.to_date,
    required this.pdf_path,
    required this.status,
    required this.created_at,
    required this.updated_at,
    required this.property_title,
    required this.unit_number,
    required this.created_at_formatted,
    required this.updated_at_formatted,
    required this.pdf_url,
    required this.user_display_name,
  });

  factory AgreementData.fromJson(Map<String, dynamic> json) =>
      _$AgreementDataFromJson(json);
  Map<String, dynamic> toJson() => _$AgreementDataToJson(this);
}
