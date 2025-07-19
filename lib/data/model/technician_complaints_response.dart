import 'package:json_annotation/json_annotation.dart';

part 'technician_complaints_response.g.dart';

@JsonSerializable()
class TechnicianComplaintsResponse {
  final bool status;
  final List<ComplaintData> data;

  TechnicianComplaintsResponse({
    required this.status,
    required this.data,
  });

  factory TechnicianComplaintsResponse.fromJson(Map<String, dynamic> json) =>
      _$TechnicianComplaintsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianComplaintsResponseToJson(this);
}

@JsonSerializable()
class ComplaintData {
  @JsonKey(name: 'complaint_id')
  final String complaintId;

  @JsonKey(name: 'complaint_number')
  final String complaintNumber;

  final String description;
  final String? reply;
  final String date;
  final String status;

  @JsonKey(name: 'status_text')
  final StatusText statusText;

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

  ComplaintData({
    required this.complaintId,
    required this.complaintNumber,
    required this.description,
    this.reply,
    required this.date,
    required this.status,
    required this.statusText,
    required this.category,
    required this.subcategory,
    required this.propertyName,
    required this.unitNumber,
    required this.fullAddress,
    required this.flatnoId,
    required this.images,
  });

  factory ComplaintData.fromJson(Map<String, dynamic> json) =>
      _$ComplaintDataFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintDataToJson(this);
}

@JsonSerializable()
class StatusText {
  final String en;

  StatusText({required this.en});

  factory StatusText.fromJson(Map<String, dynamic> json) =>
      _$StatusTextFromJson(json);

  Map<String, dynamic> toJson() => _$StatusTextToJson(this);
}
