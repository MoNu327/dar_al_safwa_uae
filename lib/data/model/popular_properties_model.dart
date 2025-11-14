import 'package:json_annotation/json_annotation.dart';

part 'popular_properties_model.g.dart';

@JsonSerializable()
class PopularPropertiesResponse {
  final bool? success;
  final PopularPropertiesMessage? message;
  final List<PopularProperty>? data;

  PopularPropertiesResponse({
    this.success,
    this.message,
    this.data,
  });

  factory PopularPropertiesResponse.fromJson(Map<String, dynamic> json) =>
      _$PopularPropertiesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PopularPropertiesResponseToJson(this);
}

@JsonSerializable()
class PopularPropertiesMessage {
  final String? en;
  final String? ar;

  PopularPropertiesMessage({
    this.en,
    this.ar,
  });

  factory PopularPropertiesMessage.fromJson(Map<String, dynamic> json) =>
      _$PopularPropertiesMessageFromJson(json);

  Map<String, dynamic> toJson() => _$PopularPropertiesMessageToJson(this);
}

@JsonSerializable()
class PopularProperty {
  final int? id;

  @JsonKey(name: 'property_title')
  final LocalizedText? propertyTitle;

  @JsonKey(name: 'property_image')
  final String? propertyImage;

  @JsonKey(name: 'property_deal')
  final LocalizedText? propertyDeal;

  @JsonKey(name: 'property_price')
  final PropertyPrice? propertyPrice;

  @JsonKey(name: 'property_type')
  final LocalizedText? propertyType;

  @JsonKey(name: 'property_address')
  final LocalizedText? propertyAddress;

  @JsonKey(name: 'property_location')
  final LocalizedText? propertyLocation;

  @JsonKey(name: 'property_bed')
  final int? propertyBed;

  @JsonKey(name: 'property_bath')
  final int? propertyBath;

  @JsonKey(name: 'property_sqft')
  final LocalizedText? propertySqft;

  PopularProperty({
    this.id,
    this.propertyTitle,
    this.propertyImage,
    this.propertyDeal,
    this.propertyPrice,
    this.propertyType,
    this.propertyAddress,
    this.propertyLocation,
    this.propertyBed,
    this.propertyBath,
    this.propertySqft,
  });

  factory PopularProperty.fromJson(Map<String, dynamic> json) =>
      _$PopularPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$PopularPropertyToJson(this);
}

@JsonSerializable()
class LocalizedText {
  late final String? en;
  late final String? ar;

  LocalizedText({
    this.en,
    this.ar,
  });

  factory LocalizedText.fromJson(Map<String, dynamic> json) =>
      _$LocalizedTextFromJson(json);

  Map<String, dynamic> toJson() => _$LocalizedTextToJson(this);
}

// ✅ FIXED: Changed raw from String? to dynamic to handle both int and String
@JsonSerializable()
class PropertyPrice {
  final dynamic raw;  // ✅ Changed from String? to dynamic
  final LocalizedText? formatted;

  PropertyPrice({
    this.raw,
    this.formatted,
  });

  factory PropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$PropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyPriceToJson(this);

  // ✅ Helper method to get raw as String
  String getRawAsString() {
    if (raw == null) return '';
    return raw.toString();
  }

  // ✅ Helper method to get raw as number (for single values)
  num? getRawAsNumber() {
    if (raw == null) return null;
    
    if (raw is num) return raw;
    
    if (raw is String) {
      // Handle range like "18000.00-20000.00"
      if (raw.contains('-')) {
        final parts = raw.split('-');
        if (parts.isNotEmpty) {
          return num.tryParse(parts[0].trim());
        }
      }
      return num.tryParse(raw);
    }
    
    return null;
  }

  // ✅ Check if price is a range
  bool isRange() {
    if (raw is String) {
      return raw.toString().contains('-');
    }
    return false;
  }

  // ✅ Get formatted price with fallback to raw
  String getFormattedPrice(bool isArabic) {
    // First try to get formatted price
    if (formatted != null) {
      final formattedText = isArabic ? formatted!.ar : formatted!.en;
      if (formattedText != null && formattedText.isNotEmpty) {
        return formattedText;
      }
    }

    // Fallback to raw price
    if (raw == null) return '';

    // If raw is already a formatted string (with currency or range)
    if (raw is String) {
      final rawStr = raw as String;
      
      // If it already has currency, return as is
      if (rawStr.contains('AED') || rawStr.contains('ر.ع')) {
        return rawStr;
      }
      
      // If it's a range, add currency
      if (rawStr.contains('-')) {
        return isArabic ? '$rawStr ر.ع' : 'AED $rawStr';
      }
      
      // Try to parse and format
      final numValue = num.tryParse(rawStr);
      if (numValue != null) {
        final formatted = numValue.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},'
        );
        return isArabic ? '$formatted ر.ع' : 'AED $formatted';
      }
      
      // Return as is if can't parse
      return rawStr;
    }

    // If raw is a number, format it
    if (raw is num) {
      final formatted = raw.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},'
      );
      return isArabic ? '$formatted ر.ع' : 'AED $formatted';
    }

    return raw.toString();
  }

  // ✅ Get price with "annually" label
  String getPriceWithAnnually(bool isArabic) {
    final price = getFormattedPrice(isArabic);
    if (price.isEmpty) {
      return isArabic ? 'السعر غير متاح' : 'Price unavailable';
    }
    return isArabic 
        ? '$price / سنوياً' 
        : '$price / annually';
  }
}