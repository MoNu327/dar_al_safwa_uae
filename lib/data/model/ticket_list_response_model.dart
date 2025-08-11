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
    required this.images,
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
    debugPrint('=== PARSING COMPLAINT JSON ===');
    debugPrint('Raw JSON keys: ${json.keys.toList()}');
    
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
    
    debugPrint('Found technician data: $technicianData');
    
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
            
            debugPrint('Successfully parsed technician: ${technician.name}');
          } catch (e) {
            debugPrint('Failed to parse technician: $e');
            debugPrint('Technician data: $techData');
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
      images: directImages, // Use the direct images list
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
    debugPrint('Failed to parse Complaint: $e\n$stack');
    throw FormatException('Failed to parse complaint: $e');
  }
}

  static DateTime? _parseAssignmentDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      debugPrint('Failed to parse assignment date: $dateString');
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
      images: images ?? this.images,
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
    'images': images,
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
factory ComplaintImages.fromJson(Map<String, dynamic> json, {List<String>? fallbackImages}) {
  debugPrint('=== PARSING COMPLAINT IMAGES ===');
  debugPrint('Raw JSON: $json');
  debugPrint('JSON keys: ${json.keys.toList()}');
  debugPrint('Fallback images count: ${fallbackImages?.length ?? 0}');
  
  // Enhanced key matching with more variations
  List<String> getImages(String key) {
    final List<String> keyVariations = [
      key,
      key.toLowerCase(),
      key.replaceAll('_', ''),
      key.replaceAll('_', '').toLowerCase(),
      key.replaceAll('_', '-'),
      key.replaceAll('_', '-').toLowerCase(),
      '${key}Images',
      '${key}_images',
      '${key}Uploaded',
      '${key}_uploaded',
    ];
    
    for (String keyVar in keyVariations) {
      final dynamic value = json[keyVar];
      debugPrint('Checking key "$keyVar": $value (type: ${value.runtimeType})');
      
      if (value is List) {
        final List<String> images = value.map((e) => e.toString()).where((img) => img.isNotEmpty).toList();
        debugPrint('Found ${images.length} images for key "$keyVar": $images');
        return images;
      }
    }
    
    debugPrint('No images found for key variations of "$key"');
    return [];
  }

  // Try to get images from all possible field variations
  final tenantImages = getImages('tenant_uploaded') + getImages('tenant') + getImages('user_uploaded') + getImages('customer_uploaded');
  final adminImages = getImages('admin_uploaded') + getImages('admin');
  final technicianImages = getImages('technician_uploaded') + getImages('technician') + getImages('tech_uploaded') + getImages('tech');
  final adminTechnicianImages = getImages('admin_technician_uploaded') + getImages('admin_tech_uploaded') + getImages('shared_uploaded');
  
  // Check for recent technician updates - this is key for your use case
  bool hasTechnicianUpdate = false;
  DateTime? lastTechnicianUpdate;
  
  // Check if there's a recent technician reply or update
  if (json.containsKey('replybytechnician') && 
      json['replybytechnician'] != null && 
      json['replybytechnician'].toString().isNotEmpty &&
      json['replybytechnician'].toString() != "No reply from technician") {
    hasTechnicianUpdate = true;
  }
  
  // Check for last updated timestamp
  if (json.containsKey('last_updated')) {
    try {
      lastTechnicianUpdate = DateTime.parse(json['last_updated'].toString());
      // If updated recently (within last hour), likely technician update
      if (DateTime.now().difference(lastTechnicianUpdate).inHours < 1) {
        hasTechnicianUpdate = true;
      }
    } catch (e) {
      debugPrint('Could not parse last_updated: ${json['last_updated']}');
    }
  }
  
  // Additional check: Look for any images field that might contain all images
  List<String> allFoundImages = [];
  List<String> recentlyAddedImages = [];
  
  if (json.containsKey('all_images') || json.containsKey('images')) {
    final allImagesData = json['all_images'] ?? json['images'];
    if (allImagesData is List) {
      allFoundImages = (allImagesData as List).map((e) => e.toString()).where((img) => img.isNotEmpty).toList();
      
      // If we have a technician update, consider these recent images as technician uploaded
      if (hasTechnicianUpdate) {
        recentlyAddedImages = [...allFoundImages];
      }
    } else if (allImagesData is Map) {
      // If images is a map with categories
      allImagesData.forEach((key, value) {
        if (value is List) {
          final categoryImages = (value as List).map((e) => e.toString()).where((img) => img.isNotEmpty).toList();
          debugPrint('Found images in category "$key": ${categoryImages.length}');
          
          // Categorize based on key name
          switch (key.toString().toLowerCase()) {
            case 'tenant':
            case 'user':
            case 'customer':
            case 'tenant_uploaded':
              tenantImages.addAll(categoryImages);
              break;
            case 'admin':
            case 'admin_uploaded':
              adminImages.addAll(categoryImages);
              break;
            case 'technician':
            case 'tech':
            case 'technician_uploaded':
            case 'tech_uploaded':
              technicianImages.addAll(categoryImages);
              break;
            case 'admin_technician':
            case 'admin_tech':
            case 'shared':
            case 'admin_technician_uploaded':
              adminTechnicianImages.addAll(categoryImages);
              break;
            default:
              allFoundImages.addAll(categoryImages);
              // If we have technician update context, treat unknown categories as technician
              if (hasTechnicianUpdate) {
                recentlyAddedImages.addAll(categoryImages);
              }
          }
        }
      });
    }
  }
  
  // Process fallback images with enhanced context awareness
  List<String> imagesToCategorize = [...(fallbackImages ?? []), ...allFoundImages];
  
  // Remove duplicates
  final Set<String> existingImages = {
    ...tenantImages,
    ...adminImages,
    ...technicianImages,
    ...adminTechnicianImages,
  };
  
  imagesToCategorize = imagesToCategorize.where((img) => !existingImages.contains(img)).toList();
  
  List<String> finalTenantImages = [...tenantImages];
  List<String> finalAdminImages = [...adminImages];
  List<String> finalTechnicianImages = [...technicianImages];
  List<String> finalAdminTechnicianImages = [...adminTechnicianImages];
  
  if (imagesToCategorize.isNotEmpty) {
    debugPrint('=== CATEGORIZING ${imagesToCategorize.length} ADDITIONAL IMAGES ===');
    debugPrint('Has technician update: $hasTechnicianUpdate');
    debugPrint('Recently added images count: ${recentlyAddedImages.length}');
    
    for (String imageUrl in imagesToCategorize) {
      String category = _determineImageCategoryEnhanced(imageUrl, json, hasTechnicianUpdate);
      debugPrint('Image: $imageUrl -> Category: $category');
      
      switch (category) {
        case 'tenant':
          finalTenantImages.add(imageUrl);
          break;
        case 'admin':
          finalAdminImages.add(imageUrl);
          break;
        case 'technician':
          finalTechnicianImages.add(imageUrl);
          break;
        case 'admin_technician':
          finalAdminTechnicianImages.add(imageUrl);
          break;
        default:
          // Enhanced fallback logic based on context
          if (hasTechnicianUpdate || recentlyAddedImages.contains(imageUrl)) {
            // If there's recent technician activity, new images likely from technician
            finalTechnicianImages.add(imageUrl);
          } else if (finalTechnicianImages.length < finalTenantImages.length) {
            finalTechnicianImages.add(imageUrl);
          } else if (finalAdminImages.length < finalTenantImages.length) {
            finalAdminImages.add(imageUrl);
          } else {
            finalTenantImages.add(imageUrl);
          }
      }
    }
  }
  
  debugPrint('=== FINAL IMAGE COUNTS ===');
  debugPrint('Tenant: ${finalTenantImages.length}');
  debugPrint('Admin: ${finalAdminImages.length}');
  debugPrint('Technician: ${finalTechnicianImages.length}');
  debugPrint('Admin/Technician: ${finalAdminTechnicianImages.length}');
  debugPrint('=== END COMPLAINT IMAGES PARSING ===');

  return ComplaintImages(
    tenantUploaded: finalTenantImages,
    adminUploaded: finalAdminImages,
    technicianUploaded: finalTechnicianImages,
    adminTechnicianUploaded: finalAdminTechnicianImages,
  );
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
    debugPrint('Using technician category due to recent technician update context');
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
      debugPrint('Could not parse last_updated for category determination');
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