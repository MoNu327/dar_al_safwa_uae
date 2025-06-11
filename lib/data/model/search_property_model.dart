import 'package:json_annotation/json_annotation.dart';

part 'search_property_model.g.dart';

class PropertySearchResultRequest {
  @JsonKey(name: 'property_options')
  final int propertyOptions;

  @JsonKey(name: 'property_types')
  final int propertyTypes;

  @JsonKey(name: 'property_locations')
  final int propertyLocations;

  @JsonKey(name: 'property_beds_bath')
  final int propertyBedsBath;

  PropertySearchResultRequest({
    required this.propertyOptions,
    required this.propertyTypes,
    required this.propertyLocations,
    required this.propertyBedsBath,
  });

  Map<String, dynamic> toJson() {
    return {
      'property_options': propertyOptions,
      'property_types': propertyTypes,
      'property_locations': propertyLocations,
      'property_beds_bath': propertyBedsBath,
    };
  }

  factory PropertySearchResultRequest.fromJson(Map<String, dynamic> json) {
    return PropertySearchResultRequest(
      propertyOptions: json['property_options'] as int,
      propertyTypes: json['property_types'] as int,
      propertyLocations: json['property_locations'] as int,
      propertyBedsBath: json['property_beds_bath'] as int,
    );
  }
}

//response class

@JsonSerializable()
class SearchPropertyResponse {
  final bool success;
  final Message? message;
  final List<Property>? data;

  SearchPropertyResponse({
    required this.success,
    this.message,
    this.data,
  });

  factory SearchPropertyResponse.fromJson(Map<String, dynamic> json) =>
      _$SearchPropertyResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SearchPropertyResponseToJson(this);
}

@JsonSerializable()
class Message {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  Message({
    this.english,
    this.arabic,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class Property {
  final int? id;
  @JsonKey(name: 'property_title')
  final PropertyTitle? propertyTitle;
  @JsonKey(name: 'property_image')
  final String? propertyImage;
  @JsonKey(name: 'property_deal')
  final PropertyDeal? propertyDeal;
  @JsonKey(name: 'property_price')
  final PropertyPrice? propertyPrice;
  @JsonKey(name: 'property_type')
  final PropertyType? propertyType;
  @JsonKey(name: 'property_location')
  final PropertyLocation? propertyLocation;
  @JsonKey(name: 'property_bed')
  final int? propertyBed;
  @JsonKey(name: 'property_bath')
  final int? propertyBath;
  @JsonKey(name: 'property_sqft')
  final PropertySqft? propertySqft;
  @JsonKey(name: 'property_rating')
  final String? propertyRating;
  @JsonKey(name: 'property_reviews')
  final int? propertyReviews;
  @JsonKey(name: 'rating_details')
  final RatingDetails? ratingDetails;

  Property({
    this.id,
    this.propertyTitle,
    this.propertyImage,
    this.propertyDeal,
    this.propertyPrice,
    this.propertyType,
    this.propertyLocation,
    this.propertyBed,
    this.propertyBath,
    this.propertySqft,
    this.propertyRating,
    this.propertyReviews,
    this.ratingDetails,
  });

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

@JsonSerializable()
class PropertyTitle {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  PropertyTitle({
    this.english,
    this.arabic,
  });

  factory PropertyTitle.fromJson(Map<String, dynamic> json) =>
      _$PropertyTitleFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyTitleToJson(this);
}

@JsonSerializable()
class PropertyDeal {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  PropertyDeal({
    this.english,
    this.arabic,
  });

  factory PropertyDeal.fromJson(Map<String, dynamic> json) =>
      _$PropertyDealFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyDealToJson(this);
}

@JsonSerializable()
class PropertyPrice {
  final int? raw;
  final FormattedPrice? formatted;

  PropertyPrice({
    this.raw,
    this.formatted,
  });

  factory PropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$PropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyPriceToJson(this);
}

@JsonSerializable()
class FormattedPrice {
  @JsonKey(name: 'en')
  final dynamic english;
  @JsonKey(name: 'ar')
  final String? arabic;

  FormattedPrice({
    this.english,
    this.arabic,
  });

  factory FormattedPrice.fromJson(Map<String, dynamic> json) =>
      _$FormattedPriceFromJson(json);

  Map<String, dynamic> toJson() => _$FormattedPriceToJson(this);
}

@JsonSerializable()
class PropertyType {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  PropertyType({
    this.english,
    this.arabic,
  });

  factory PropertyType.fromJson(Map<String, dynamic> json) =>
      _$PropertyTypeFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyTypeToJson(this);
}

@JsonSerializable()
class PropertyLocation {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  PropertyLocation({
    this.english,
    this.arabic,
  });

  factory PropertyLocation.fromJson(Map<String, dynamic> json) =>
      _$PropertyLocationFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyLocationToJson(this);
}

@JsonSerializable()
class PropertySqft {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  PropertySqft({
    this.english,
    this.arabic,
  });

  factory PropertySqft.fromJson(Map<String, dynamic> json) =>
      _$PropertySqftFromJson(json);

  Map<String, dynamic> toJson() => _$PropertySqftToJson(this);
}

@JsonSerializable()
class RatingDetails {
  @JsonKey(name: 'en')
  final String? english;
  @JsonKey(name: 'ar')
  final String? arabic;

  RatingDetails({
    this.english,
    this.arabic,
  });

  factory RatingDetails.fromJson(Map<String, dynamic> json) =>
      _$RatingDetailsFromJson(json);

  Map<String, dynamic> toJson() => _$RatingDetailsToJson(this);
}
