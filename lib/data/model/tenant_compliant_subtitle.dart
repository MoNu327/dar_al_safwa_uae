import 'package:json_annotation/json_annotation.dart';

part 'tenant_compliant_subtitle.g.dart';

class ComplaintSubCategoriesRequest {
  final int complaintId;
  ComplaintSubCategoriesRequest({
    required this.complaintId,
  });
  Map<String, dynamic> toJson() {
    return {
      'complaint_master_id': complaintId,
    };
  }
}

@JsonSerializable()
class ComplaintSubCategoriesResponse {
  final bool? status;
  final String message;
  final List<ComplaintSubCategory>? data;

  ComplaintSubCategoriesResponse({
    this.status,
    required this.message,
    this.data,
  });

  factory ComplaintSubCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$ComplaintSubCategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintSubCategoriesResponseToJson(this);
}

@JsonSerializable()
class ComplaintSubCategory {
  @JsonKey(fromJson: _toInt)
  final int id;

  final String name;

  @JsonKey(name: 'complaint_master_id', fromJson: _toInt)
  final int complaintMasterId;

  @JsonKey(fromJson: _toInt)
  final int status;

  @JsonKey(fromJson: _toIntNullable)
  final int? flag;

  @JsonKey(name: 'complaint_master_name')
  final String complaintMasterName;

  ComplaintSubCategory({
    required this.id,
    required this.name,
    required this.complaintMasterId,
    required this.status,
    this.flag,
    required this.complaintMasterName,
  });

  factory ComplaintSubCategory.fromJson(Map<String, dynamic> json) =>
      _$ComplaintSubCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintSubCategoryToJson(this);

  /// --- Utility functions for safe conversion ---
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    return _toInt(value);
  }
}
