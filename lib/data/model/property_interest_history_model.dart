import 'dart:convert';

class PropertyInterestsResponse {
  final bool status;
  final Message message;
  final List<PropertyInterestUser> data;

  PropertyInterestsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PropertyInterestsResponse.fromJson(Map<String, dynamic> json) {
    return PropertyInterestsResponse(
      status: json['status'] as bool,
      message: Message.fromJson(Map<String, dynamic>.from(json['message'] ?? {})),
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => PropertyInterestUser.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message.toJson(),
        'data': data.map((e) => e.toJson()).toList(),
      };
}

class Message {
  final String? en;
  final String? ar;

  Message({this.en, this.ar});

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      en: json['en'] as String?,
      ar: json['ar'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'en': en,
        'ar': ar,
      };
}

class PropertyInterestUser {
  final String propertyId;
  final String unitId;
  final String? propertyTitle;
  final String unitType;
  final String? propertyImageUrl;

  PropertyInterestUser({
    required this.propertyId,
    required this.unitId,
    this.propertyTitle,
    required this.unitType,
    this.propertyImageUrl,
  });

  factory PropertyInterestUser.fromJson(Map<String, dynamic> json) {
    return PropertyInterestUser(
      propertyId: (json['property_id'] ?? '').toString(),
      unitId: (json['unit_id'] ?? '').toString(),
      propertyTitle: json['property_title'] as String?,
      unitType: (json['unit_type'] ?? '').toString(),
      propertyImageUrl: json['property_image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'property_id': propertyId,
        'unit_id': unitId,
        'property_title': propertyTitle,
        'unit_type': unitType,
        'property_image_url': propertyImageUrl,
      };
}