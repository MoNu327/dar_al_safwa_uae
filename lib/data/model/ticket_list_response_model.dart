import 'dart:convert';
import 'package:majan/core/utils/date_formater.dart';
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
      // debugPrint('Failed to parse ComplaintsResponse: $e\n$stack');
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
  // final List<String> images;
  final List<Technician> assignedTechnicians;
  final ComplaintImages complaintImages;
  
  // Enhanced fields for assignment tracking
  final User? createdBy;
  final List<TimelineEvent> timeline;
  final String? assignedTechnicianId;  // Added for direct assignment tracking
  final String? assignedTechnicianName;  // Added for direct assignment tracking
  final DateTime? assignedAt;  // Added for assignment timestamp
  final AssignmentStatus assignmentStatus;  // Added for assignment status tracking

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
    // required this.images,
    this.assignedTechnicians = const [],
    required this.complaintImages,
    this.createdBy,
    this.timeline = const [],
    this.assignedTechnicianId,
    this.assignedTechnicianName,
    this.assignedAt,
    this.assignmentStatus = AssignmentStatus.unassigned,
  });

  String get formattedDate => DateFormatter.formatTo12Hour(date);
  
  // Helper method to check if complaint is assigned
  bool get isAssigned => assignedTechnicianId != null && assignedTechnicianId!.isNotEmpty;
  
  // Helper method to get primary assigned technician
  String? get primaryTechnicianId => assignedTechnicianId ?? 
      (assignedTechnicians.isNotEmpty ? assignedTechnicians.first.technicianId : null);
  
  String? get primaryTechnicianName => assignedTechnicianName ?? 
      (assignedTechnicians.isNotEmpty ? assignedTechnicians.first.name : null);

  // Update this part in your Complaint.fromJson method:

