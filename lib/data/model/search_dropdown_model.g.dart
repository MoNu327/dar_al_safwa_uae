// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_dropdown_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchDropdownResponse _$SearchDropdownResponseFromJson(
        Map<String, dynamic> json) =>
    SearchDropdownResponse(
      success: json['success'] as bool,
      message: json['message'] == null
          ? null
          : SearchDropdownMessage.fromJson(
              json['message'] as Map<String, dynamic>),
      data: json['data'] == null
          ? null
          : SearchDropdownData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchDropdownResponseToJson(
        SearchDropdownResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };

SearchDropdownMessage _$SearchDropdownMessageFromJson(
        Map<String, dynamic> json) =>
    SearchDropdownMessage(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );

Map<String, dynamic> _$SearchDropdownMessageToJson(
        SearchDropdownMessage instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };

SearchDropdownData _$SearchDropdownDataFromJson(Map<String, dynamic> json) =>
    SearchDropdownData(
      propertyOptions: (json['property_option'] as List<dynamic>?)
              ?.map((e) => PropertyOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      propertyTypes: (json['property_types'] as List<dynamic>?)
              ?.map((e) => PropertyType.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      propertyLocations: (json['property_locations'] as List<dynamic>?)
              ?.map((e) => PropertyLocation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      propertyBedsBaths: (json['property_beds_bath'] as List<dynamic>?)
              ?.map((e) => PropertyBedsBath.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      propertyPrices: (json['price_range'] as List<dynamic>?)
              ?.map(
                  (e) => PropertyRangePrice.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$SearchDropdownDataToJson(SearchDropdownData instance) =>
    <String, dynamic>{
      'property_option': instance.propertyOptions,
      'property_types': instance.propertyTypes,
      'property_locations': instance.propertyLocations,
      'property_beds_bath': instance.propertyBedsBaths,
      'price_range': instance.propertyPrices,
    };

PropertyOption _$PropertyOptionFromJson(Map<String, dynamic> json) =>
    PropertyOption(
      id: (json['id'] as num).toInt(),
      name: LocalizedText.fromJson(json['name'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyOptionToJson(PropertyOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

PropertyType _$PropertyTypeFromJson(Map<String, dynamic> json) => PropertyType(
      id: (json['id'] as num).toInt(),
      name: LocalizedText.fromJson(json['name'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyTypeToJson(PropertyType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

PropertyRangePrice _$PropertyRangePriceFromJson(Map<String, dynamic> json) =>
    PropertyRangePrice(
      id: (json['id'] as num).toInt(),
      name: LocalizedText.fromJson(json['name'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyRangePriceToJson(PropertyRangePrice instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

PropertyLocation _$PropertyLocationFromJson(Map<String, dynamic> json) =>
    PropertyLocation(
      id: (json['id'] as num).toInt(),
      name: LocalizedText.fromJson(json['name'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyLocationToJson(PropertyLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

PropertyBedsBath _$PropertyBedsBathFromJson(Map<String, dynamic> json) =>
    PropertyBedsBath(
      id: (json['id'] as num).toInt(),
      name: LocalizedText.fromJson(json['name'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PropertyBedsBathToJson(PropertyBedsBath instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

LocalizedText _$LocalizedTextFromJson(Map<String, dynamic> json) =>
    LocalizedText(
      en: json['en'] as String,
      ar: json['ar'] as String,
    );

Map<String, dynamic> _$LocalizedTextToJson(LocalizedText instance) =>
    <String, dynamic>{
      'en': instance.en,
      'ar': instance.ar,
    };
