// import 'dart:convert';

// import 'package:dar_al_safwa/core/utils/date_formater.dart';
// import 'package:flutter/material.dart';

// class ComplaintsResponse {
//   final bool status;
//   final String message;
//   final Map<String, String>? localizedMessages;
//   final List<Complaint> data;

//   ComplaintsResponse({
//     required this.status,
//     required this.message,
//     this.localizedMessages,
//     required this.data,
//   });

//   factory ComplaintsResponse.fromJson(dynamic json) {
//     try {
//       final Map<String, dynamic> parsedJson = json is String 
//           ? jsonDecode(json) as Map<String, dynamic>
//           : json as Map<String, dynamic>;

//       return ComplaintsResponse(
//         status: parsedJson['status'] as bool? ?? parsedJson['success'] as bool? ?? false,
//         message: _parseMessage(parsedJson['message']),
//         localizedMessages: _parseLocalizedMessages(parsedJson['message']),
//         data: (parsedJson['data'] is List)
//             ? (parsedJson['data'] as List).map((x) => Complaint.fromJson(x)).toList()
//             : [Complaint.fromJson(parsedJson['data'] ?? {})],
//       );
//     } catch (e, stack) {
//       debugPrint('Failed to parse ComplaintsResponse: $e\n$stack');
//       throw FormatException('Failed to parse complaints response: $e');
//     }
//   }

//   static String _parseMessage(dynamic message) {
//     if (message == null) return '';
//     if (message is String) return message;
//     if (message is Map) return message['en']?.toString() ?? '';
//     return message.toString();
//   }

//   static Map<String, String>? _parseLocalizedMessages(dynamic message) {
//     if (message is Map) {
//       return message.map((k, v) => MapEntry(k.toString(), v.toString()));
//     }
//     return null;
//   }

//   Map<String, dynamic> toJson() => {
//     'status': status,
//     'message': localizedMessages ?? message,
//     'data': data.map((e) => e.toJson()).toList(),
//   };
// }

// class Complaint {
//   final String complaintId;
//   final String complaintNumber;
//   final String description;
//   final String? replyByTechnician;
//   final String? replyByAdmin;
//   // final String? reply; // New field
//   final String? amountPaid; // New field
//   final String? amountPaidStatus; // New field
//   final String date; // Store raw date
//   final String? lastUpdated; // New field
//   final String? lastUpdatedByAdmin; // New field
//   final bool addedByAdmin; // New field
//   final StatusText statusText;
//   final String status;
//   final String category;
//   final String subcategory;
//   final String propertyName;
//   final String unitNumber;
//   final String unitType; // New field
//   final String fullAddress;
//   final String flatnoId;
//   final List<String> images;
//   final List<Technician> assignedTechnicians; // New field
//   final ComplaintImages complaintImages; // New field for categorized images

//   Complaint({
//     required this.complaintId,
//     required this.complaintNumber,
//     required this.description,
//     this.replyByTechnician,
//     this.replyByAdmin,
//     // this.reply,
//     this.amountPaid,
//     this.amountPaidStatus,
//     required this.date,
//     this.lastUpdated,
//     this.lastUpdatedByAdmin,
//     this.addedByAdmin = false,
//     required this.statusText,
//     required this.status,
//     required this.category,
//     required this.subcategory,
//     required this.propertyName,
//     required this.unitNumber,
//     this.unitType = '',
//     required this.fullAddress,
//     required this.flatnoId,
//     required this.images,
//     this.assignedTechnicians = const [],
//     required this.complaintImages,
//   });

//   String get formattedDate => DateFormatter.formatTo12Hour(date);
// factory Complaint.fromJson(Map<String, dynamic> json) {
//   try {
//     final property = json['property'] is Map 
//         ? (json['property'] as Map).cast<String, dynamic>() 
//         : <String, dynamic>{};
    
//     final images = json['images'] is Map 
//         ? (json['images'] as Map).cast<String, dynamic>() 
//         : <String, dynamic>{};

