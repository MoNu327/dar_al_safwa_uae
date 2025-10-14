import 'package:majan/data/model/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

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

  // NEW: Handle notification tap with PDF support
  Future<void> handleNotificationTap(NotificationModel notification) async {
    debugPrint('=== STORED NOTIFICATION TAPPED ===');
    debugPrint('Type: ${notification.type}');
    debugPrint('Data: ${notification.data}');
    
    final data = notification.data ?? {};
    
    // Check if this is a PDF/document notification
    final link = data['link'] as String?;
    final pdfUrl = (data['pdfUrl'] ?? data['pdf_url']) as String?;
    final fileUrl = (data['fileUrl'] ?? data['file_url']) as String?;
    final notificationType = notification.type;
    
    final hasLink = link != null || pdfUrl != null || fileUrl != null;
    final isDocumentType = notificationType == 'letter' || 
                          notificationType == 'document' || 
                          notificationType == 'lease_renewal';
    
    debugPrint('Has link: $hasLink, Is document type: $isDocumentType');
    
    if (hasLink || isDocumentType) {
      // Handle PDF/document download
      await _handlePdfDownload(data);
    } else {
      // Handle regular navigation
      _handleRegularNavigation(notification);
    }
  }

  // NEW: Handle PDF download
  Future<void> _handlePdfDownload(Map<String, dynamic> data) async {
    try {
      final link = data['link'] as String?;
      final pdfUrl = (data['pdfUrl'] ?? data['pdf_url']) as String?;
      final fileUrl = (data['fileUrl'] ?? data['file_url']) as String?;
      final fileName = (data['fileName'] ?? data['file_name']) as String?;
      final fileType = (data['fileType'] ?? data['file_type']) as String?;
      
      final urlToHandle = link ?? pdfUrl ?? fileUrl;
      
      if (urlToHandle != null && urlToHandle.isNotEmpty) {
        final isPdf = urlToHandle.toLowerCase().endsWith('.pdf') || 
            fileType?.toLowerCase() == 'pdf' ||
            urlToHandle.toLowerCase().contains('.pdf');
        
        if (isPdf) {
          await _downloadAndOpenPdf(
            urlToHandle,
            fileName ?? 'letter_${DateTime.now().millisecondsSinceEpoch}.pdf'
          );
        } else {
          await _openUrl(urlToHandle);
        }
      } else {
        Get.snackbar(
          'Error',
          'No file found in this notification',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Error handling PDF download: $e');
      Get.snackbar(
        'Error',
        'Could not download the file',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // NEW: Download and open PDF
  Future<void> _downloadAndOpenPdf(String url, String fileName) async {
    try {
      debugPrint('Starting PDF download for: $url');
      
      // Request permissions based on Android version
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        debugPrint('Android SDK: $sdkInt');
        
        PermissionStatus status;
        
        if (sdkInt >= 33) {
          status = PermissionStatus.granted;
        } else if (sdkInt >= 30) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            status = await Permission.manageExternalStorage.request();
          }
        } else {
          status = await Permission.storage.request();
        }
        
        debugPrint('Permission status: $status');
        
        if (!status.isGranted && sdkInt < 33) {
          Get.snackbar(
            'Permission Required',
            'Storage permission is needed to download files',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
      }

      Get.snackbar(
        'Downloading',
        'Downloading PDF file...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      debugPrint('Fetching URL: $url');
      final response = await http.get(Uri.parse(url));
      
      debugPrint('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        String finalFileName = fileName;
        if (!finalFileName.endsWith('.pdf')) {
          finalFileName = '$finalFileName.pdf';
        }
        
        String? filePath;
        
        if (Platform.isAndroid) {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          
          filePath = '${downloadsDir.path}/$finalFileName';
          debugPrint('Using Downloads directory: $filePath');
        } else {
          final directory = await getApplicationDocumentsDirectory();
          filePath = '${directory.path}/$finalFileName';
        }

        if (filePath == null) {
          throw Exception('Could not determine save location');
        }

        final file = File(filePath);
        debugPrint('Saving file to: $filePath');
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('PDF saved successfully to: $filePath');

        // Notify Android MediaStore
        if (Platform.isAndroid) {
          await _notifyMediaScanner(filePath);
        }

        Get.snackbar(
          'Download Complete',
          'File saved to Downloads folder\n$finalFileName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );

        // Wait a moment, then open
        await Future.delayed(const Duration(milliseconds: 500));
        
        try {
          await _openPdfFile(filePath);
        } catch (e) {
          debugPrint('Error opening PDF: $e');
          Get.snackbar(
            'File Saved',
            'PDF saved to Downloads. Open it from your file manager.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      } else {
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF: $e');
      Get.snackbar(
        'Download Failed',
        'Could not download the file. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // NEW: Notify media scanner
  Future<void> _notifyMediaScanner(String filePath) async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.majan.app/file_opener');
        await platform.invokeMethod('scanFile', {'path': filePath});
        debugPrint('Media scanner notified for: $filePath');
      }
    } catch (e) {
      debugPrint('Error notifying media scanner: $e');
    }
  }

  // NEW: Open PDF file
  Future<void> _openPdfFile(String filePath) async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.majan.app/file_opener');
        await platform.invokeMethod('openFile', {'path': filePath});
        debugPrint('File opened using native method');
      } else {
        final uri = Uri.file(filePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('Error opening PDF: $e');
      throw e;
    }
  }

  // NEW: Open URL
  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('Opened URL: $url');
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      debugPrint('Error opening URL: $e');
      Get.snackbar(
        'Error',
        'Could not open the link',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // NEW: Handle regular navigation
  void _handleRegularNavigation(NotificationModel notification) {
    final data = notification.data ?? {};
    
    switch (notification.type) {
      case 'chat':
      case 'message':
        if (notification.chatId != null) {
          Get.toNamed('/agent', arguments: data);
        }
        break;
      case 'property':
      case 'property_update':
        if (notification.propertyId != null) {
          Get.toNamed('/propertyDetails', arguments: {
            'propertyId': notification.propertyId,
            ...data
          });
        }
        break;
      case 'technician_assignment':
      case 'technician_ticket':
        if (notification.ticketId != null) {
          Get.toNamed('/technician-tickets', arguments: data);
        }
        break;
      case 'ticket':
      case 'complaint':
      case 'tenant_ticket':
        Get.toNamed('/navbar');
        break;
      default:
        break;
    }
  }
}