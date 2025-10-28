import 'package:json_annotation/json_annotation.dart';

part 'search_property_model.g.dart';

@JsonSerializable()
class PropertySearchResultRequest {
  @JsonKey(name: 'property_options')
  final int propertyOptions;

  @JsonKey(name: 'property_types')
  final int propertyTypes;

  @JsonKey(name: 'property_locations')
  final int propertyLocations;

  @JsonKey(name: 'property_beds_bath')
  final int propertyBedsBath;

  @JsonKey(name: 'property_price_range_id')
  final int  propertyPriceForSearch;

  PropertySearchResultRequest({
    required this.propertyOptions,
    required this.propertyTypes,
    required this.propertyLocations,
    required this.propertyBedsBath,
    required this.propertyPriceForSearch,
  });

  factory PropertySearchResultRequest.fromJson(Map<String, dynamic> json) =>
      _$PropertySearchResultRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PropertySearchResultRequestToJson(this);
}

@JsonSerializable()
class SearchPropertyResponse {
  final bool success;
  final List<Property>? data;

  SearchPropertyResponse({
    required this.success,
    this.data,
  });

  factory SearchPropertyResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchPropertyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchPropertyResponseToJson(this);
}

@JsonSerializable()
class Property {
  final int? id;
  final LocalizedText? title;
  @JsonKey(name: 'deal_type')
  final LocalizedText? dealType;
  final PropertyPrice? price;
  final Features? features;
  final LocalizedText? type;
  final LocalizedText? location;
  final Specs? specs;
  final String? image;
  final Rating? rating; 

  Property({
    this.id,
    this.title,
    this.dealType,
    this.price,
    this.features,
    this.type,
    this.location,
    this.specs,
    this.image,
    this.rating
  });

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

@JsonSerializable()
class LocalizedText {
  final String? en;
  final String? ar;

  LocalizedText({this.en, this.ar});

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);
}

@JsonSerializable()
class PropertyPrice {
  final int? raw;
  final FormattedPrice? formatted;

  PropertyPrice({this.raw, this.formatted});

  factory PropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$PropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyPriceToJson(this);
}

@JsonSerializable()
class FormattedPrice {
  final String? en;
  final String? ar;

  FormattedPrice({this.en, this.ar});

  factory FormattedPrice.fromJson(Map<String, dynamic> json) =>
      _$FormattedPriceFromJson(json);

  Map<String, dynamic> toJson() => _$FormattedPriceToJson(this);
}

@JsonSerializable()
class Features {
  @JsonKey(name: 'balcony')
  final bool? balcony;
  @JsonKey(name: 'maid_room')
  final bool? maidRoom;
  @JsonKey(name: 'parking')
  final bool? parking;
  @JsonKey(name: 'sea_view')
  final bool? seaView;
  @JsonKey(name: 'furnished')
  final bool? furnished;

  Features(
      {this.balcony,
      this.maidRoom,
      this.parking,
      this.seaView,
      this.furnished});

  factory Features.fromJson(Map<String, dynamic> json) =>
      _$FeaturesFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturesToJson(this);
}

@JsonSerializable()
class Specs {
  final int? beds;
  final int? baths;
  final LocalizedText? area;

  Specs({this.beds, this.baths, this.area});

  factory Specs.fromJson(Map<String, dynamic> json) => _$SpecsFromJson(json);

  Map<String, dynamic> toJson() => _$SpecsToJson(this);
}


@JsonSerializable()
class Rating {
  final double? average;

  @JsonKey(name: 'average_arabic')
  final String? averageArabic;

  final int? count;

  Rating({
    this.average,
    this.averageArabic,
    this.count,
  });

  factory Rating.fromJson(Map<String, dynamic> json) =>
      _$RatingFromJson(json);

  Map<String, dynamic> toJson() => _$RatingToJson(this);
}