//     return Complaint(
//       complaintId: json['complaint_id']?.toString() ?? '',
//       complaintNumber: json['complaint_number']?.toString() ?? '',
//       description: json['description']?.toString() ?? '',
//       replyByTechnician: json['replybytechnician']?.toString() ?? json['reply']?.toString(),
//       replyByAdmin: json['replybyadmin']?.toString() ?? json['reply_by_admin']?.toString(),
//       // reply: json['reply']?.toString(),
//       amountPaid: json['amount_paid']?.toString(),
//       amountPaidStatus: json['amount_paid_status']?.toString(),
//       date: json['date']?.toString() ?? json['created_at']?.toString() ?? '',
//       lastUpdated: json['last_updated']?.toString(),
//       lastUpdatedByAdmin: json['last_updated_by_admin']?.toString(),
//       addedByAdmin: json['added_by_admin'] as bool? ?? false,
//       statusText: json['status'] is Map 
//           ? StatusText.fromJson((json['status'] as Map).cast<String, dynamic>())
//           : (json['status_text'] is Map
//               ? StatusText.fromJson((json['status_text'] as Map).cast<String, dynamic>())
//               : StatusText(en: json['status_text']?.toString() ?? '')),
//       status: json['status'] is String 
//           ? json['status'] as String
//           : (json['status'] is Map
//               ? (json['status'] as Map)['en']?.toString() ?? ''
//               : json['status_text']?.toString() ?? ''),
//       category: json['category']?.toString() ?? '',
//       subcategory: json['subcategory']?.toString() ?? '',
//       propertyName: property['title']?.toString() ?? json['property_name']?.toString() ?? '',
//       unitNumber: property['unit_number']?.toString() ?? json['unit_number']?.toString() ?? '',
//       unitType: property['unit_type']?.toString() ?? '',
//       fullAddress: property['address_format']?.toString() ?? json['full_address']?.toString() ?? '',
//       flatnoId: json['flatno_id']?.toString() ?? property['id']?.toString() ?? '',
//       images: (json['images'] is List 
//           ? (json['images'] as List).map((e) => e.toString()).toList()
//           : (images['tenant_uploaded'] as List?)?.map((e) => e.toString()).toList() ?? []),
//       assignedTechnicians: (property['assigned_technicians'] as List?)?.map((e) => 
//           Technician.fromJson((e as Map).cast<String, dynamic>())).toList() ?? [],
//       complaintImages: ComplaintImages.fromJson(images),
//     );
//   } catch (e, stack) {
//     debugPrint('Failed to parse Complaint: $e\n$stack');
//     throw FormatException('Failed to parse complaint: $e');
//   }
// }
//   Map<String, dynamic> toJson() => {
//     'complaint_id': complaintId,
//     'complaint_number': complaintNumber,
//     'description': description,
//     'replybytechnician': replyByTechnician,
//     'replybyadmin': replyByAdmin,
//     // 'reply': reply,
//     'amount_paid': amountPaid,
//     'amount_paid_status': amountPaidStatus,
//     'date': date,
//     'last_updated': lastUpdated,
//     'last_updated_by_admin': lastUpdatedByAdmin,
//     'added_by_admin': addedByAdmin,
//     'status': status,
//     'status_text': statusText.toJson(),
//     'category': category,
//     'subcategory': subcategory,
//     'property_name': propertyName,
//     'unit_number': unitNumber,
//     'unit_type': unitType,
//     'full_address': fullAddress,
//     'flatno_id': flatnoId,
//     'images': images,
//     'property': {
//       'id': flatnoId,
//       'title': propertyName,
//       'unit_number': unitNumber,
//       'address_format': fullAddress,
//       'unit_type': unitType,
//       'assigned_technicians': assignedTechnicians.map((e) => e.toJson()).toList(),
//     },
//     'complaint_images': complaintImages.toJson(),
//   };
// }

// class StatusText {
//   final String en;

//   StatusText({required this.en});

//   factory StatusText.fromJson(Map<String, dynamic> json) => StatusText(
//     en: json['en']?.toString() ?? '',
//   );

