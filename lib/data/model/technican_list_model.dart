class TechnicianDropdownResponse {
  final bool success;
  final Message message;
  final TechnicianData data;

  TechnicianDropdownResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory TechnicianDropdownResponse.fromJson(Map<String, dynamic> json) {
    return TechnicianDropdownResponse(
      success: json['success'] ?? false,
      message: Message.fromJson(json['message'] ?? {}),
      data: TechnicianData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message.toJson(),
        'data': data.toJson(),
      };

  String get displayMessage => message.en;
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

  Map<String, dynamic> toJson() => {
        'en': en,
        'ar': ar,
      };
}

class TechnicianData {
  final List<Technician> technicians;
  final int count;
  final String locationId;

  TechnicianData({
    required this.technicians,
    required this.count,
    required this.locationId,
  });

  factory TechnicianData.fromJson(Map<String, dynamic> json) {
    return TechnicianData(
      technicians: (json['technicians'] as List?)
          ?.map((tech) => Technician.fromJson(tech))
          .toList() ?? [],
      count: json['count'] ?? 0,
      locationId: json['location_id'] ?? '0',
    );
  }

  Map<String, dynamic> toJson() => {
        'technicians': technicians.map((tech) => tech.toJson()).toList(),
        'count': count,
        'location_id': locationId,
      };
}

class Technician {
  final String uid;
  final String fullName;
  final String email;
  final String phone;

  Technician({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    return Technician(
      uid: json['uid'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'fullName': fullName,
        'email': email,
        'phone': phone,
      };

  // For dropdown display
  @override
  String toString() => fullName.isNotEmpty 
      ? '$fullName (${phone.isNotEmpty ? phone : email})' 
      : email;
}