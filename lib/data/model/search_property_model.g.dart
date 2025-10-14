// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_property_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertySearchResultRequest _$PropertySearchResultRequestFromJson(
        Map<String, dynamic> json) =>
    PropertySearchResultRequest(
      propertyOptions: (json['property_options'] as num).toInt(),
      propertyTypes: (json['property_types'] as num).toInt(),
      propertyLocations: (json['property_locations'] as num).toInt(),
      propertyBedsBath: (json['property_beds_bath'] as num).toInt(),
      propertyPriceForSearch: (json['property_price_range'] as num).toInt(),
    );

Map<String, dynamic> _$PropertySearchResultRequestToJson(
        PropertySearchResultRequest instance) =>
    <String, dynamic>{
      'property_options': instance.propertyOptions,
      'property_types': instance.propertyTypes,
      'property_locations': instance.propertyLocations,
      'property_beds_bath': instance.propertyBedsBath,
      'property_price_range': instance.propertyPriceForSearch,
    };

SearchPropertyResponse _$SearchPropertyResponseFromJson(
        Map<String, dynamic> json) =>
    SearchPropertyResponse(
      success: json['success'] as bool,
      data: (json['data'] as List<dynamic>?)
          ?.map((e) => Property.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchPropertyResponseToJson(
        SearchPropertyResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'data': instance.data,
    };

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] == null
          ? null
          : LocalizedText.fromJson(json['title'] as Map<String, dynamic>),
      dealType: json['deal_type'] == null
          ? null
          : LocalizedText.fromJson(json['deal_type'] as Map<String, dynamic>),
      price: json['price'] == null
          ? null
          : PropertyPrice.fromJson(json['price'] as Map<String, dynamic>),
      features: json['features'] == null
          ? null
          : Features.fromJson(json['features'] as Map<String, dynamic>),
      type: json['type'] == null
          ? null
          : LocalizedText.fromJson(json['type'] as Map<String, dynamic>),
      location: json['location'] == null
          ? null
          : LocalizedText.fromJson(json['location'] as Map<String, dynamic>),
      specs: json['specs'] == null
          ? null
          : Specs.fromJson(json['specs'] as Map<String, dynamic>),
      image: json['image'] as String?,
      rating: json['rating'] == null
          ? null
          : Rating.fromJson(json['rating'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'deal_type': instance.dealType,
      'price': instance.price,
      'features': instance.features,
      'type': instance.type,
      'location': instance.location,
      'specs': instance.specs,
      'image': instance.image,
      'rating': instance.rating,
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
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$FormattedPriceToJson(FormattedPrice instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

Features _$FeaturesFromJson(Map<String, dynamic> json) => Features(
      balcony: json['balcony'] as bool?,
      maidRoom: json['maid_room'] as bool?,
      parking: json['parking'] as bool?,
      seaView: json['sea_view'] as bool?,
      furnished: json['furnished'] as bool?,
    );

Map<String, dynamic> _$FeaturesToJson(Features instance) => <String, dynamic>{
      'balcony': instance.balcony,
      'maid_room': instance.maidRoom,
      'parking': instance.parking,
      'sea_view': instance.seaView,
      'furnished': instance.furnished,
    };

Specs _$SpecsFromJson(Map<String, dynamic> json) => Specs(
      beds: (json['beds'] as num?)?.toInt(),
      baths: (json['baths'] as num?)?.toInt(),
      area: json['area'] == null
          ? null
          : LocalizedText.fromJson(json['area'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SpecsToJson(Specs instance) => <String, dynamic>{
      'beds': instance.beds,
      'baths': instance.baths,
      'area': instance.area,
    };

Rating _$RatingFromJson(Map<String, dynamic> json) => Rating(
      average: (json['average'] as num?)?.toDouble(),
      averageArabic: json['average_arabic'] as String?,
      count: (json['count'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RatingToJson(Rating instance) => <String, dynamic>{
      'average': instance.average,
      'average_arabic': instance.averageArabic,
      'count': instance.count,
    };