//   Map<String, dynamic> toJson() => {'en': en};
// }

// class Technician {
//   final String technicianId;
//   final String name;
//   final String email;
//   final String phone;
//   final String? photo;
//   final String assignedAt;

//   Technician({
//     required this.technicianId,
//     required this.name,
//     required this.email,
//     required this.phone,
//     this.photo,
//     required this.assignedAt,
//   });

//   factory Technician.fromJson(Map<String, dynamic> json) => Technician(
//     technicianId: json['technician_id']?.toString() ?? '',
//     name: json['name']?.toString() ?? '',
//     email: json['email']?.toString() ?? '',
//     phone: json['phone']?.toString() ?? '',
//     photo: json['photo']?.toString(),
//     assignedAt: json['assigned_at']?.toString() ?? '',
//   );

//   Map<String, dynamic> toJson() => {
//     'technician_id': technicianId,
//     'name': name,
//     'email': email,
//     'phone': phone,
//     'photo': photo,
//     'assigned_at': assignedAt,
//   };
// }

// class ComplaintImages {
//   final List<String> tenantUploaded;
//   final List<String> adminUploaded;
//   final List<String> technicianUploaded;
//   final List<String> adminTechnicianUploaded;

//   ComplaintImages({
//     this.tenantUploaded = const [],
//     this.adminUploaded = const [],
//     this.technicianUploaded = const [],
//     this.adminTechnicianUploaded = const [],
//   });

// factory ComplaintImages.fromJson(Map<String, dynamic> json) {
//   // Handle various possible field names
//   List<String> getImages(String key) {
//     final dynamic value = json[key] ?? 
//                          json[key.toLowerCase()] ?? 
//                          json[key.replaceAll('_', '')];
//     if (value is List) return value.map((e) => e.toString()).toList();
//     return [];
//   }

//   return ComplaintImages(
//     tenantUploaded: getImages('tenant_uploaded'),
//     adminUploaded: getImages('admin_uploaded'),
//     technicianUploaded: getImages('technician_uploaded') ?? 
//                        getImages('tech_uploaded'),
//     adminTechnicianUploaded: getImages('admin_technician_uploaded'),
//   );
// }

//   Map<String, dynamic> toJson() => {
//     'tenant_uploaded': tenantUploaded,
//     'admin_uploaded': adminUploaded,
//     'technician_uploaded': technicianUploaded,
//     'admin_technician_uploaded': adminTechnicianUploaded,
//   };
// }



import 'dart:convert';
import 'package:dar_al_safwa/core/utils/date_formater.dart';
import 'package:flutter/material.dart';

class ComplaintsResponse {
  final bool status;
  final String message;
  final Map<String, String>? localizedMessages;
  final List<Complaint> data;

  ComplaintsResponse({
    required this.status,
    required this.message,
    this.localizedMessages,
    required this.data,
  });

  factory ComplaintsResponse.fromJson(dynamic json) {
    try {
      final Map<String, dynamic> parsedJson = json is String 
          ? jsonDecode(json) as Map<String, dynamic>
          : json as Map<String, dynamic>;

      return ComplaintsResponse(
        status: parsedJson['status'] as bool? ?? parsedJson['success'] as bool? ?? false,
        message: _parseMessage(parsedJson['message']),
        localizedMessages: _parseLocalizedMessages(parsedJson['message']),
        data: (parsedJson['data'] is List)
            ? (parsedJson['data'] as List).map((x) => Complaint.fromJson(x)).toList()
            : [Complaint.fromJson(parsedJson['data'] ?? {})],
      );
    } catch (e, stack) {
      debugPrint('Failed to parse ComplaintsResponse: $e\n$stack');
      throw FormatException('Failed to parse complaints response: $e');
    }
  }

  static String _parseMessage(dynamic message) {
    if (message == null) return '';
    if (message is String) return message;
    if (message is Map) return message['en']?.toString() ?? '';
    return message.toString();
  }

