import 'package:json_annotation/json_annotation.dart';
part 'tenant_compliant_model.g.dart';
@JsonSerializable()
class ComplaintCategoriesResponse {
  final bool? status; // nullable
  final String message;
  final List<ComplaintCategory>? data; // nullable

  ComplaintCategoriesResponse({
    this.status, // no required keyword
    required this.message,
    this.data, // no required keyword
  });

  factory ComplaintCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCategoriesResponseToJson(this);
}

@JsonSerializable()
class ComplaintCategory {
  final int id;
  final String name;
  final int? flag; // nullable

  ComplaintCategory({
    required this.id,
    required this.name,
    this.flag, // no required keyword
  });

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCategoryToJson(this);
}