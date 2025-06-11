// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_banner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyBannerResponse _$PropertyBannerResponseFromJson(
        Map<String, dynamic> json) =>
    PropertyBannerResponse(
      success: json['success'] as bool?,
      message: json['message'] == null
          ? null
          : Message.fromJson(json['message'] as Map<String, dynamic>),
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => PropertyBannerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PropertyBannerResponseToJson(
        PropertyBannerResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

PropertyBannerModel _$PropertyBannerModelFromJson(Map<String, dynamic> json) =>
    PropertyBannerModel(
      id: (json['id'] as num?)?.toInt(),
      propertyTitle: json['property_title'] == null
          ? null
          : Message.fromJson(json['property_title'] as Map<String, dynamic>),
      propertyImage: json['property_image'] as String?,
      propertyPrice: json['property_price'] == null
          ? null
          : PropertyPrice.fromJson(
              json['property_price'] as Map<String, dynamic>),
      propertyLocation: json['property_location'] == null
          ? null
          : Message.fromJson(json['property_location'] as Map<String, dynamic>),
      propertyBed: (json['property_bed'] as num?)?.toInt(),
      propertyBath: (json['property_bath'] as num?)?.toInt(),
      propertySqft: json['property_sqft'] == null
          ? null
          : Message.fromJson(json['property_sqft'] as Map<String, dynamic>),
      featured: json['featured'] as bool?,
    );

Map<String, dynamic> _$PropertyBannerModelToJson(
        PropertyBannerModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'property_title': instance.propertyTitle,
      'property_image': instance.propertyImage,
      'property_price': instance.propertyPrice,
      'property_location': instance.propertyLocation,
      'property_bed': instance.propertyBed,
      'property_bath': instance.propertyBath,
      'property_sqft': instance.propertySqft,
      'featured': instance.featured,
    };

PropertyPrice _$PropertyPriceFromJson(Map<String, dynamic> json) =>
    PropertyPrice(
      raw: (json['raw'] as num?)?.toInt(),
      formatted: json['formatted'] == null
          ? null
          : Message.fromJson(json['formatted'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyPriceToJson(PropertyPrice instance) =>
    <String, dynamic>{
      'raw': instance.raw,
      'formatted': instance.formatted,
    };
