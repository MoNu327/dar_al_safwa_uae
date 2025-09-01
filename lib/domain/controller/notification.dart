import 'package:majan/data/model/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';

import 'package:majan/data/model/notification_model.dart';

class NotificationController extends GetxController {
  static const String _storageKey = 'stored_notifications';
  final GetStorage _storage = GetStorage();
  
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadStoredNotifications();
  }

  void loadStoredNotifications() {
    try {
      isLoading.value = true;
      final storedData = _storage.read(_storageKey);
      if (storedData != null) {
        final List<dynamic> jsonList = json.decode(storedData);
        final List<NotificationModel> loadedNotifications = jsonList
            .map((json) => NotificationModel.fromJson(json))
            .toList();
        
        loadedNotifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifications.value = loadedNotifications;
        _updateUnreadCount();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _saveNotifications() {
    try {
      final List<Map<String, dynamic>> jsonList = 
          notifications.map((notification) => notification.toJson()).toList();
      _storage.write(_storageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  void addNotificationFromRemoteMessage(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);
    addNotification(notification);
  }

  void addNotification(NotificationModel notification) {
    final existingIndex = notifications.indexWhere((n) => n.id == notification.id);
    
    if (existingIndex != -1) {
      notifications[existingIndex] = notification;
    } else {
      notifications.insert(0, notification);
      
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
    }
    
    _saveNotifications();
    _updateUnreadCount();
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _saveNotifications();
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    bool hasChanges = false;
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
        hasChanges = true;
      }
    }
    if (hasChanges) {
      _saveNotifications();
      _updateUnreadCount();
    }
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    _updateUnreadCount();
  }

  void clearAllNotifications() {
    notifications.clear();
    _saveNotifications();
    _updateUnreadCount();
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  List<NotificationModel> getNotificationsByType(String type) {
    return notifications.where((n) => n.type == type).toList();
  }
}