factory Complaint.fromJson(Map<String, dynamic> json) {
  try {
    // debugPrint('=== PARSING COMPLAINT JSON ===');
    // debugPrint('Raw JSON keys: ${json.keys.toList()}');
    
    final complaint = json['complaint'] ?? json;
    // debugPrint('Complaint keys: ${complaint.keys.toList()}');
    
    final property = json['property'] is Map 
        ? (json['property'] as Map).cast<String, dynamic>() 
        : (complaint['property'] is Map 
            ? (complaint['property'] as Map).cast<String, dynamic>()
            : <String, dynamic>{});
    
    // debugPrint('Property keys: ${property.keys.toList()}');
    
    final unit = property['unit'] is Map 
        ? (property['unit'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    
    final images = complaint['images'] is Map 
        ? (complaint['images'] as Map).cast<String, dynamic>() 
        : <String, dynamic>{};

    // Extract direct images list for fallback
    List<String> directImages = [];
    if (complaint['images'] is List) {
      directImages = (complaint['images'] as List).map((e) => e.toString()).toList();
    }

    // Also check for complaint_images field
    Map<String, dynamic> complaintImagesData = {};
    if (complaint['complaint_images'] is Map) {
      complaintImagesData = (complaint['complaint_images'] as Map).cast<String, dynamic>();
    } else if (images.isNotEmpty) {
      complaintImagesData = images;
    }

    // Enhanced technician parsing with multiple fallbacks
    List<Technician> parsedTechnicians = [];
    String? assignedTechId;
    String? assignedTechName;
    DateTime? assignedAt;
    
    final List<dynamic>? technicianData = 
        property['assigned_technicians'] as List<dynamic>? ??
        complaint['assigned_technicians'] as List<dynamic>? ??
        json['assigned_technicians'] as List<dynamic>? ??
        property['technicians'] as List<dynamic>? ??
        complaint['technicians'] as List<dynamic>? ??
        json['technicians'] as List<dynamic>?;
    
    // debugPrint('Found technician data: $technicianData');
    
    if (technicianData != null && technicianData.isNotEmpty) {
      for (var techData in technicianData) {
        if (techData is Map) {
          try {
            final technician = Technician.fromJson(techData.cast<String, dynamic>());
            parsedTechnicians.add(technician);
            
            // Set primary technician info from first technician
            if (assignedTechId == null) {
              assignedTechId = technician.technicianId;
              assignedTechName = technician.name;
              assignedAt = _parseAssignmentDate(technician.assignedAt);
            }
            
            // debugPrint('Successfully parsed technician: ${technician.name}');
          } catch (e) {
            // debugPrint('Failed to parse technician: $e');
            // debugPrint('Technician data: $techData');
          }
        }
      }
    }

    // Also check for direct assignment fields
    assignedTechId ??= complaint['assigned_technician_id']?.toString() ?? 
                      complaint['assignedTechnicianId']?.toString();
    assignedTechName ??= complaint['assigned_technician_name']?.toString() ?? 
                        complaint['assignedTechnicianName']?.toString();

    // Determine assignment status
    AssignmentStatus assignmentStatus = AssignmentStatus.unassigned;
    if (assignedTechId != null && assignedTechId.isNotEmpty) {
      final statusValue = complaint['assignment_status']?.toString().toLowerCase();
      switch (statusValue) {
        case 'assigned':
          assignmentStatus = AssignmentStatus.assigned;
          break;
        case 'reassigned':
          assignmentStatus = AssignmentStatus.reassigned;
          break;
        case 'escalated':
          assignmentStatus = AssignmentStatus.escalated;
          break;
        default:
          assignmentStatus = AssignmentStatus.assigned;
      }
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
      // images: directImages, // Use the direct images list
      assignedTechnicians: parsedTechnicians,
      // Use the improved parser with fallback images
      complaintImages: ComplaintImages.fromJson(complaintImagesData, fallbackImages: directImages),
      createdBy: complaint['created_by'] != null 
          ? User.fromJson((complaint['created_by'] as Map).cast<String, dynamic>())
          : null,
      timeline: (json['timeline'] as List?)?.map((e) => 
          TimelineEvent.fromJson((e as Map).cast<String, dynamic>())).toList() ?? [],
      assignedTechnicianId: assignedTechId,
      assignedTechnicianName: assignedTechName,
      assignedAt: assignedAt,
      assignmentStatus: assignmentStatus,
    );
  } catch (e, stack) {
    // debugPrint('Failed to parse Complaint: $e\n$stack');
    throw FormatException('Failed to parse complaint: $e');
  }
}

  static DateTime? _parseAssignmentDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      // debugPrint('Failed to parse assignment date: $dateString');
      return null;
    }
  }

  // Enhanced copyWith method
  Complaint copyWith({
    String? complaintId,
    String? complaintNumber,
    String? description,
    String? replyByTechnician,
    String? replyByAdmin,
    String? amountPaid,
    String? amountPaidStatus,
    String? date,
    String? lastUpdated,
    String? lastUpdatedByAdmin,
    bool? addedByAdmin,
    StatusText? statusText,
    String? status,
    String? category,
    String? subcategory,
    String? propertyName,
    String? unitNumber,
    String? unitType,
    String? fullAddress,
    String? flatnoId,
    List<String>? images,
    List<Technician>? assignedTechnicians,
    ComplaintImages? complaintImages,
    User? createdBy,
    List<TimelineEvent>? timeline,
    String? assignedTechnicianId,
    String? assignedTechnicianName,
    DateTime? assignedAt,
    AssignmentStatus? assignmentStatus,
  }) {
    return Complaint(
      complaintId: complaintId ?? this.complaintId,
      complaintNumber: complaintNumber ?? this.complaintNumber,
      description: description ?? this.description,
      replyByTechnician: replyByTechnician ?? this.replyByTechnician,
      replyByAdmin: replyByAdmin ?? this.replyByAdmin,
      amountPaid: amountPaid ?? this.amountPaid,
      amountPaidStatus: amountPaidStatus ?? this.amountPaidStatus,
      date: date ?? this.date,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      lastUpdatedByAdmin: lastUpdatedByAdmin ?? this.lastUpdatedByAdmin,
      addedByAdmin: addedByAdmin ?? this.addedByAdmin,
      statusText: statusText ?? this.statusText,
      status: status ?? this.status,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      propertyName: propertyName ?? this.propertyName,
      unitNumber: unitNumber ?? this.unitNumber,
      unitType: unitType ?? this.unitType,
      fullAddress: fullAddress ?? this.fullAddress,
      flatnoId: flatnoId ?? this.flatnoId,
      // images: images ?? this.images,
      assignedTechnicians: assignedTechnicians ?? this.assignedTechnicians,
      complaintImages: complaintImages ?? this.complaintImages,
      createdBy: createdBy ?? this.createdBy,
      timeline: timeline ?? this.timeline,
      assignedTechnicianId: assignedTechnicianId ?? this.assignedTechnicianId,
      assignedTechnicianName: assignedTechnicianName ?? this.assignedTechnicianName,
      assignedAt: assignedAt ?? this.assignedAt,
      assignmentStatus: assignmentStatus ?? this.assignmentStatus,
    );
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
    // 'images': images,
    'created_by': createdBy?.toJson(),
    'timeline': timeline.map((e) => e.toJson()).toList(),
    'assigned_technician_id': assignedTechnicianId,
    'assigned_technician_name': assignedTechnicianName,
    'assigned_at': assignedAt?.toIso8601String(),
    'assignment_status': assignmentStatus.name,
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

// New enum for assignment status
enum AssignmentStatus {
  unassigned,
  assigned,
  reassigned,
  escalated,
}

extension AssignmentStatusExtension on AssignmentStatus {
  String get displayName {
    switch (this) {
      case AssignmentStatus.unassigned:
        return 'Unassigned';
      case AssignmentStatus.assigned:
        return 'Assigned';
      case AssignmentStatus.reassigned:
        return 'Reassigned';
      case AssignmentStatus.escalated:
        return 'Escalated';
    }
  }

  Color get color {
    switch (this) {
      case AssignmentStatus.unassigned:
        return Colors.grey;
      case AssignmentStatus.assigned:
        return Colors.blue;
      case AssignmentStatus.reassigned:
        return Colors.orange;
      case AssignmentStatus.escalated:
        return Colors.red;
    }
  }
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
// Enhanced ComplaintImages.fromJson method with better technician image detection
// Simplified and more reliable ComplaintImages.fromJson method
factory ComplaintImages.fromJson(Map<String, dynamic> json, {List<String>? fallbackImages}) {
  // debugPrint('=== SIMPLIFIED COMPLAINT IMAGES PARSING ===');
  // debugPrint('Input JSON: $json');
  // debugPrint('Fallback images: $fallbackImages');
  
  // Helper function to safely extract image list
  List<String> extractImageList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((img) => img.isNotEmpty && img != 'null')
          .toList();
    }
    if (value is String && value.isNotEmpty && value != 'null') {
      return [value];
    }
    return [];
  }

  // Try direct field extraction first
  List<String> tenantImages = extractImageList(json['tenant_uploaded']) +
                              extractImageList(json['tenant']) +
                              extractImageList(json['user_uploaded']) +
                              extractImageList(json['customer_uploaded']);

  List<String> adminImages = extractImageList(json['admin_uploaded']) +
                             extractImageList(json['admin']);

  List<String> technicianImages = extractImageList(json['technician_uploaded']) +
                                  extractImageList(json['technician']) +
                                  extractImageList(json['tech_uploaded']);

  List<String> adminTechnicianImages = extractImageList(json['admin_technician_uploaded']) +
                                       extractImageList(json['admin_tech_uploaded']) +
                                       extractImageList(json['shared_uploaded']);

  // debugPrint('Direct extraction results:');
  // debugPrint('- Tenant: ${tenantImages.length} images');
  // debugPrint('- Admin: ${adminImages.length} images');
  // debugPrint('- Technician: ${technicianImages.length} images');
  // debugPrint('- Admin/Tech: ${adminTechnicianImages.length} images');

  // If no categorized images found, use fallback logic
  if (tenantImages.isEmpty && adminImages.isEmpty && 
      technicianImages.isEmpty && adminTechnicianImages.isEmpty) {
    
    // debugPrint('No categorized images found, using fallback...');
    
    // Try to find images in other common field names
    List<String> allImages = [];
    
    // Check various possible field names
    final possibleImageFields = [
      'images', 'all_images', 'attachments', 'files', 'photos',
      'complaint_images', 'ticket_images', 'uploaded_files'
    ];
    
    for (String field in possibleImageFields) {
      final fieldImages = extractImageList(json[field]);
      allImages.addAll(fieldImages);
      if (fieldImages.isNotEmpty) {
        // debugPrint('Found ${fieldImages.length} images in field "$field"');
      }
    }
    
    // Add fallback images if provided
    if (fallbackImages != null) {
      allImages.addAll(fallbackImages);
      // debugPrint('Added ${fallbackImages.length} fallback images');
    }
    
    // Remove duplicates
    allImages = allImages.toSet().toList();
    
    if (allImages.isNotEmpty) {
      // debugPrint('Total images to distribute: ${allImages.length}');
      
      // Simple distribution logic
      if (allImages.length == 1) {
        tenantImages = allImages;
      } else if (allImages.length == 2) {
        tenantImages = [allImages[0]];
        technicianImages = [allImages[1]];
      } else if (allImages.length == 3) {
        tenantImages = [allImages[0]];
        technicianImages = [allImages[1]];
        adminImages = [allImages[2]];
      } else {
        // For 4+ images, distribute evenly
        final third = (allImages.length / 3).ceil();
        tenantImages = allImages.take(third).toList();
        technicianImages = allImages.skip(third).take(third).toList();
        adminImages = allImages.skip(third * 2).toList();
      }
      
      // debugPrint('Distributed images:');
      // debugPrint('- Tenant: ${tenantImages.length}');
      // debugPrint('- Technician: ${technicianImages.length}');
      // debugPrint('- Admin: ${adminImages.length}');
    }
  }

  // Check complaint context for better categorization
  bool hasTechnicianActivity = false;
  
  // Check for technician reply
  if (json['replybytechnician'] != null && 
      json['replybytechnician'].toString().isNotEmpty &&
      json['replybytechnician'].toString() != "No reply from technician") {
    hasTechnicianActivity = true;
  }
  
  // Check status for technician involvement
  final status = json['status']?.toString().toLowerCase() ?? '';
  if (status.contains('progress') || status.contains('assigned') || 
      status.contains('working') || status.contains('completed')) {
    hasTechnicianActivity = true;
  }
  
  // If we have technician activity but no technician images, 
  // move some tenant images to technician
  if (hasTechnicianActivity && technicianImages.isEmpty && tenantImages.length > 1) {
    final halfPoint = (tenantImages.length / 2).ceil();
    technicianImages = tenantImages.skip(halfPoint).toList();
    tenantImages = tenantImages.take(halfPoint).toList();
    
    // debugPrint('Redistributed due to technician activity:');
    // debugPrint('- Tenant: ${tenantImages.length}');
    // debugPrint('- Technician: ${technicianImages.length}');
  }

  final result = ComplaintImages(
    tenantUploaded: tenantImages,
    adminUploaded: adminImages,
    technicianUploaded: technicianImages,
    adminTechnicianUploaded: adminTechnicianImages,
  );
  
  // debugPrint('=== FINAL RESULT ===');
  // debugPrint('- Tenant: ${result.tenantUploaded}');
  // debugPrint('- Admin: ${result.adminUploaded}');
  // debugPrint('- Technician: ${result.technicianUploaded}');
  // debugPrint('- Admin/Tech: ${result.adminTechnicianUploaded}');
  // debugPrint('=== END SIMPLIFIED PARSING ===');
  
  return result;
}

