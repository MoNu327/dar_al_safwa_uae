import 'package:json_annotation/json_annotation.dart';

part 'property_details_model.g.dart';

@JsonSerializable()
class PropertyResponse {
  final bool? success;
  final Message? message;
  final PropertyData? data;

  PropertyResponse({this.success, this.message, this.data});

  factory PropertyResponse.fromJson(Map<String, dynamic> json) => _$PropertyResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyResponseToJson(this);
}

@JsonSerializable()
class Message {
  final String? en;
  final String? ar;

  Message({this.en, this.ar});

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class PropertyData {
  final Property? property;

  PropertyData({this.property});

  factory PropertyData.fromJson(Map<String, dynamic> json) => _$PropertyDataFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyDataToJson(this);
}

@JsonSerializable()
class Property {
  final int? id;
  @JsonKey(name: 'highlight_images')
  final List<String>? highlightImages;
  @JsonKey(name: 'image_gallery')
  final List<String>? imageGallery;
  @JsonKey(name: 'youtube_video')
  final YoutubeVideo? youtubeVideo;
  final Message? title;
  @JsonKey(name: 'deal_type')
  final Message? dealType;
  final Location? location;
  final Price? price;
  final Message? description;
  final Overview? overview;
  @JsonKey(name: 'property_features')
  final PropertyFeatures? propertyFeatures;
  @JsonKey(name: 'unit_types')
  final UnitTypes? unitTypes;
  final Agent? agent;
  final Regulations? regulations;
  @JsonKey(name: 'nearbytype')
  final List<NearbyType>? nearbyTypes;
  final Reviews? reviews;

  Property({
    this.id,
    this.highlightImages,
    this.imageGallery,
    this.youtubeVideo,
    this.title,
    this.dealType,
    this.location,
    this.price,
    this.description,
    this.overview,
    this.propertyFeatures,
    this.unitTypes,
    this.agent,
    this.regulations,
    this.nearbyTypes,
    this.reviews,
  });

  factory Property.fromJson(Map<String, dynamic> json) => _$PropertyFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}

@JsonSerializable()
class YoutubeVideo {
  final String? url;
  final String? thumbnail;

  YoutubeVideo({this.url, this.thumbnail});

  factory YoutubeVideo.fromJson(Map<String, dynamic> json) => _$YoutubeVideoFromJson(json);
  Map<String, dynamic> toJson() => _$YoutubeVideoToJson(this);
}

@JsonSerializable()
class Location {
  final Address? address;

  Location({this.address});

  factory Location.fromJson(Map<String, dynamic> json) => _$LocationFromJson(json);
  Map<String, dynamic> toJson() => _$LocationToJson(this);
}

@JsonSerializable()
class Address {
  final Message? building;
  final Message? street;
  final Message? full;
  final Coordinates? coordinates;
  final String? icon;

  Address({this.building, this.street, this.full, this.coordinates, this.icon});

  factory Address.fromJson(Map<String, dynamic> json) => _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

@JsonSerializable()
class Coordinates {
  final double? latitude;
  final double? longitude;

  Coordinates({this.latitude, this.longitude});

  factory Coordinates.fromJson(Map<String, dynamic> json) => _$CoordinatesFromJson(json);
  Map<String, dynamic> toJson() => _$CoordinatesToJson(this);
}

@JsonSerializable()
class Price {
  final double? raw;
  final Message? formatted;

  Price({this.raw, this.formatted});

  factory Price.fromJson(Map<String, dynamic> json) => _$PriceFromJson(json);
  Map<String, dynamic> toJson() => _$PriceToJson(this);
}

@JsonSerializable()
class Overview {
  final String? en;
  final String? ar;
  final List<OverviewItem>? items;

  Overview({this.en, this.ar, this.items});

  factory Overview.fromJson(Map<String, dynamic> json) => _$OverviewFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewToJson(this);
}

@JsonSerializable()
class OverviewItem {
  final Message? title;
  final dynamic value;
  final String? icon;

  OverviewItem({this.title, this.value, this.icon});

  factory OverviewItem.fromJson(Map<String, dynamic> json) => _$OverviewItemFromJson(json);
  Map<String, dynamic> toJson() => _$OverviewItemToJson(this);
}

@JsonSerializable()
class PropertyFeatures {
  @JsonKey(name: 'section_title')
  final Message? sectionTitle;
  final List<Message>? items;

  PropertyFeatures({this.sectionTitle, this.items});

