import 'package:json_annotation/json_annotation.dart';

part 'complaint_categories_model.g.dart';

/// Converts dynamic (String/int) to int safely
int _stringToInt(dynamic value) => int.tryParse(value.toString()) ?? 0;

@JsonSerializable()
class ComplaintCategoriesResponse {
  final bool status;
  final String message;
  final List<ComplaintCategory> data;

  ComplaintCategoriesResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ComplaintCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCategoriesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCategoriesResponseToJson(this);
}

@JsonSerializable()
class ComplaintCategory {
  @JsonKey(fromJson: _stringToInt)
  final int id;

  final String name;

  @JsonKey(fromJson: _stringToInt)
  final int flag;

  ComplaintCategory({
    required this.id,
    required this.name,
    required this.flag,
  });

  factory ComplaintCategory.fromJson(Map<String, dynamic> json) =>
      _$ComplaintCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$ComplaintCategoryToJson(this);
}
