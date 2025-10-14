import 'package:json_annotation/json_annotation.dart';

part 'search_dropdown_model.g.dart';

@JsonSerializable()
class SearchDropdownResponse {
  final bool success;
  final SearchDropdownMessage? message;
  final SearchDropdownData? data;

  SearchDropdownResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory SearchDropdownResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchDropdownResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchDropdownResponseToJson(this);
}

@JsonSerializable()
class SearchDropdownMessage {
  final String? en;
  final String? ar;

  SearchDropdownMessage({
    this.en,
    this.ar,
  });

  factory SearchDropdownMessage.fromJson(Map<String, dynamic> json) =>
      _$SearchDropdownMessageFromJson(json);

  Map<String, dynamic> toJson() => _$SearchDropdownMessageToJson(this);
}

@JsonSerializable()
class SearchDropdownData {
  @JsonKey(name: 'property_option', defaultValue: [])
  final List<PropertyOption> propertyOptions;

  @JsonKey(name: 'property_types', defaultValue: [])
  final List<PropertyType> propertyTypes;

  @JsonKey(name: 'property_locations', defaultValue: [])
  final List<PropertyLocation> propertyLocations;

  @JsonKey(name: 'property_beds_bath', defaultValue: [])
  final List<PropertyBedsBath> propertyBedsBaths;

  @JsonKey(name: 'price_range', defaultValue: [])
  final List<PropertyRangePrice> propertyPrices;

  SearchDropdownData({
    required this.propertyOptions,
    required this.propertyTypes,
    required this.propertyLocations,
    required this.propertyBedsBaths,
    required this.propertyPrices,
  });

  factory SearchDropdownData.fromJson(Map<String, dynamic> json) =>
      _$SearchDropdownDataFromJson(json);

  Map<String, dynamic> toJson() => _$SearchDropdownDataToJson(this);
}

@JsonSerializable()
class PropertyOption {
  final int id;
  final LocalizedText name;

  PropertyOption({
    required this.id,
    required this.name,
  });

  factory PropertyOption.fromJson(Map<String, dynamic> json) =>
      _$PropertyOptionFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyOptionToJson(this);
}

@JsonSerializable()
class PropertyType {
  final int id;
  final LocalizedText name;

  PropertyType({
    required this.id,
    required this.name,
  });

  factory PropertyType.fromJson(Map<String, dynamic> json) =>
      _$PropertyTypeFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyTypeToJson(this);
}

@JsonSerializable()
class PropertyRangePrice {
  final int id;
  final LocalizedText name;

  PropertyRangePrice({
    required this.id,
    required this.name,
  });

  factory PropertyRangePrice.fromJson(Map<String, dynamic> json) =>
      _$PropertyRangePriceFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyRangePriceToJson(this);
}

@JsonSerializable()
class PropertyLocation {
  final int id;
  final LocalizedText name;

  PropertyLocation({
    required this.id,
    required this.name,
  });

  factory PropertyLocation.fromJson(Map<String, dynamic> json) =>
      _$PropertyLocationFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyLocationToJson(this);
}

@JsonSerializable()
class PropertyBedsBath {
  final int id;
  final LocalizedText name;

  PropertyBedsBath({
    required this.id,
    required this.name,
  });

  factory PropertyBedsBath.fromJson(Map<String, dynamic> json) =>
      _$PropertyBedsBathFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyBedsBathToJson(this);
}

@JsonSerializable()
class LocalizedText {
  final String en;
  final String ar;

  LocalizedText({
    required this.en,
    required this.ar,
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);
}