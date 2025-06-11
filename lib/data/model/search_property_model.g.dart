// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchPropertyResponse _$SearchPropertyResponseFromJson(
        Map<String, dynamic> json) =>
    SearchPropertyResponse(
      success: json['success'] as bool,
      message: json['message'] == null
          ? null
          : Message.fromJson(json['message'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Property.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchPropertyResponseToJson(
        SearchPropertyResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      id: (json['id'] as num?)?.toInt(),
      propertyTitle: json['property_title'] == null
          ? null
          : PropertyTitle.fromJson(
              json['property_title'] as Map<String, dynamic>),
      propertyImage: json['property_image'] as String?,
      propertyDeal: json['property_deal'] == null
          ? null
          : PropertyDeal.fromJson(
              json['property_deal'] as Map<String, dynamic>),
      propertyPrice: json['property_price'] == null
          ? null
          : PropertyPrice.fromJson(
              json['property_price'] as Map<String, dynamic>),
      propertyType: json['property_type'] == null
          ? null
          : PropertyType.fromJson(
              json['property_type'] as Map<String, dynamic>),
      propertyLocation: json['property_location'] == null
          ? null
          : PropertyLocation.fromJson(
              json['property_location'] as Map<String, dynamic>),
      propertyBed: (json['property_bed'] as num?)?.toInt(),
      propertyBath: (json['property_bath'] as num?)?.toInt(),
      propertySqft: json['property_sqft'] == null
          ? null
          : PropertySqft.fromJson(
              json['property_sqft'] as Map<String, dynamic>),
      propertyRating: json['property_rating'] as String?,
      propertyReviews: (json['property_reviews'] as num?)?.toInt(),
      ratingDetails: json['rating_details'] == null
          ? null
          : RatingDetails.fromJson(
              json['rating_details'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'property_title': instance.propertyTitle,
      'property_image': instance.propertyImage,
      'property_deal': instance.propertyDeal,
      'property_price': instance.propertyPrice,
      'property_type': instance.propertyType,
      'property_location': instance.propertyLocation,
      'property_bed': instance.propertyBed,
      'property_bath': instance.propertyBath,
      'property_sqft': instance.propertySqft,
      'property_rating': instance.propertyRating,
      'property_reviews': instance.propertyReviews,
      'rating_details': instance.ratingDetails,
    };

PropertyTitle _$PropertyTitleFromJson(Map<String, dynamic> json) =>
    PropertyTitle(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$PropertyTitleToJson(PropertyTitle instance) =>
    <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

PropertyDeal _$PropertyDealFromJson(Map<String, dynamic> json) => PropertyDeal(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$PropertyDealToJson(PropertyDeal instance) =>
    <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

PropertyPrice _$PropertyPriceFromJson(Map<String, dynamic> json) =>
    PropertyPrice(
      raw: (json['raw'] as num?)?.toInt(),
      formatted: json['formatted'] == null
          ? null
          : FormattedPrice.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyPriceToJson(PropertyPrice instance) =>
    <String, dynamic>{
      'raw': instance.raw,
      'formatted': instance.formatted,
    };

FormattedPrice _$FormattedPriceFromJson(Map<String, dynamic> json) =>
    FormattedPrice(
      english: json['en'],
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$FormattedPriceToJson(FormattedPrice instance) =>
    <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

PropertyType _$PropertyTypeFromJson(Map<String, dynamic> json) => PropertyType(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$PropertyTypeToJson(PropertyType instance) =>
    <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

PropertyLocation _$PropertyLocationFromJson(Map<String, dynamic> json) =>
    PropertyLocation(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$PropertyLocationToJson(PropertyLocation instance) =>
    <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

PropertySqft _$PropertySqftFromJson(Map<String, dynamic> json) => PropertySqft(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$PropertySqftToJson(PropertySqft instance) =>
    <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };

RatingDetails _$RatingDetailsFromJson(Map<String, dynamic> json) =>
    RatingDetails(
      english: json['en'] as String?,
      arabic: json['ar'] as String?,
    );

Map<String, dynamic> _$RatingDetailsToJson(RatingDetails instance) =>
    <String, dynamic>{
      'en': instance.english,
      'ar': instance.arabic,
    };
