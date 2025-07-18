import 'package:json_annotation/json_annotation.dart';
part 'technican_viewticket_model.g.dart';


@JsonSerializable(explicitToJson: true)
class ViewTicketResponse {
  final bool status;
  final List<ViewTicketData> data;

  ViewTicketResponse({
    required this.status,
    required this.data,
  });

  factory ViewTicketResponse.fromJson(Map<String, dynamic> json) =>
      _$ViewTicketResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ViewTicketResponseToJson(this);
}

@JsonSerializable()
class ViewTicketData {
  @JsonKey(name: 'complaint_id')
  final String complaintId;

  @JsonKey(name: 'complaint_number')
  final String complaintNumber;

  final String description;
  final String? reply;
  final String date;
  final String status;
  final String category;
  final String subcategory;

  @JsonKey(name: 'property_name')
  final String propertyName;

  @JsonKey(name: 'unit_number')
  final String unitNumber;

  @JsonKey(name: 'full_address')
  final String fullAddress;

  @JsonKey(name: 'flatno_id')
  final String flatnoId;

  final List<String> images;

  @JsonKey(
      name: 'status_text',
      fromJson: _statusTextFromJson,
      toJson: _statusTextToJson)
  final String statusText;

  ViewTicketData({
    required this.complaintId,
    required this.complaintNumber,
    required this.description,
    this.reply,
    required this.date,
    required this.status,
    required this.category,
    required this.subcategory,
    required this.propertyName,
    required this.unitNumber,
    required this.fullAddress,
    required this.flatnoId,
    required this.images,
    required this.statusText,
  });

  factory ViewTicketData.fromJson(Map<String, dynamic> json) =>
      _$ViewTicketDataFromJson(json);

  Map<String, dynamic> toJson() => _$ViewTicketDataToJson(this);

  /// Custom handling for nested `status_text.en`
  static String _statusTextFromJson(Map<String, dynamic>? json) =>
      json?['en'] ?? '';

  static Map<String, dynamic> _statusTextToJson(String status) =>
      {'en': status};
}
