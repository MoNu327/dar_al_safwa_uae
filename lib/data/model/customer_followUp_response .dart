class CustomerFollowUpResponse {
  final bool status;
  final Message message;
  final CustomerFollowUpData data;

  CustomerFollowUpResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CustomerFollowUpResponse.fromJson(Map<String, dynamic> json) {
    return CustomerFollowUpResponse(
      status: json['status'] ?? false,
      message: Message.fromJson(json['message']),
      data: CustomerFollowUpData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message.toJson(),
      'data': data.toJson(),
    };
  }
}

class Message {
  final String en;
  final String ar;

  Message({
    required this.en,
    required this.ar,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      en: json['en'] ?? '',
      ar: json['ar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'en': en,
      'ar': ar,
    };
  }
}

class CustomerFollowUpData {
  final String chatId;
  final ChatInfo chatInfo;
  final UserInfo userInfo;
  final AgentInfo agentInfo;
  final PropertyInfo propertyInfo;
  final UnitInfo unitInfo;

  CustomerFollowUpData({
    required this.chatId,
    required this.chatInfo,
    required this.userInfo,
    required this.agentInfo,
    required this.propertyInfo,
    required this.unitInfo,
  });

  factory CustomerFollowUpData.fromJson(Map<String, dynamic> json) {
    return CustomerFollowUpData(
      chatId: json['chat_id'] ?? '',
      chatInfo: ChatInfo.fromJson(json['chat_info']),
      userInfo: UserInfo.fromJson(json['user_info']),
      agentInfo: AgentInfo.fromJson(json['agent_info']),
      propertyInfo: PropertyInfo.fromJson(json['property_info']),
      unitInfo: UnitInfo.fromJson(json['unit_info']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'chat_info': chatInfo.toJson(),
      'user_info': userInfo.toJson(),
      'agent_info': agentInfo.toJson(),
      'property_info': propertyInfo.toJson(),
      'unit_info': unitInfo.toJson(),
    };
  }
}

class ChatInfo {
  final String lastMessage;
  final String lastMessageAt;
  final String status;
  final String createdAt;

  ChatInfo({
    required this.lastMessage,
    required this.lastMessageAt,
    required this.status,
    required this.createdAt,
  });

  factory ChatInfo.fromJson(Map<String, dynamic> json) {
    return ChatInfo(
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: json['lastMessageAt'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class UserInfo {
  final String uid;
  final String email;
  final String? mobile;
  final String? phoneNumber;
  final String fullName;

  UserInfo({
    required this.uid,
    required this.email,
    this.mobile,
    this.phoneNumber,
    required this.fullName,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'],
      phoneNumber: json['phoneNumber'],
      fullName: json['fullName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'mobile': mobile,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
    };
  }
}

class AgentInfo {
  final String uid;
  final String email;
  final String mobile;
  final String displayName;
  final String? fullName;

  AgentInfo({
    required this.uid,
    required this.email,
    required this.mobile,
    required this.displayName,
    this.fullName,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) {
    return AgentInfo(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      displayName: json['displayName'] ?? '',
      fullName: json['fullName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'mobile': mobile,
      'displayName': displayName,
      'fullName': fullName,
    };
  }
}

// ✅ CORRECTED: PropertyInfo with direct latitude and longitude fields
class PropertyInfo {
  final String id;
  final String title;
  final double? latitude;   // ✅ Direct field from API
  final double? longitude;  // ✅ Direct field from API

  PropertyInfo({
    required this.id,
    required this.title,
    this.latitude,
    this.longitude,
  });

  factory PropertyInfo.fromJson(Map<String, dynamic> json) {
    return PropertyInfo(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      latitude: json['latitude'] != null 
          ? (json['latitude'] is String 
              ? double.tryParse(json['latitude']) 
              : (json['latitude'] as num?)?.toDouble())
          : null,
      longitude: json['longitude'] != null 
          ? (json['longitude'] is String 
              ? double.tryParse(json['longitude']) 
              : (json['longitude'] as num?)?.toDouble())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // ✅ Helper method to check if property has valid coordinates
  bool get hasValidCoordinates {
    return latitude != null && 
           longitude != null && 
           latitude != 0.0 && 
           longitude != 0.0 &&
           latitude!.abs() <= 90 && 
           longitude!.abs() <= 180;
  }

  // ✅ Helper method to get Google Maps URL
  String? get googleMapsUrl {
    if (hasValidCoordinates) {
      return 'https://www.google.com/maps?q=$latitude,$longitude';
    }
    return null;
  }
}

class UnitInfo {
  final String id;
  final String title;

  UnitInfo({
    required this.id,
    required this.title,
  });

  factory UnitInfo.fromJson(Map<String, dynamic> json) {
    return UnitInfo(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
    };
  }
}