  static Map<String, String>? _parseLocalizedMessages(dynamic message) {
    if (message is Map) {
      return message.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': localizedMessages ?? message,
    'data': data.map((e) => e.toJson()).toList(),
  };
}

class Complaint {
  final String complaintId;
  final String complaintNumber;
  final String description;
  final String? replyByTechnician;
  final String? replyByAdmin;
  final String? amountPaid;
  final String? amountPaidStatus;
  final String date;
  final String? lastUpdated;
  final String? lastUpdatedByAdmin;
  final bool addedByAdmin;
  final StatusText statusText;
  final String status;
  final String category;
  final String subcategory;
  final String propertyName;
  final String unitNumber;
  final String unitType;
  final String fullAddress;
  final String flatnoId;
  final List<String> images;
  final List<Technician> assignedTechnicians;
  final ComplaintImages complaintImages;
  
  // New fields from API response
  final User? createdBy;
  final List<TimelineEvent> timeline;

  Complaint({
    required this.complaintId,
    required this.complaintNumber,
    required this.description,
    this.replyByTechnician,
    this.replyByAdmin,
    this.amountPaid,
    this.amountPaidStatus,
    required this.date,
    this.lastUpdated,
    this.lastUpdatedByAdmin,
    this.addedByAdmin = false,
    required this.statusText,
    required this.status,
    required this.category,
    required this.subcategory,
    required this.propertyName,
    required this.unitNumber,
    this.unitType = '',
    required this.fullAddress,
    required this.flatnoId,
    required this.images,
    this.assignedTechnicians = const [],
    required this.complaintImages,
    this.createdBy,
    this.timeline = const [],
  });

  String get formattedDate => DateFormatter.formatTo12Hour(date);

