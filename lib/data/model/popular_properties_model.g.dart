// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'popular_properties_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PopularPropertiesResponse _$PopularPropertiesResponseFromJson(
        Map<String, dynamic> json) =>
    PopularPropertiesResponse(
      success: json['success'] as bool?,
      message: json['message'] == null
          ? null
          : PopularPropertiesMessage.fromJson(
              json['message'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PopularProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PopularPropertiesResponseToJson(
        PopularPropertiesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

PopularPropertiesMessage _$PopularPropertiesMessageFromJson(
        Map<String, dynamic> json) =>
    PopularPropertiesMessage(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$PopularPropertiesMessageToJson(
        PopularPropertiesMessage instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

PopularProperty _$PopularPropertyFromJson(Map<String, dynamic> json) =>
    PopularProperty(
      id: (json['id'] as num?)?.toInt(),
      propertyTitle: json['property_title'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_title'] as Map<String, dynamic>),
      propertyImage: json['property_image'] as String?,
      propertyDeal: json['property_deal'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_deal'] as Map<String, dynamic>),
      propertyPrice: json['property_price'] == null
          ? null
          : PropertyPrice.fromJson(
              json['property_price'] as Map<String, dynamic>),
      propertyType: json['property_type'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_type'] as Map<String, dynamic>),
      propertyAddress: json['property_address'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_address'] as Map<String, dynamic>),
      propertyLocation: json['property_location'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_location'] as Map<String, dynamic>),
      propertyBed: (json['property_bed'] as num?)?.toInt(),
      propertyBath: (json['property_bath'] as num?)?.toInt(),
      propertySqft: json['property_sqft'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_sqft'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PopularPropertyToJson(PopularProperty instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_title': instance.propertyTitle,
      'property_image': instance.propertyImage,
      'property_deal': instance.propertyDeal,
      'property_price': instance.propertyPrice,
      'property_type': instance.propertyType,
      'property_address': instance.propertyAddress,
      'property_location': instance.propertyLocation,
      'property_bed': instance.propertyBed,
      'property_bath': instance.propertyBath,
      'property_sqft': instance.propertySqft,
    };

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) =>
    LocalizedText(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$LocalizedTextToJson(LocalizedText instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

PropertyPrice _$PropertyPriceFromJson(Map<String, dynamic> json) =>
    PropertyPrice(
      raw: (json['raw'] as num?)?.toDouble(),
      formatted: json['formatted'] == null
          ? null
          : LocalizedText.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyPriceToJson(PropertyPrice instance) =>
    <String, dynamic>{
      'raw': instance.raw,
      'formatted': instance.formatted,
    };
