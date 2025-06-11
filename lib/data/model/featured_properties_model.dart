import 'package:json_annotation/json_annotation.dart';

part 'featured_properties_model.g.dart';

@JsonSerializable()
class FeaturedPropertiesResponse {
  final bool? success;
  final FeaturedPropertiesMessage? message;
  final List<FeaturedProperty>? data;

  FeaturedPropertiesResponse({
    this.success,
    this.message,
    this.data,
  });

  factory FeaturedPropertiesResponse.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertiesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertiesResponseToJson(this);
}

@JsonSerializable()
class FeaturedPropertiesMessage {
  final String? en;
  final String? ar;

  FeaturedPropertiesMessage({
    this.en,
    this.ar,
  });

  factory FeaturedPropertiesMessage.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertiesMessageFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertiesMessageToJson(this);
}

@JsonSerializable()
class FeaturedProperty {
  final int? id;
  @JsonKey(name: 'property_title')
  final LocalizedText? title;
  @JsonKey(name: 'property_image')
  final String? image;
  @JsonKey(name: 'property_deal')
  final LocalizedText? dealType;
  @JsonKey(name: 'property_price')
  final FeaturedPropertyPrice? price;
  @JsonKey(name: 'property_type')
  final LocalizedText? type;
  @JsonKey(name: 'property_address')
  final LocalizedText? address;
  @JsonKey(name: 'property_location')
  final LocalizedText? location;
  @JsonKey(name: 'property_bed')
  final int? bedrooms;
  @JsonKey(name: 'property_bath')
  final int? bathrooms;
  @JsonKey(name: 'property_sqft')
  final LocalizedText? area;

  FeaturedProperty({
    this.id,
    this.title,
    this.image,
    this.dealType,
    this.price,
    this.type,
    this.address,
    this.location,
    this.bedrooms,
    this.bathrooms,
    this.area,
  });

  factory FeaturedProperty.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertyToJson(this);
}

@JsonSerializable()
class LocalizedText {
  final String? en;
  final String? ar;

  LocalizedText({
    this.en,
    this.ar,
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);
}

@JsonSerializable()
class FeaturedPropertyPrice {
  final double? raw;
  final LocalizedText? formatted;

  FeaturedPropertyPrice({this.raw, this.formatted});

  factory FeaturedPropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertyPriceToJson(this);
}
