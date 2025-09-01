import 'package:firebase_messaging/firebase_messaging.dart';

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
    return {
      'id': id,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type,
      'propertyId': propertyId,
      'ticketId': ticketId,
      'chatId': chatId,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      imageUrl: json['imageUrl'],
      data: json['data'],
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
    return NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? _getDefaultTitle(data),
      body: message.notification?.body ?? _getDefaultBody(data),
      imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
      data: data,
      timestamp: DateTime.now(),
      type: data['type'] ?? 'general',
      propertyId: data['propertyId'],
      ticketId: data['ticketId'] ?? data['complaintId'] ?? data['assignmentId'],
      chatId: data['chatId'],
    );
  }

  static String _getDefaultTitle(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'technician_assignment': return 'New Assignment';
      case 'technician_ticket': return 'New Ticket';
      case 'job_update': return 'Job Update';
      case 'technician_rectify': return 'Rectify Ticket';
      case 'ticket': case 'complaint': case 'tenant_ticket': return 'Ticket Update';
      case 'property': case 'property_update': return 'Property Update';
      case 'tenant_property': return 'Property Notification';
      case 'tenant_documents': return 'Documents Update';
      case 'tenant_complaint': return 'Complaint Registration';
      case 'enquiry': return 'Customer Enquiry';
      case 'chat': case 'message': return 'New Message';
      case 'approval_pending': return 'Approval Required';
      default: return 'New Notification';
    }
  }

  static String _getDefaultBody(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'technician_assignment': return 'You have been assigned a new job';
      case 'technician_ticket': return 'New ticket assigned to you';
      case 'job_update': return 'Job status has been updated';
      case 'technician_rectify': return 'Ticket requires rectification';
      case 'ticket': case 'complaint': case 'tenant_ticket': return 'Ticket has been updated';
      case 'property': case 'property_update': return 'Property information updated';
      case 'tenant_property': return 'Property notification for tenant';
      case 'tenant_documents': return 'Documents have been updated';
      case 'tenant_complaint': return 'Register a new complaint';
      case 'enquiry': return 'New customer enquiry received';
      case 'chat': case 'message': return data['message'] ?? 'You have a new message';
      case 'approval_pending': return 'Your request is pending approval';
      default: return data['message'] ?? 'You have a new notification';
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
