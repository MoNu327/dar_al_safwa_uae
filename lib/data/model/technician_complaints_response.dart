import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

part 'technician_complaints_response.g.dart';

@JsonSerializable()
class TechnicianComplaintsResponse {
  @JsonKey(fromJson: _statusFromJson)
  final bool? status;

  final List<ComplaintData>? data;

  TechnicianComplaintsResponse({
    this.status,
    this.data,
  });

  factory TechnicianComplaintsResponse.fromJson(Map<String, dynamic> json) =>
      _$TechnicianComplaintsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TechnicianComplaintsResponseToJson(this);

  static bool _statusFromJson(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true' || value == '1';
    if (value is int) return value == 1;
    return false;
  }
}

@JsonSerializable()
class ComplaintData {
  @JsonKey(name: 'complaint_id')
  final String? complaintId;

  @JsonKey(name: 'complaint_number')
  final String? complaintNumber;

  final String? description;
  final String? reply;

  @JsonKey(name: 'last_updated')
  final String? date;

  final String? status;

  @JsonKey(name: 'status_text')
  final StatusText? statusText;

  final String? category;
  final String? subcategory;

  @JsonKey(name: 'property_name')
  final String? propertyName;

  @JsonKey(name: 'unit_number')
  final String? unitNumber;

  @JsonKey(name: 'full_address')
  final String? fullAddress;

  @JsonKey(name: 'flatno_id')
  final String? flatnoId;

  @JsonKey(defaultValue: [])
  final List<String>? images;

  ComplaintData({
    this.complaintId,
    this.complaintNumber,
    this.description,
    this.reply,
    this.date,
    this.status,
    this.statusText,
    this.category,
    this.subcategory,
    this.propertyName,
    this.unitNumber,
    this.fullAddress,
    this.flatnoId,
    this.images,
  });

  factory ComplaintData.fromJson(Map<String, dynamic> json) =>
      _$ComplaintDataFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintDataToJson(this);

  // Getter for formatted date
  String get formattedDate {
    if (date == null) return 'No date';
    try {
      return DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(date!));
    } catch (e) {
      return date!; // Return original if parsing fails
    }
  }

  // Getter for display status (handles "In Progres" typo)
  String get displayStatus {
    final status = statusText?.en?.toLowerCase() ?? '';
    if (status == 'in progres') return 'In Progress';
    return statusText?.en ?? status ?? 'Unknown';
  }

  // Getter for status color
  Color get statusColor {
    switch (displayStatus.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rectified':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}

@JsonSerializable()
class StatusText {
  final String? en;

  StatusText({this.en});

  factory StatusText.fromJson(Map<String, dynamic> json) =>
      _$StatusTextFromJson(json);

  Map<String, dynamic> toJson() => _$StatusTextToJson(this);
}