// Enhanced category determination with technician update context
static String _determineImageCategoryEnhanced(String imageUrl, Map<String, dynamic> context, bool hasTechnicianUpdate) {
  String lowerUrl = imageUrl.toLowerCase();
  
  // Check URL patterns first
  if (lowerUrl.contains('tenant') || lowerUrl.contains('user') || lowerUrl.contains('customer')) {
    return 'tenant';
  } else if (lowerUrl.contains('admin') && (lowerUrl.contains('tech') || lowerUrl.contains('technician'))) {
    return 'admin_technician';
  } else if (lowerUrl.contains('admin')) {
    return 'admin';
  } else if (lowerUrl.contains('technician') || lowerUrl.contains('tech')) {
    return 'technician';
  }
  
  // If we have technician update context, prioritize technician category
  if (hasTechnicianUpdate) {
    // debugPrint('Using technician category due to recent technician update context');
    return 'technician';
  }
  
  // Check context for hints about who uploaded the image
  if (context.containsKey('last_updated_by')) {
    final lastUpdatedBy = context['last_updated_by'].toString().toLowerCase();
    if (lastUpdatedBy.contains('tech')) {
      return 'technician';
    } else if (lastUpdatedBy.contains('admin')) {
      return 'admin';
    }
  }
  
  // Check if there's a technician reply - images might be from technician
  if (context.containsKey('replybytechnician') && 
      context['replybytechnician'] != null && 
      context['replybytechnician'].toString().isNotEmpty &&
      context['replybytechnician'].toString() != "No reply from technician") {
    return 'technician';
  }
  
  // Check complaint status - if in progress or completed, later images might be from technician
  if (context.containsKey('status')) {
    final status = context['status'].toString().toLowerCase();
    if (status.contains('progress') || status.contains('assigned') || status.contains('working') || 
        status.contains('completed') || status.contains('resolved')) {
      return 'technician';
    }
  }
  
  // Check if complaint has been updated recently
  if (context.containsKey('last_updated')) {
    try {
      final lastUpdate = DateTime.parse(context['last_updated'].toString());
      final now = DateTime.now();
      
      // If updated within last 24 hours, likely technician
      if (now.difference(lastUpdate).inHours < 24) {
        return 'technician';
      }
    } catch (e) {
      // debugPrint('Could not parse last_updated for category determination');
    }
  }
  
  // Default to tenant for initial images
  return 'tenant';
}

  // Enhanced helper methods
  bool get hasAnyImages => 
      tenantUploaded.isNotEmpty || 
      adminUploaded.isNotEmpty || 
      technicianUploaded.isNotEmpty || 
      adminTechnicianUploaded.isNotEmpty;

  int get totalImageCount => 
      tenantUploaded.length + 
      adminUploaded.length + 
      technicianUploaded.length + 
      adminTechnicianUploaded.length;

  // Get all images as a single list with source information
  List<Map<String, dynamic>> get allImagesWithSource {
    List<Map<String, dynamic>> allImages = [];
    
    for (String image in tenantUploaded) {
      allImages.add({'url': image, 'source': 'tenant', 'category': 'Tenant'});
    }
    
    for (String image in adminUploaded) {
      allImages.add({'url': image, 'source': 'admin', 'category': 'Admin'});
    }
    
    for (String image in technicianUploaded) {
      allImages.add({'url': image, 'source': 'technician', 'category': 'Technician'});
    }
    
    for (String image in adminTechnicianUploaded) {
      allImages.add({'url': image, 'source': 'admin_technician', 'category': 'Admin/Technician'});
    }
    
    return allImages;
  }

  // Get images by category
  List<String> getImagesByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'tenant':
        return tenantUploaded;
      case 'admin':
        return adminUploaded;
      case 'technician':
        return technicianUploaded;
      case 'admin_technician':
        return adminTechnicianUploaded;
      default:
        return [];
    }
  }

  Map<String, dynamic> toJson() => {
    'tenant_uploaded': tenantUploaded,
    'admin_uploaded': adminUploaded,
    'technician_uploaded': technicianUploaded,
    'admin_technician_uploaded': adminTechnicianUploaded,
  };
}