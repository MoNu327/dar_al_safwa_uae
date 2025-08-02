import 'dart:convert';

import 'package:flutter/widgets.dart';

class TicketHistoryModel {
  final String ticket;
  final String complaintId;
  final String complaintNumber;
  final String description;
  final String replyByTechnician;
  final String amountPaid;
  final String paymentStatus;
  final String tenantDate;
  final String technicianUpdateTime;
  final String status;
  final StatusText statusText;
  final String category;
  final String subcategory;
  final String propertyName;
  final String unitNumber;
  final String fullAddress;
  final String flatnoId;
  final TicketImages images;

  TicketHistoryModel({
    required this.ticket,
    required this.complaintId,
    required this.complaintNumber,
    required this.description,
    required this.replyByTechnician,
    required this.amountPaid,
    required this.paymentStatus,
    required this.tenantDate,
    required this.technicianUpdateTime,
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

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    debugPrint('Fetched JSON: ${jsonEncode(json)}'); 
    return TicketHistoryModel(
      ticket: json['ticket'] ?? '',
      complaintId: json['complaint_id'] ?? '',
      complaintNumber: json['complaint_number'] ?? '',
      description: json['tennatdescription'] ?? '',
      replyByTechnician: json['technicianreply'] ?? '',
      amountPaid: json['amount_paid'] ?? '',
      paymentStatus: json['payment_status'].toString(),
      tenantDate: json['tenantdate'] ?? '',
      technicianUpdateTime: json['technicianupdatetime'] ?? '',
      status: json['status'] ?? '',
      statusText: StatusText.fromJson(json['status_text'] ?? {}),
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      propertyName: json['property_name'] ?? '',
      unitNumber: json['unit_number'] ?? '',
      fullAddress: json['full_address'] ?? '',
      flatnoId: json['flatno_id'] ?? '',
      images: TicketImages.fromJson(json['images'] ?? {}),


    );
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
}

class TicketImages {
  final List<String> tenantImages;
  final List<String> technicianImages;

  TicketImages({
    required this.tenantImages,
    required this.technicianImages,
  });

  factory TicketImages.fromJson(Map<String, dynamic> json) {
    return TicketImages(
      tenantImages: (json['tenant_uploaded_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      technicianImages: (json['technician_uploaded_images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
