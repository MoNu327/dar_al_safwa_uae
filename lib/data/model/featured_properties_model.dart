import 'package:json_annotation/json_annotation.dart';

part 'featured_properties_model.g.dart';

@JsonSerializable()
class FeaturedPropertiesResponse {
  final bool? success;
  final FeaturedPropertiesMessage? message;
  final List<FeaturedProperty>? data;

  FeaturedPropertiesResponse({
    this.success,
    this.message,
    this.data,
  });

  factory FeaturedPropertiesResponse.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertiesResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertiesResponseToJson(this);
}

@JsonSerializable()
class FeaturedPropertiesMessage {
  final String? en;
  final String? ar;

  FeaturedPropertiesMessage({
    this.en,
    this.ar,
  });

  factory FeaturedPropertiesMessage.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertiesMessageFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertiesMessageToJson(this);
}

@JsonSerializable()
class FeaturedProperty {
  final int? id;

  @JsonKey(name: 'property_title')
  final LocalizedText? title;

  @JsonKey(name: 'property_image')
  final String? image;

  @JsonKey(name: 'property_deal')
  final LocalizedText? dealType;

  @JsonKey(name: 'property_price')
  final FeaturedPropertyPrice? price;

  @JsonKey(name: 'property_type')
  final LocalizedText? type;

  @JsonKey(name: 'property_address')
  final LocalizedText? address;

  @JsonKey(name: 'property_location')
  final LocalizedText? location;

  @JsonKey(name: 'property_bed')
  final int? bedrooms;

  @JsonKey(name: 'property_bath')
  final int? bathrooms;

  @JsonKey(name: 'property_sqft')
  final LocalizedText? area;

  FeaturedProperty({
    this.id,
    this.title,
    this.image,
    this.dealType,
    this.price,
    this.type,
    this.address,
    this.location,
    this.bedrooms,
    this.bathrooms,
    this.area,
  });

  factory FeaturedProperty.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertyFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertyToJson(this);
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
class FeaturedPropertyPrice {
  final dynamic raw;  // ✅ Changed from String? to dynamic
  final LocalizedText? formatted;

  FeaturedPropertyPrice({
    this.raw,
    this.formatted,
  });

  factory FeaturedPropertyPrice.fromJson(Map<String, dynamic> json) =>
      _$FeaturedPropertyPriceFromJson(json);

  Map<String, dynamic> toJson() => _$FeaturedPropertyPriceToJson(this);

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