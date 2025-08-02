import 'package:json_annotation/json_annotation.dart';

part 'location_dropdown_model.g.dart';

@JsonSerializable()
class LocationDropdownResponse {
  final bool? success;
  final Message? message;
  final List<LocationDropdownModel>? data;

  LocationDropdownResponse({
    this.success,
    this.message,
    this.data,
  });

  factory LocationDropdownResponse.fromJson(Map<String, dynamic> json) =>
      _$LocationDropdownResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LocationDropdownResponseToJson(this);
}

@JsonSerializable()
class Message {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  Message({this.english, this.arabic});

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  String getText(String languageCode) {
    return languageCode == 'ar'
        ? (arabic ?? english ?? '')
        : (english ?? arabic ?? '');
  }
}

@JsonSerializable()
class LocationDropdownModel {
  final int? id;
  final Message? name;

  LocationDropdownModel({this.id, this.name});

  factory LocationDropdownModel.fromJson(Map<String, dynamic> json) =>
      _$LocationDropdownModelFromJson(json);

  Map<String, dynamic> toJson() => _$LocationDropdownModelToJson(this);

  String get nameEn => name?.english ?? '';
  String get nameAr => name?.arabic ?? '';

  String getName(String languageCode) {
    return name?.getText(languageCode) ?? '';
  }
}