  factory PropertyFeatures.fromJson(Map<String, dynamic> json) => _$PropertyFeaturesFromJson(json);
  Map<String, dynamic> toJson() => _$PropertyFeaturesToJson(this);
}

@JsonSerializable()
class UnitTypes {
  @JsonKey(name: 'main_title')
  final Message? mainTitle;
  final List<UnitTypeData>? data;

  UnitTypes({this.mainTitle, this.data});

  factory UnitTypes.fromJson(Map<String, dynamic> json) => _$UnitTypesFromJson(json);
  Map<String, dynamic> toJson() => _$UnitTypesToJson(this);
}

@JsonSerializable()
class UnitTypeData {
  final int? id;
  final int? beds;
  final int? baths;
  final Message? area;
  @JsonKey(name: 'base_rent_amount')
  final BaseRentAmount? baseRentAmount;
  @JsonKey(name: 'unit_type')
  final UnitType? unitType;
  @JsonKey(name: 'youtube_url')
  final String? youtubeUrl;

  UnitTypeData({this.id, this.beds, this.baths, this.area, this.baseRentAmount, this.unitType, this.youtubeUrl});

  factory UnitTypeData.fromJson(Map<String, dynamic> json) => _$UnitTypeDataFromJson(json);
  Map<String, dynamic> toJson() => _$UnitTypeDataToJson(this);
}

@JsonSerializable()
class BaseRentAmount {
  final double? raw;
  final Message? formatted;

  BaseRentAmount({this.raw, this.formatted});

  factory BaseRentAmount.fromJson(Map<String, dynamic> json) => _$BaseRentAmountFromJson(json);
  Map<String, dynamic> toJson() => _$BaseRentAmountToJson(this);
}

@JsonSerializable()
class UnitType {
  final int? id;
  final String? code;
  final Message? name;
  final Message? description;

  UnitType({this.id, this.code, this.name, this.description});

  factory UnitType.fromJson(Map<String, dynamic> json) => _$UnitTypeFromJson(json);
  Map<String, dynamic> toJson() => _$UnitTypeToJson(this);
}

@JsonSerializable()
class Agent {
  final String? uid;
  final Message? name;
  final String? phone;
  final String? email;
  final String? image;

  Agent({this.uid, this.name, this.phone, this.email, this.image});

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);
  Map<String, dynamic> toJson() => _$AgentToJson(this);
}

@JsonSerializable()
class Regulations {
  @JsonKey(name: 'main_title')
  final Message? mainTitle;
  final List<RegulationData>? data;

  Regulations({this.mainTitle, this.data});

  factory Regulations.fromJson(Map<String, dynamic> json) => _$RegulationsFromJson(json);
  Map<String, dynamic> toJson() => _$RegulationsToJson(this);
}

@JsonSerializable()
class RegulationData {
  final Message? title;
  final String? value;

  RegulationData({this.title, this.value});

  factory RegulationData.fromJson(Map<String, dynamic> json) => _$RegulationDataFromJson(json);
  Map<String, dynamic> toJson() => _$RegulationDataToJson(this);
}

@JsonSerializable()
class NearbyType {
  final Message? type;
  final Message? name;
  final String? distance;

  NearbyType({this.type, this.name, this.distance});

  factory NearbyType.fromJson(Map<String, dynamic> json) => _$NearbyTypeFromJson(json);
  Map<String, dynamic> toJson() => _$NearbyTypeToJson(this);
}

@JsonSerializable()
class Reviews {
  final OverallRating? overall;
  @JsonKey(name: 'recent_reviews')
  final List<RecentReview>? recentReviews;

  Reviews({this.overall, this.recentReviews});

  factory Reviews.fromJson(Map<String, dynamic> json) => _$ReviewsFromJson(json);
  Map<String, dynamic> toJson() => _$ReviewsToJson(this);
}

@JsonSerializable()
class OverallRating {
  final double? rating;
  final int? count;

  OverallRating({this.rating, this.count});

  factory OverallRating.fromJson(Map<String, dynamic> json) => _$OverallRatingFromJson(json);
  Map<String, dynamic> toJson() => _$OverallRatingToJson(this);
}

@JsonSerializable()
class RecentReview {
  final User? user;
  final double? rating;
  final String? comment;
  final String? date;

  RecentReview({this.user, this.rating, this.comment, this.date});

  factory RecentReview.fromJson(Map<String, dynamic> json) => _$RecentReviewFromJson(json);
  Map<String, dynamic> toJson() => _$RecentReviewToJson(this);
}

@JsonSerializable()
class User {
  final String? name;
  final String? avatar;

  User({this.name, this.avatar});

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
