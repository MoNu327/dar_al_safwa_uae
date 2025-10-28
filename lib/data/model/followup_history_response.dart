// followup_history_response.dart
import 'package:flutter/material.dart';

class FollowUpHistoryResponse {
  final bool status;
  final Message message;
  final List<FollowUpHistoryItem> data;

  FollowUpHistoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory FollowUpHistoryResponse.fromJson(Map<String, dynamic> json) {
    return FollowUpHistoryResponse(
      status: json['status'] ?? false,
      message: Message.fromJson(json['message'] ?? {}),
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => FollowUpHistoryItem.fromJson(item))
          .toList() ?? [],
    );
  }
}

class FollowUpHistoryItem {
  final String id;
  final String customerId;
  final String propertyId;
  final String unitType;
  final int saleStatus;
  final StatusText? statusText; // Made nullable
  final String notes;
  final String followupDate;
  final String createdAt;
  final String updatedAt;
  final String? technicianId;
  final String? flag;

  FollowUpHistoryItem({
    required this.id,
    required this.customerId,
    required this.propertyId,
    required this.unitType,
    required this.saleStatus,
    required this.statusText, // Still required but can be null
    required this.notes,
    required this.followupDate,
    required this.createdAt,
    required this.updatedAt,
    this.technicianId,
    this.flag,
  });

  factory FollowUpHistoryItem.fromJson(Map<String, dynamic> json) {
    return FollowUpHistoryItem(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      unitType: json['unit_type'] ?? '',
      saleStatus: _parseSaleStatus(json['sale_status']),
      statusText: _parseStatusText(json['status_text']), // Use helper method
      notes: json['notes'] ?? '',
      followupDate: json['followup_date'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      technicianId: json['technician_id']?.toString(),
      flag: json['flag']?.toString(),
    );
  }

  static int _parseSaleStatus(dynamic status) {
    if (status is int) return status;
    if (status is String) return int.tryParse(status) ?? 0;
    return 0;
  }

  static StatusText? _parseStatusText(dynamic statusText) {
    if (statusText == null) return null;
    if (statusText is Map<String, dynamic>) {
      return StatusText.fromJson(statusText);
    }
    // If statusText is not in expected format, return null or default
    return null;
  }

  // Getter for English status text with fallback
  String get saleStatusText {
    if (statusText != null && statusText!.en.isNotEmpty) {
      return statusText!.en;
    }
    // Fallback based on saleStatus if statusText is null
    return _getFallbackStatusText(saleStatus);
  }

  String _getFallbackStatusText(int status) {
    switch (status) {
      case 1:
        return 'Property Visit Pending';
      case 2:
        return 'Property Visit Scheduled';
      case 3:
        return 'Property Visited';
      case 4:
        return 'Property Agreed';
      default:
        return 'Unknown Status';
    }
  }

  String get formattedCreatedAt {
    try {
      final date = DateTime.parse(createdAt);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return createdAt;
    }
  }

  String get formattedFollowupDate {
    try {
      final date = DateTime.parse(followupDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return followupDate;
    }
  }

  Color get statusColor {
    switch (saleStatus) {
      case 1: // Property Visit Pending
        return Colors.orange;
      case 2: // Property Visit Scheduled
        return Colors.blue;
      case 3: // Property Visited
        return Colors.purple;
      case 4: // Property Agreed
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData get statusIcon {
    switch (saleStatus) {
      case 1: // Property Visit Pending
        return Icons.schedule;
      case 2: // Property Visit Scheduled
        return Icons.event_available;
      case 3: // Property Visited
        return Icons.check_circle_outline;
      case 4: // Property Agreed
        return Icons.check_circle;
      default:
        return Icons.info_outline;
    }
  }
}

class StatusText {
  final String en;
  final String ar;

  StatusText({
    required this.en,
    required this.ar,
  });

  factory StatusText.fromJson(Map<String, dynamic> json) {
    return StatusText(
      en: json['en'] ?? '',
      ar: json['ar'] ?? '',
    );
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
}