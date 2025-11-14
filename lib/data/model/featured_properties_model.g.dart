// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'featured_properties_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeaturedPropertiesResponse _$FeaturedPropertiesResponseFromJson(
        Map<String, dynamic> json) =>
    FeaturedPropertiesResponse(
      success: json['success'] as bool?,
      message: json['message'] == null
          ? null
          : FeaturedPropertiesMessage.fromJson(
              json['message'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => FeaturedProperty.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FeaturedPropertiesResponseToJson(
        FeaturedPropertiesResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

FeaturedPropertiesMessage _$FeaturedPropertiesMessageFromJson(
        Map<String, dynamic> json) =>
    FeaturedPropertiesMessage(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$FeaturedPropertiesMessageToJson(
        FeaturedPropertiesMessage instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

FeaturedProperty _$FeaturedPropertyFromJson(Map<String, dynamic> json) =>
    FeaturedProperty(
      id: (json['id'] as num?)?.toInt(),
      title: json['property_title'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_title'] as Map<String, dynamic>),
      image: json['property_image'] as String?,
      dealType: json['property_deal'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_deal'] as Map<String, dynamic>),
      price: json['property_price'] == null
          ? null
          : FeaturedPropertyPrice.fromJson(
              json['property_price'] as Map<String, dynamic>),
      type: json['property_type'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_type'] as Map<String, dynamic>),
      address: json['property_address'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_address'] as Map<String, dynamic>),
      location: json['property_location'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_location'] as Map<String, dynamic>),
      bedrooms: (json['property_bed'] as num?)?.toInt(),
      bathrooms: (json['property_bath'] as num?)?.toInt(),
      area: json['property_sqft'] == null
          ? null
          : LocalizedText.fromJson(
              json['property_sqft'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FeaturedPropertyToJson(FeaturedProperty instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_title': instance.title,
      'property_image': instance.image,
      'property_deal': instance.dealType,
      'property_price': instance.price,
      'property_type': instance.type,
      'property_address': instance.address,
      'property_location': instance.location,
      'property_bed': instance.bedrooms,
      'property_bath': instance.bathrooms,
      'property_sqft': instance.area,
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

FeaturedPropertyPrice _$FeaturedPropertyPriceFromJson(
        Map<String, dynamic> json) =>
    FeaturedPropertyPrice(
      raw: json['raw'],
      formatted: json['formatted'] == null
          ? null
          : LocalizedText.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FeaturedPropertyPriceToJson(
        FeaturedPropertyPrice instance) =>
    <String, dynamic>{
      'raw': instance.raw,
      'formatted': instance.formatted,
    };
