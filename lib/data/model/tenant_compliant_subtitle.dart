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
  final int id;
  final String name;
  final int complaint_master_id;
  final int status;
  final int? flag;
  final String complaint_master_name;

  ComplaintSubCategory({
    required this.id,
    required this.name,
    required this.complaint_master_id,
    required this.status,
    this.flag,
    required this.complaint_master_name,
  });

  factory ComplaintSubCategory.fromJson(Map<String, dynamic> json) =>
      _$ComplaintSubCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintSubCategoryToJson(this);
}