  factory Complaint.fromJson(Map<String, dynamic> json) {
  try {
    debugPrint('=== PARSING COMPLAINT JSON ===');
    debugPrint('Raw JSON keys: ${json.keys.toList()}');
    
    // Handle both old and new API structure
    final complaint = json['complaint'] ?? json;
    debugPrint('Complaint keys: ${complaint.keys.toList()}');
    
    final property = json['property'] is Map 
        ? (json['property'] as Map).cast<String, dynamic>() 
        : (complaint['property'] is Map 
            ? (complaint['property'] as Map).cast<String, dynamic>()
            : <String, dynamic>{});
    
    debugPrint('Property keys: ${property.keys.toList()}');
    
    final unit = property['unit'] is Map 
        ? (property['unit'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    
    final images = complaint['images'] is Map 
        ? (complaint['images'] as Map).cast<String, dynamic>() 
        : <String, dynamic>{};


    
    // Enhanced technician parsing with multiple fallbacks
    List<Technician> parsedTechnicians = [];
    
    // Try different possible locations for technician data
    final List<dynamic>? technicianData = 
        property['assigned_technicians'] as List<dynamic>? ??
        complaint['assigned_technicians'] as List<dynamic>? ??
        json['assigned_technicians'] as List<dynamic>? ??
        property['technicians'] as List<dynamic>? ??
        complaint['technicians'] as List<dynamic>? ??
        json['technicians'] as List<dynamic>?;
    
    debugPrint('Found technician data: $technicianData');
    
    if (technicianData != null && technicianData.isNotEmpty) {
      for (var techData in technicianData) {
        if (techData is Map) {
          try {
            final technician = Technician.fromJson(techData.cast<String, dynamic>());
            parsedTechnicians.add(technician);
            debugPrint('Successfully parsed technician: ${technician.name}');
          } catch (e) {
            debugPrint('Failed to parse technician: $e');
            debugPrint('Technician data: $techData');
          }
        }
      }
    } else {
      debugPrint('No technician data found in any expected location');
    }

    return Complaint(
      complaintId: complaint['id']?.toString() ?? complaint['complaint_id']?.toString() ?? '',
      complaintNumber: complaint['complaint_number']?.toString() ?? '',
      description: complaint['description']?.toString() ?? '',
      replyByTechnician: complaint['replybytechnician']?.toString() ?? complaint['reply']?.toString(),
      replyByAdmin: complaint['replybyadmin']?.toString() ?? complaint['reply_by_admin']?.toString(),
      amountPaid: complaint['amount_paid']?.toString(),
      amountPaidStatus: complaint['amount_paid_status']?.toString(),
      date: complaint['created_at']?.toString() ?? complaint['date']?.toString() ?? '',
      lastUpdated: complaint['last_updated']?.toString(),
      lastUpdatedByAdmin: complaint['last_updated_by_admin']?.toString(),
      addedByAdmin: complaint['added_by_admin'] as bool? ?? false,
      statusText: complaint['status'] is Map 
          ? StatusText.fromJson((complaint['status'] as Map).cast<String, dynamic>())
          : (complaint['status_text'] is Map
              ? StatusText.fromJson((complaint['status_text'] as Map).cast<String, dynamic>())
              : StatusText(en: complaint['status_text']?.toString() ?? complaint['status']?.toString() ?? '')),
      status: complaint['status'] is String 
          ? complaint['status'] as String
          : (complaint['status'] is Map
              ? (complaint['status'] as Map)['en']?.toString() ?? ''
              : complaint['status_text']?.toString() ?? ''),
      category: complaint['category']?.toString() ?? '',
      subcategory: complaint['subcategory']?.toString() ?? '',
      propertyName: property['title']?.toString() ?? complaint['property_name']?.toString() ?? '',
      unitNumber: unit['number']?.toString() ?? property['unit_number']?.toString() ?? complaint['unit_number']?.toString() ?? '',
      unitType: unit['type']?.toString() ?? property['unit_type']?.toString() ?? '',
      fullAddress: unit['address_format']?.toString() ?? property['address_format']?.toString() ?? complaint['full_address']?.toString() ?? '',
      flatnoId: property['id']?.toString() ?? complaint['flatno_id']?.toString() ?? '',
      images: (complaint['images'] is List 
          ? (complaint['images'] as List).map((e) => e.toString()).toList()
          : (images['tenant_uploaded'] as List?)?.map((e) => e.toString()).toList() ?? []),
      assignedTechnicians: parsedTechnicians,
      complaintImages: ComplaintImages.fromJson(images),
      createdBy: complaint['created_by'] != null 
          ? User.fromJson((complaint['created_by'] as Map).cast<String, dynamic>())
          : null,
      timeline: (json['timeline'] as List?)?.map((e) => 
          TimelineEvent.fromJson((e as Map).cast<String, dynamic>())).toList() ?? [],
    );
  } catch (e, stack) {
    debugPrint('Failed to parse Complaint: $e\n$stack');
    throw FormatException('Failed to parse complaint: $e');
  }
}

  Map<String, dynamic> toJson() => {
    'complaint_id': complaintId,
    'complaint_number': complaintNumber,
    'description': description,
    'replybytechnician': replyByTechnician,
    'replybyadmin': replyByAdmin,
    'amount_paid': amountPaid,
    'amount_paid_status': amountPaidStatus,
    'date': date,
    'last_updated': lastUpdated,
    'last_updated_by_admin': lastUpdatedByAdmin,
    'added_by_admin': addedByAdmin,
    'status': status,
    'status_text': statusText.toJson(),
    'category': category,
    'subcategory': subcategory,
    'property_name': propertyName,
    'unit_number': unitNumber,
    'unit_type': unitType,
    'full_address': fullAddress,
    'flatno_id': flatnoId,
    'images': images,
    'created_by': createdBy?.toJson(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'property': {
      'id': flatnoId,
      'title': propertyName,
      'unit_number': unitNumber,
      'address_format': fullAddress,
      'unit_type': unitType,
      'assigned_technicians': assignedTechnicians.map((e) => e.toJson()).toList(),
    },
    'complaint_images': complaintImages.toJson(),
  };
}

class StatusText {
  final String en;

  StatusText({required this.en});

  factory StatusText.fromJson(Map<String, dynamic> json) => StatusText(
    en: json['en']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'en': en};
}

class User {
  final String type;
  final String? uid;
  final String name;
  final String? email;
  final String? phone;
  final String? photo;
  final String? role;

  User({
    required this.type,
    this.uid,
    required this.name,
    this.email,
    this.phone,
    this.photo,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    type: json['type']?.toString() ?? '',
    uid: json['uid']?.toString(),
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString(),
    phone: json['phone']?.toString(),
    photo: json['photo']?.toString(),
    role: json['role']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'uid': uid,
    'name': name,
    'email': email,
    'phone': phone,
    'photo': photo,
    'role': role,
  };
}

class Technician {
  final String technicianId;
  final String name;
  final String email;
  final String phone;
  final String? photo;
  final String assignedAt;

  Technician({
    required this.technicianId,
    required this.name,
    required this.email,
    required this.phone,
    this.photo,
    required this.assignedAt,
  });

  factory Technician.fromJson(Map<String, dynamic> json) => Technician(
    technicianId: json['technician_id']?.toString() ?? json['uid']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    photo: json['photo']?.toString(),
    assignedAt: json['assigned_at']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'technician_id': technicianId,
    'name': name,
    'email': email,
    'phone': phone,
    'photo': photo,
    'assigned_at': assignedAt,
  };
}

class TimelineEvent {
  final String type;
  final String timestamp;
  final String? message;
  final String? oldStatus;
  final String? newStatus;
  final String? imagePath;
  final String? reason;
  final User? by;
  final User? technician;

  TimelineEvent({
    required this.type,
    required this.timestamp,
    this.message,
    this.oldStatus,
    this.newStatus,
    this.imagePath,
    this.reason,
    this.by,
    this.technician,
  });

  String get formattedTimestamp => DateFormatter.formatTo12Hour(timestamp);

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
    type: json['type']?.toString() ?? '',
    timestamp: json['timestamp']?.toString() ?? '',
    message: json['message']?.toString(),
    oldStatus: json['old_status']?.toString(),
    newStatus: json['new_status']?.toString(),
    imagePath: json['image_path']?.toString(),
    reason: json['reason']?.toString(),
    by: json['by'] != null 
        ? User.fromJson((json['by'] as Map).cast<String, dynamic>())
        : null,
    technician: json['technician'] != null 
        ? User.fromJson((json['technician'] as Map).cast<String, dynamic>())
        : null,
  );

  Map<String, dynamic> toJson() => {
    'type': type,
    'timestamp': timestamp,
    'message': message,
    'old_status': oldStatus,
    'new_status': newStatus,
    'image_path': imagePath,
    'reason': reason,
    'by': by?.toJson(),
    'technician': technician?.toJson(),
  };
}

class ComplaintImages {
  final List<String> tenantUploaded;
  final List<String> adminUploaded;
  final List<String> technicianUploaded;
  final List<String> adminTechnicianUploaded;

  ComplaintImages({
    this.tenantUploaded = const [],
    this.adminUploaded = const [],
    this.technicianUploaded = const [],
    this.adminTechnicianUploaded = const [],
  });

  factory ComplaintImages.fromJson(Map<String, dynamic> json) {
    List<String> getImages(String key) {
      final dynamic value = json[key] ?? 
                           json[key.toLowerCase()] ?? 
                           json[key.replaceAll('_', '')];
      if (value is List) return value.map((e) => e.toString()).toList();
      return [];
    }

    return ComplaintImages(
      tenantUploaded: getImages('tenant_uploaded'),
      adminUploaded: getImages('admin_uploaded'),
      technicianUploaded: getImages('technician_uploaded') ?? 
                         getImages('tech_uploaded'),
      adminTechnicianUploaded: getImages('admin_technician_uploaded'),
    );
  }

  Map<String, dynamic> toJson() => {
    'tenant_uploaded': tenantUploaded,
    'admin_uploaded': adminUploaded,
    'technician_uploaded': technicianUploaded,
    'admin_technician_uploaded': adminTechnicianUploaded,
  };
}