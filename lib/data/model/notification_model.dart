import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;
  final String type;
  final String? propertyId;
  final String? ticketId;
  final String? chatId;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.timestamp,
    this.isRead = false,
    required this.type,
    this.propertyId,
    this.ticketId,
    this.chatId,
  });

  Map<String, dynamic> toJson() {
    // ✅ DEBUG: Log what we're saving
    debugPrint('💾 Converting to JSON:');
    debugPrint('   ID: $id');
    debugPrint('   Type: $type');
    debugPrint('   Data keys: ${data?.keys.toList()}');
    debugPrint('   Data is null: ${data == null}');
    
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data != null ? Map<String, dynamic>.from(data!) : null, // ✅ Deep copy
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type,
      'propertyId': propertyId,
      'ticketId': ticketId,
      'chatId': chatId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // ✅ DEBUG: Log what we're loading
    debugPrint('📥 Loading from JSON:');
    debugPrint('   ID: ${json['id']}');
    debugPrint('   Type: ${json['type']}');
    debugPrint('   Raw data: ${json['data']}');
    debugPrint('   Data type: ${json['data']?.runtimeType}');
    
    final data = json['data'];
    Map<String, dynamic>? parsedData;
    
    if (data != null) {
      if (data is Map) {
        parsedData = Map<String, dynamic>.from(data);
        debugPrint('   ✅ Parsed data as Map with ${parsedData.keys.length} keys');
      } else if (data is String) {
        // In case data was stringified
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            parsedData = Map<String, dynamic>.from(decoded);
            debugPrint('   ✅ Parsed data from String with ${parsedData.keys.length} keys');
          }
        } catch (e) {
          debugPrint('   ⚠️ Error parsing data string: $e');
        }
      }
    } else {
      debugPrint('   ⚠️ Data is null in JSON');
    }
    
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['imageUrl'],
      data: parsedData,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'general',
      propertyId: json['propertyId'],
      ticketId: json['ticketId'],
      chatId: json['chatId'],
    );
  }

 factory NotificationModel.fromRemoteMessage(RemoteMessage message) {
  final data = message.data;
  final body = message.notification?.body ?? '';
  
  debugPrint('🔍 === CREATING NOTIFICATION MODEL FROM REMOTE MESSAGE ===');
  debugPrint('   Message ID: ${message.messageId}');
  debugPrint('   Notification body: $body');
  debugPrint('   Data: $data');
  
  // ✅ SMART TYPE DETECTION: Check body text if data is empty
  String extractedType = data['type'] as String? ?? 'general';
  
  if (data.isEmpty || extractedType == 'general') {
    // Detect payment reminder from body text
    if (body.contains('Amount: OMR') || 
        body.contains('Payment due') || 
        body.contains('Payment Method:')) {
      extractedType = 'payment_reminder';
      debugPrint('   ✅ Detected payment_reminder from body text');
    }
    // Add other type detections as needed
  }
  
  debugPrint('   ✅ Final notification type: $extractedType');
  
  final model = NotificationModel(
    id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
    title: message.notification?.title ?? _getDefaultTitle(data),
    body: body,
    imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
    data: Map<String, dynamic>.from(data),
    timestamp: DateTime.now(),
    type: extractedType,  // ✅ Use detected type
    propertyId: data['propertyId'] as String?,
    ticketId: data['ticketId'] as String? ?? 
              data['complaintId'] as String? ?? 
              data['complaint_id'] as String? ?? 
              data['assignmentId'] as String?,
    chatId: data['chatId'] as String?,
  );
  
  debugPrint('🎯 Created NotificationModel:');
  debugPrint('   Model type: ${model.type}');
  
  return model;
}

  static String _getDefaultTitle(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'technician_assignment': 
        return 'New Assignment';
      case 'technician_ticket': 
        return 'New Ticket';
      case 'job_update': 
        return 'Job Update';
      case 'technician_rectify': 
        return 'Rectify Ticket';
      case 'ticket': 
      case 'complaint': 
      case 'tenant_ticket': 
        return 'Ticket Update';
      case 'new_complaint':
        return 'New Complaint Registered';
      case 'new_ticket':
        return 'New Ticket Created';
      case 'property': 
      case 'property_update': 
        return 'Property Update';
      case 'tenant_property': 
        return 'Property Notification';
      case 'tenant_documents': 
        return 'Documents Update';
      case 'tenant_complaint': 
        return 'Complaint Registration';
      case 'enquiry': 
        return 'Customer Enquiry';
      case 'chat': 
      case 'message': 
        return 'New Message';
      case 'approval_pending': 
        return 'Approval Required';
      case 'payment_reminder':
      case 'upcoming_payment':
        return 'Payment Reminder';
      case 'contract_expiry':
        return 'Contract Expiry Notice';
      case 'document_expiry':
        return 'Document Expiry Notice';
      case 'booking':
      case 'property_booking':
      case 'new_booking':
        return 'New Booking';
      case 'follow_up':
      case 'followup':
      case 'site_visit':
        return 'Follow-up Update';
      case 'property_interest':
      case 'customer_interest':
        return 'Property Interest';
      default: 
        return 'New Notification';
    }
  }

  static String _getDefaultBody(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'technician_assignment': 
        return 'You have been assigned a new job';
      case 'technician_ticket': 
        return 'New ticket assigned to you';
      case 'job_update': 
        return 'Job status has been updated';
      case 'technician_rectify': 
        return 'Ticket requires rectification';
      case 'ticket': 
      case 'complaint': 
      case 'tenant_ticket': 
        return 'Ticket has been updated';
      case 'new_complaint':
        return data['description'] as String? ?? 'New complaint registered';
      case 'new_ticket':
        return data['description'] as String? ?? 'New ticket created';
      case 'property': 
      case 'property_update': 
        return 'Property information updated';
      case 'tenant_property': 
        return 'Property notification for tenant';
      case 'tenant_documents': 
        return 'Documents have been updated';
      case 'tenant_complaint': 
        return 'Register a new complaint';
      case 'enquiry': 
        return 'New customer enquiry received';
      case 'chat': 
      case 'message': 
        return data['message'] as String? ?? 'You have a new message';
      case 'approval_pending': 
        return 'Your request is pending approval';
      case 'payment_reminder':
      case 'upcoming_payment':
        final amount = data['amount'];
        final dueDate = data['dueDate'] ?? 
                        data['expected_date'] ?? 
                        data['cheque_date'] ?? 
                        data['transfer_date'] ?? 
                        data['cash_payment_date'];
        if (amount != null && dueDate != null) {
          return 'Payment of OMR $amount is due';
        }
        return data['message'] as String? ?? 'You have a payment due';
      case 'contract_expiry':
        return data['message'] as String? ?? 'Your contract is expiring soon';
      case 'document_expiry':
        return data['message'] as String? ?? 'Your document is expiring soon';
      case 'booking':
      case 'property_booking':
      case 'new_booking':
        return data['message'] as String? ?? 'New property booking received';
      case 'follow_up':
      case 'followup':
      case 'site_visit':
        return data['message'] as String? ?? 'Follow-up update available';
      case 'property_interest':
      case 'customer_interest':
        return data['message'] as String? ?? 'Customer interested in property';
      default: 
        return data['message'] as String? ?? 'You have a new notification';
    }
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      propertyId: propertyId,
      ticketId: ticketId,
      chatId: chatId,
    );
  }
}