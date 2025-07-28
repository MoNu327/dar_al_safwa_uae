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
        status: parsedJson['status'] as bool? ?? false,
        message: _parseMessage(parsedJson['message']),
        localizedMessages: _parseLocalizedMessages(parsedJson['message']),
        data: (parsedJson['data'] as List?)?.map((x) => Complaint.fromJson(x)).toList() ?? [],
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
  final String date; // Store raw date
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

  String get formattedDate => DateFormatter.formatTo12Hour(date);

  factory Complaint.fromJson(Map<String, dynamic> json) {
    try {
      return Complaint(
        complaintId: json['complaint_id']?.toString() ?? '',
        complaintNumber: json['complaint_number']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        replyByTechnician: json['replybytechnician']?.toString(),
        replyByAdmin: json['replybyadmin']?.toString(),
        date: json['date']?.toString() ?? '', // Store raw date
        status: json['status']?.toString() ?? '',
        statusText: json['status_text'] is Map
            ? StatusText.fromJson(json['status_text'] as Map<String, dynamic>)
            : StatusText(en: json['status_text']?.toString() ?? ''),
        category: json['category']?.toString() ?? '',
        subcategory: json['subcategory']?.toString() ?? '',
        propertyName: json['property_name']?.toString() ?? '',
        unitNumber: json['unit_number']?.toString() ?? '',
        fullAddress: json['full_address']?.toString() ?? '',
        flatnoId: json['flatno_id']?.toString() ?? '',
        images: (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
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

class StatusText {
  final String en;

  StatusText({required this.en});

  factory StatusText.fromJson(Map<String, dynamic> json) => StatusText(
    en: json['en']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'en': en};
}