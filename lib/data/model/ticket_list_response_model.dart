import 'dart:convert';

class ComplaintsResponse {
  final bool status;
  final String message;
  final List<Complaint> data;

  ComplaintsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ComplaintsResponse.fromJson(dynamic json) {
    if (json is String) {
      try {
        json = jsonDecode(json);
      } catch (e) {
        throw Exception("Invalid JSON string in ComplaintsResponse: $e");
      }
    }
    if (json is! Map<String, dynamic>) {
      throw Exception("ComplaintsResponse JSON is not a valid Map");
    }

    return ComplaintsResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => Complaint.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class Complaint {
  final String complaintId;
  final String complaintNumber;
  final String description;
  final String? replyByTechnician;
  final String? replyByAdmin;
  final String date;
  final String status;
  final StatusText statusText;
  final String category;
  final String subcategory;
  final String propertyName;
  final String unitNumber;
  final String fullAddress;
  final String flatnoId;
  final List<String> images;

  Complaint({
    required this.complaintId,
    required this.complaintNumber,
    required this.description,
    this.replyByTechnician,
    this.replyByAdmin,
    required this.date,
    required this.status,
    required this.statusText,
    required this.category,
    required this.subcategory,
    required this.propertyName,
    required this.unitNumber,
    required this.fullAddress,
    required this.flatnoId,
    required this.images,
  });

  factory Complaint.fromJson(dynamic json) {
    if (json is String) {
      try {
        json = jsonDecode(json);
      } catch (e) {
        throw Exception("Invalid JSON string in Complaint: $e");
      }
    }
    if (json is! Map<String, dynamic>) {
      throw Exception("Complaint JSON is not a valid Map");
    }

    return Complaint(
      complaintId: json['complaint_id'] ?? '',
      complaintNumber: json['complaint_number'] ?? '',
      description: json['description'] ?? '',
      replyByTechnician: json['replybytechnician'],
      replyByAdmin: json['replybyadmin'],
      date: json['date'] ?? '',
      status: json['status'] ?? '',
      statusText: (json['status_text'] is Map)
          ? StatusText.fromJson(json['status_text'])
          : StatusText(en: json['status_text']?.toString() ?? ''),
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      propertyName: json['property_name'] ?? '',
      unitNumber: json['unit_number'] ?? '',
      fullAddress: json['full_address'] ?? '',
      flatnoId: json['flatno_id'] ?? '',
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint_id': complaintId,
      'complaint_number': complaintNumber,
      'description': description,
      'replybytechnician': replyByTechnician,
      'replybyadmin': replyByAdmin,
      'date': date,
      'status': status,
      'status_text': statusText.toJson(),
      'category': category,
      'subcategory': subcategory,
      'property_name': propertyName,
      'unit_number': unitNumber,
      'full_address': fullAddress,
      'flatno_id': flatnoId,
      'images': images,
    };
  }
}

class StatusText {
  final String en;

  StatusText({required this.en});

  factory StatusText.fromJson(Map<String, dynamic> json) {
    return StatusText(
      en: json['en'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'en': en,
    };
  }
}
