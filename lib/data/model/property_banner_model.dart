import 'package:json_annotation/json_annotation.dart';

part 'property_banner_model.g.dart';

@JsonSerializable()
class PropertyBannerResponse {
  final bool? success;
  final Message? message;
  final List<PropertyBannerModel>? data;

  PropertyBannerResponse({
    this.success,
    this.message,
    this.data,
  });

  factory PropertyBannerResponse.fromJson(Map<String, dynamic> json) =>
      _$PropertyBannerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyBannerResponseToJson(this);
}

@JsonSerializable()
class Message {
  final String? en;
  final String? ar;

  Message({
    this.en,
    this.ar,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  String getText(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return ar ?? en ?? '';
      default:
        return en ?? ar ?? '';
    }
  }
}

@JsonSerializable()
class PropertyBannerModel {
  final int? id;
  @JsonKey(name: 'property_title')
  final Message? propertyTitle;
  @JsonKey(name: 'property_image')
  final String? propertyImage;
  @JsonKey(name: 'property_price')
  final PropertyPrice? propertyPrice;
  @JsonKey(name: 'property_location')
  final Message? propertyLocation;
  @JsonKey(name: 'property_bed')
  final int? propertyBed;
  @JsonKey(name: 'property_bath')
  final int? propertyBath;
  @JsonKey(name: 'property_sqft')
  final Message? propertySqft;
  final bool? featured;

  PropertyBannerModel({
    this.id,
    this.propertyTitle,
    this.propertyImage,
    this.propertyPrice,
    this.propertyLocation,
    this.propertyBed,
    this.propertyBath,
    this.propertySqft,
    this.featured,
  });

  factory PropertyBannerModel.fromJson(Map<String, dynamic> json) =>
      _$PropertyBannerModelFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyBannerModelToJson(this);

  // Helper getters
  String get titleEn => propertyTitle?.en ?? '';
  String get titleAr => propertyTitle?.ar ?? '';
  String get imageUrl => propertyImage ?? '';
  int get priceRaw => propertyPrice?.raw ?? 0;
  String get priceFormattedEn => propertyPrice?.formatted?.en ?? '';
  String get priceFormattedAr => propertyPrice?.formatted?.ar ?? '';
  String get locationEn => propertyLocation?.en ?? '';
  String get locationAr => propertyLocation?.ar ?? '';
  int get bedCount => propertyBed ?? 0;
  int get bathCount => propertyBath ?? 0;
  String get sqftEn => propertySqft?.en ?? '';
  String get sqftAr => propertySqft?.ar ?? '';
  bool get isFeatured => featured ?? false;
}

@JsonSerializable()
class PropertyPrice {
  final int? raw;
  final Message? formatted;

  PropertyPrice({
    this.raw,
    this.formatted,
  });

  factory PropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$PropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyPriceToJson(this);
}
