import 'package:json_annotation/json_annotation.dart';

part 'popular_properties_model.g.dart';

@JsonSerializable()
class PopularPropertiesResponse {
  final bool success;
  final PopularPropertiesMessage message;
  final List<PopularProperty> data;

  PopularPropertiesResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory PopularPropertiesResponse.fromJson(Map<String, dynamic> json) =>
      _$PopularPropertiesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PopularPropertiesResponseToJson(this);
}

@JsonSerializable()
class PopularPropertiesMessage {
  final String en;
  final String ar;

  PopularPropertiesMessage({
    required this.en,
    required this.ar,
  });

  factory PopularPropertiesMessage.fromJson(Map<String, dynamic> json) =>
      _$PopularPropertiesMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PopularPropertiesMessageToJson(this);
}

@JsonSerializable()
class PopularProperty {
  final int id;
  @JsonKey(name: 'property_title')
  final LocalizedText propertyTitle;
  @JsonKey(name: 'property_image')
  final String propertyImage;
  @JsonKey(name: 'property_deal')
  final LocalizedText propertyDeal;
  @JsonKey(name: 'property_price')
  final PropertyPrice propertyPrice;
  @JsonKey(name: 'property_type')
  final LocalizedText propertyType;
  @JsonKey(name: 'property_address')
  final LocalizedText propertyAddress;
  @JsonKey(name: 'property_location')
  final LocalizedText propertyLocation;
  @JsonKey(name: 'property_bed')
  final int propertyBed;
  @JsonKey(name: 'property_bath')
  final int propertyBath;
  @JsonKey(name: 'property_sqft')
  final LocalizedText propertySqft;

  PopularProperty({
    required this.id,
    required this.propertyTitle,
    required this.propertyImage,
    required this.propertyDeal,
    required this.propertyPrice,
    required this.propertyType,
    required this.propertyAddress,
    required this.propertyLocation,
    required this.propertyBed,
    required this.propertyBath,
    required this.propertySqft,
  });

  factory PopularProperty.fromJson(Map<String, dynamic> json) =>
      _$PopularPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PopularPropertyToJson(this);
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

@JsonSerializable()
class PropertyPrice {
  final double raw;
  final LocalizedText formatted;

  PropertyPrice({
    required this.raw,
    required this.formatted,
  });

  factory PropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$PropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyPriceToJson(this);
}
