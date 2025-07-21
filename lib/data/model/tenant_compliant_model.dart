import 'package:json_annotation/json_annotation.dart';
part 'tenant_compliant_model.g.dart';

@JsonSerializable()
class ComplaintCategoriesResponse {
  final bool? status;
  final String message;
  final List<ComplaintCategory>? data;

  ComplaintCategoriesResponse({
    this.status,
    required this.message,
    this.data,
  });

  factory ComplaintCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCategoriesResponseToJson(this);
}

@JsonSerializable()
class ComplaintCategory {
  @JsonKey(fromJson: _toInt)
  final int id;

  final String name;

  @JsonKey(fromJson: _toIntNullable)
  final int? flag;

  ComplaintCategory({
    required this.id,
    required this.name,
    this.flag,
  });

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCategoryToJson(this);

  /// Converts both String and int to int
  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Converts String or null to int?
  static int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    return _toInt(value);
  }
}
