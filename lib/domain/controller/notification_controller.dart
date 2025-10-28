import 'dart:async';

import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/full_complaint_model.dart';
import 'package:majan/data/model/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';


class NotificationController extends GetxController {
  // ✅ UPDATED: Use user-specific storage key
  static const String _storageKeyPrefix = 'stored_notifications_';
  static const String _currentUserKey = 'current_notification_user';
  final GetStorage _storage = GetStorage();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
    ComplaintImages? images;


  // Stream controller for real-time notifications
  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  // ✅ NEW: Current user ID for user-specific storage
  String? _currentUserId;

  @override
  void onInit() {
    super.onInit();
    loadStoredNotifications();
  }

  @override
  void onClose() {
    _notificationStreamController.close();
    super.onClose();
  }

  bool _hasLink(Map<String, dynamic> data) {
  final link = data['link'] as String?;
  final url = data['url'] as String?;
  final webUrl = data['webUrl'] as String?;
  
  return (link != null && link.isNotEmpty) ||
         (url != null && url.isNotEmpty) ||
         (webUrl != null && webUrl.isNotEmpty);
}

// ✅ NEW: Helper method to get the link from data
String? _getLink(Map<String, dynamic> data) {
  final link = data['link'] as String?;
  final url = data['url'] as String?;
  final webUrl = data['webUrl'] as String?;
  
  return link ?? url ?? webUrl;
}

  // ✅ NEW: Set user ID and load their notifications
  void setUserId(String userId) {
    if (_currentUserId == userId) {
      debugPrint('ℹ️ User ID already set to: $userId');
      return;
    }

    debugPrint('📱 Setting notification user ID: $userId');

    // Save old user's notifications if switching users
    if (_currentUserId != null && _currentUserId != userId) {
      debugPrint('💾 Saving notifications for previous user: $_currentUserId');
      _saveNotifications();
      notifications.clear();
    }

    // Set new user context
    _currentUserId = userId;
    _storage.write(_currentUserKey, userId);

    // ✅ CRITICAL: Load stored notifications IMMEDIATELY
    loadStoredNotifications();

    // ✅ Then merge pending notifications after a small delay
    Future.delayed(const Duration(milliseconds: 200), () {
      _loadAndMergePendingNotifications();
    });
  }

  // ✅ NEW: Clear user ID on logout (but keep notifications stored)
  void clearUserId() {
    debugPrint('🚪 User logging out - current user: $_currentUserId');

    // ✅ CRITICAL: Save notifications BEFORE clearing user context
    if (_currentUserId != null) {
      _saveNotifications();
      debugPrint(
          '💾 Saved ${notifications.length} notifications for user: $_currentUserId');
    }

    // Clear in-memory notifications (they'll reload on next login)
    notifications.clear();
    _updateUnreadCount();

    // NOW clear the user context
    final previousUserId = _currentUserId;
    _currentUserId = null;
    _storage.remove(_currentUserKey);

    debugPrint(
        '✅ User context cleared. Notifications for $previousUserId remain in storage.');
  }

  // ✅ UPDATED: Get user-specific storage key
  String get _storageKey {
    final userId =
        _currentUserId ?? _storage.read(_currentUserKey) ?? 'default';
    return '$_storageKeyPrefix$userId';
  }

  // ✅ UPDATED: Load notifications for current user
  void loadStoredNotifications() {
    try {
      isLoading.value = true;

      // Ensure we have a user ID
      if (_currentUserId == null) {
        _currentUserId = _storage.read(_currentUserKey);
      }

      if (_currentUserId == null) {
        debugPrint('⚠️ No user ID available, cannot load notifications');
        notifications.clear();
        _updateUnreadCount();
        return;
      }

      debugPrint('📥 Loading notifications for user: $_currentUserId');

      final storedData = _storage.read(_storageKey);

      if (storedData != null && storedData.toString().isNotEmpty) {
        try {
          final List<dynamic> jsonList = json.decode(storedData);
          final List<NotificationModel> loadedNotifications =
              jsonList.map((json) => NotificationModel.fromJson(json)).toList();

          // Sort by timestamp (newest first)
          loadedNotifications
              .sort((a, b) => b.timestamp.compareTo(a.timestamp));
          notifications.value = loadedNotifications;
          _updateUnreadCount();

          debugPrint(
              '✅ Loaded ${notifications.length} notifications for user $_currentUserId');
        } catch (e) {
          debugPrint('❌ Error parsing stored notifications: $e');
          notifications.clear();
        }
      } else {
        debugPrint('ℹ️ No stored notifications found for user $_currentUserId');
        notifications.clear();
      }
    } catch (e) {
      debugPrint('❌ Error loading notifications: $e');
      notifications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // ✅ UPDATED: Save notifications with user-specific key
  void _saveNotifications() {
    try {
      // ✅ FIX: Try multiple sources to get user ID
      String? userId = _currentUserId;

      if (userId == null) {
        userId = _storage.read(_currentUserKey);
        debugPrint('⚠️ User ID was null, retrieved from storage: $userId');
      }

      if (userId == null) {
        // ✅ FIX: Store in temporary buffer for when user logs in
        debugPrint(
            '⚠️ No user ID available - storing notifications in temporary buffer');
        _savePendingNotifications();
        return;
      }

      // Keep only last 100 notifications per user
      if (notifications.length > 100) {
        notifications.value = notifications.take(100).toList();
      }

    final List<Map<String, dynamic>> jsonList = 
        notifications.map((notification) => notification.toJson()).toList();
    
    final storageKey = '$_storageKeyPrefix$userId';
    _storage.write(storageKey, json.encode(jsonList));
    
    debugPrint('💾 Saved ${notifications.length} notifications for user $userId');
  } catch (e) {
    debugPrint('❌ Error saving notifications: $e');
    // Try to save to pending buffer as fallback
    try {
      _savePendingNotifications();
    } catch (bufferError) {
      debugPrint('❌ Error saving to pending buffer: $bufferError');
    }
  }
}

Future<void> _copyLinkToClipboard(String link) async {
  try {
    await Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'Link Copied',
      'Link copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
    debugPrint('✅ Link copied to clipboard: $link');
  } catch (e) {
    debugPrint('❌ Error copying link: $e');
    Get.snackbar(
      'Error',
      'Failed to copy link',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// ✅ NEW: Open link in browser
Future<void> _openLinkInBrowser(String link) async {
  try {
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('✅ Opened link in browser: $link');
    } else {
      throw Exception('Could not launch URL');
    }
  } catch (e) {
    debugPrint('❌ Error opening link: $e');
    Get.snackbar(
      'Error',
      'Could not open the link',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// ✅ NEW: Widget to display link actions
Widget _buildLinkActions(String link) {
  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.blue[200]!, width: 1),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.link, size: 16, color: Colors.blue[700]),
            const SizedBox(width: 6),
            Text(
              'Link Available',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            link,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Copy button
            TextButton.icon(
              onPressed: () => _copyLinkToClipboard(link),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy', style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            // Open button
            ElevatedButton.icon(
              onPressed: () => _openLinkInBrowser(link),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                elevation: 0,
              ),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    ),
  );
}


  // ✅ NEW: Save pending notifications to temporary buffer
  void _savePendingNotifications() {
    try {
      if (notifications.isEmpty) {
        debugPrint('ℹ️ No notifications to save to pending buffer');
        return;
      }

      const pendingKey = 'pending_notifications';

      // Check if there are existing pending notifications
      final existingData = _storage.read(pendingKey);
      List<NotificationModel> allPending = [];

      if (existingData != null && existingData.toString().isNotEmpty) {
        try {
          final List<dynamic> existingList = json.decode(existingData);
          allPending = existingList
              .map((json) => NotificationModel.fromJson(json))
              .toList();
          debugPrint(
              '📥 Found ${allPending.length} existing pending notifications');
        } catch (e) {
          debugPrint('⚠️ Error parsing existing pending notifications: $e');
        }
      }

      // Merge with current notifications (avoiding duplicates)
      for (var notification in notifications) {
        final existingIndex =
            allPending.indexWhere((n) => n.id == notification.id);
        if (existingIndex == -1) {
          allPending.add(notification);
        }
      }

      // Keep only last 100
      if (allPending.length > 100) {
        allPending = allPending.take(100).toList();
      }

      final List<Map<String, dynamic>> jsonList =
          allPending.map((notification) => notification.toJson()).toList();

      _storage.write(pendingKey, json.encode(jsonList));
      debugPrint(
          '💾 Saved ${allPending.length} notifications to pending buffer');
    } catch (e) {
      debugPrint('❌ Error saving pending notifications: $e');
    }
  }

  // ✅ NEW: Load and merge pending notifications
  void _loadAndMergePendingNotifications() {
    try {
      const pendingKey = 'pending_notifications';
      final storedData = _storage.read(pendingKey);

      if (storedData != null && storedData.toString().isNotEmpty) {
        final List<dynamic> jsonList = json.decode(storedData);
        final List<NotificationModel> pendingNotifications =
            jsonList.map((json) => NotificationModel.fromJson(json)).toList();

        if (pendingNotifications.isNotEmpty) {
          debugPrint(
              '📥 Found ${pendingNotifications.length} pending notifications, merging...');

          int mergedCount = 0;

          // Merge pending notifications with current ones
          for (var notification in pendingNotifications) {
            final existingIndex =
                notifications.indexWhere((n) => n.id == notification.id);
            if (existingIndex == -1) {
              notifications.insert(0, notification);
              mergedCount++;
            } else {
              debugPrint(
                  '⏭️ Skipping duplicate notification: ${notification.id}');
            }
          }

          debugPrint('✅ Merged $mergedCount new notifications');

          // Sort by timestamp (newest first)
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

          // Save merged notifications
          _saveNotifications();

          // Clear pending buffer
          _storage.remove(pendingKey);
          debugPrint('🧹 Cleared pending notifications buffer');

          // Update unread count
          _updateUnreadCount();
        } else {
          debugPrint('ℹ️ Pending buffer exists but is empty');
        }
      } else {
        debugPrint('ℹ️ No pending notifications found');
      }
    } catch (e) {
      debugPrint('❌ Error loading pending notifications: $e');
      // Don't rethrow - we don't want to break the login flow
    }
  }

  void addNotificationFromRemoteMessage(RemoteMessage message) {
    final notification = NotificationModel.fromRemoteMessage(message);
    addNotification(notification);

    // Also add to stream for real-time processing
    _notificationStreamController.add(message.data);
  }

  void addNotification(NotificationModel notification) {
    final existingIndex =
        notifications.indexWhere((n) => n.id == notification.id);

    if (existingIndex != -1) {
      notifications[existingIndex] = notification;
      debugPrint('📝 Updated existing notification: ${notification.id}');
    } else {
      notifications.insert(0, notification);
      debugPrint('➕ Added new notification: ${notification.id}');

      // Keep only last 100 notifications
      if (notifications.length > 100) {
        notifications.removeRange(100, notifications.length);
      }
    }

    _saveNotifications();
    _updateUnreadCount();

    // Also notify stream for real-time processing
    _notificationStreamController.add(notification.data ?? {});
  }

  // Direct method to add data to stream (for TenantsTicketsController)
  void addNotificationData(Map<String, dynamic> data) {
    _notificationStreamController.add(data);
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _saveNotifications();
      _updateUnreadCount();
      debugPrint('✓ Marked notification as read: $notificationId');
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
      debugPrint('✓ Marked all notifications as read');
    }
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere((n) => n.id == notificationId);
    _saveNotifications();
    _updateUnreadCount();
    debugPrint('🗑️ Deleted notification: $notificationId');
  }

  void clearAllNotifications() {
    notifications.clear();
    _saveNotifications();
    _updateUnreadCount();
    debugPrint('🗑️ Cleared all notifications for user $_currentUserId');
  }

  // ✅ NEW: Clear notifications for all users (admin function)
  void clearAllUsersNotifications() {
    final allKeys = _storage.getKeys();
    for (var key in allKeys) {
      if (key.toString().startsWith(_storageKeyPrefix)) {
        _storage.remove(key);
      }
    }
    notifications.clear();
    _updateUnreadCount();
    debugPrint('🗑️ Cleared notifications for all users');
  }

  // ✅ NEW: Clean old notifications (older than 30 days)
  void cleanOldNotifications({int daysToKeep = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    final originalCount = notifications.length;

    notifications.removeWhere((n) => n.timestamp.isBefore(cutoffDate));

    final removedCount = originalCount - notifications.length;
    if (removedCount > 0) {
      _saveNotifications();
      debugPrint(
          '🧹 Cleaned $removedCount old notifications (older than $daysToKeep days)');
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  List<NotificationModel> getNotificationsByType(String type) {
    return notifications.where((n) => n.type == type).toList();
  }

  // Get ticket-related notifications
  List<NotificationModel> getTicketNotifications() {
    return notifications
        .where((n) =>
            n.type == 'ticket_reply' ||
            n.type == 'complaint_reply' ||
            n.type == 'ticket_update' ||
            n.type == 'complaint' ||
            n.type == 'tenant_ticket' ||
            n.type == 'complaint_status_update')
        .toList();
  }

  // Check if there are unread ticket notifications
  bool hasUnreadTicketNotifications() {
    return notifications.any((n) =>
        !n.isRead &&
        (n.type == 'ticket_reply' ||
            n.type == 'complaint_reply' ||
            n.type == 'ticket_update' ||
            n.type == 'complaint' ||
            n.type == 'tenant_ticket' ||
            n.type == 'complaint_status_update'));
  }

  // Handle notification tap with PDF support
  Future<void> handleNotificationTap(NotificationModel notification) async {
    debugPrint('=== STORED NOTIFICATION TAPPED ===');
    debugPrint('Type: ${notification.type}');
    debugPrint('Data: ${notification.data}');

    // Mark as read when tapped
    markAsRead(notification.id);

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

  // Handle PDF download
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
              fileName ??
                  'letter_${DateTime.now().millisecondsSinceEpoch}.pdf');
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

  // Download and open PDF using open_filex
  Future<void> _downloadAndOpenPdf(String url, String fileName) async {
  try {
    debugPrint('Starting PDF download for: $url');

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

    // ✅ CHANGED: Show persistent downloading snackbar
    Get.snackbar(
      'Downloading',
      'Downloading PDF file...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      showProgressIndicator: true,
      isDismissible: false,
      duration: null, // ← Makes it persistent
    );

    debugPrint('Fetching URL: $url');
    final response = await http.get(Uri.parse(url));

    debugPrint('Response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      String finalFileName = fileName;
      if (!finalFileName.endsWith('.pdf')) {
        finalFileName = '$finalFileName.pdf';
      }

      String filePath;

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
        debugPrint('Using iOS documents directory: $filePath');
      }

      final file = File(filePath);
      debugPrint('Saving file to: $filePath');
      await file.writeAsBytes(response.bodyBytes);
      debugPrint('PDF saved successfully to: $filePath');

      if (Platform.isAndroid) {
        await _notifyMediaScanner(filePath);
      }

      // ✅ CHANGED: Close downloading snackbar
      Get.closeAllSnackbars();

      Get.snackbar(
        'Download Complete',
        Platform.isAndroid
            ? 'File saved to Downloads folder\n$finalFileName'
            : 'File saved successfully\n$finalFileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      try {
        final result = await OpenFilex.open(filePath);

        if (result.type != ResultType.done) {
          debugPrint('Could not open PDF: ${result.message}');
          Get.snackbar(
            'File Saved',
            Platform.isAndroid
                ? 'PDF saved to Downloads. Open it from your file manager.'
                : 'PDF saved. You can open it from the Files app.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        }
      } catch (e) {
        debugPrint('Error opening PDF: $e');
        Get.snackbar(
          'File Saved',
          Platform.isAndroid
              ? 'PDF saved to Downloads. Open it from your file manager.'
              : 'PDF saved. You can open it from the Files app.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } else {
      // ✅ CHANGED: Close downloading snackbar on error
      Get.closeAllSnackbars();
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error downloading PDF: $e');
    // ✅ CHANGED: Close downloading snackbar on error
    Get.closeAllSnackbars();
    Get.snackbar(
      'Download Failed',
      'Could not download the file. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
  // Notify media scanner
  Future<void> _notifyMediaScanner(String filePath) async {
    try {
      if (Platform.isAndroid) {
        const platform = MethodChannel('com.daralsafwa.app/file_opener');
        await platform.invokeMethod('scanFile', {'path': filePath});
        debugPrint('Media scanner notified for: $filePath');
      }
    } catch (e) {
      debugPrint('Error notifying media scanner: $e');
    }
  }

  // Open URL
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

 void _handleRegularNavigation(NotificationModel notification) {
  final data = notification.data ?? {};
  final notificationType = data['type'] as String?;
   final hasLink = _hasLink(data);
  final link = hasLink ? _getLink(data) : null;
    debugPrint('🎯 Handling navigation for type: ${notification.type}');

  debugPrint('🎯 Navigating using GetX for type: $notificationType');
  debugPrint('🎯 Handling navigation for type: ${notification.type}');
  debugPrint('🎯 Ticket ID: ${notification.ticketId}');
  
  switch (notification.type) {
   case 'chat':
    case 'message':
      final message = data['message'] as String?;
      final userName = data['userName'] as String? ?? 'User';
      
      if (message != null && message.isNotEmpty) {
        Get.dialog(
          AlertDialog(
            backgroundColor: AppColors.primaryColor,
            title: Row(
              children: [
                const Icon(Icons.chat_bubble, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text('Message from $userName', style: const TextStyle(fontSize: 18)),
              ],
            ),
            content: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                    ),
                    // ✅ Add link actions if link exists
                    if (hasLink && link != null) _buildLinkActions(link),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
                child: const Text('Close', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          barrierDismissible: true,
        );
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
      
    // Handle follow-up notifications - SHOW NOTES
   case 'follow_up':
    case 'followup':
    case 'site_visit':
    case 'property_visit_scheduled':
    case 'property_visit_pending':
    case 'property_visited':
    case 'property_agreed':
      _handleFollowUpNavigation(data, hasLink: hasLink, link: link);
      break;

      // Handle booking notifications - SHOW BOOKING DETAILS
      case 'booking':
      case 'property_booking':
      case 'new_booking':
      case 'booking_confirmed':
        debugPrint('🎯 Booking notification detected - showing details');
        _handleBookingNavigation(data);
        break;

    case 'complaint_status_update':
case 'ticket':
case 'complaint':
case 'tenant_ticket':
case 'complaint_reply':
case 'ticket_reply':
case 'ticket_update':
case 'new_complaint':  // ✅ ADD THIS LINE
case 'new_ticket':     // ✅ ADD THIS LINE (just in case)
  // Show detailed ticket dialog
  _handleTicketNavigation(data, notification.type);
  break;

     case 'property_interest':
    case 'customer_interest':
    case 'property_enquiry':
      _handlePropertyInterestNavigation(data, hasLink: hasLink, link: link);
      break;
  }
}
// ✅ NEW: Handle ticket navigation with complete details
// ✅ UPDATED: Handle ticket navigation with image preview support
void _handleTicketNavigation(Map<String, dynamic> data, String notificationType) {
  // Extract ticket ID
  final ticketId = data['ticketId'] as String?;
  final complaintId = data['complaintId'] as String?;
  final complaintIdFromData = data['complaint_id']?.toString();
  final complaintNumber = data['complaint_number'] as String?;
  
  final finalTicketId = complaintIdFromData ?? ticketId ?? complaintId;
  final displayTicketId = complaintNumber ?? finalTicketId;
  
  // ✅ NEW: Extract image data from notification
  final imageUrl = _extractPreviewImage(data);
  final timestamp = data['timestamp'] as String?;
  final createdAt = data['createdAt'] as String?;
  final finalTimestamp = timestamp ?? createdAt;
  
  // Extract other data for dialog display
  final message = data['message'] as String?;
  final reply = data['reply'] as String?;
  final category = data['category'] as String?;
  final subCategory = data['sub_category'] as String?;
  final status = data['status'] as String?;
  final description = data['description'] as String?;
  final propertyName = data['propertyName'] as String?;
  final propertyTitle = data['property_title'] as String?;
  final unitAddress = data['unit_address'] as String?;
  final complainant = data['complainant'] as String?;
  final updatedAt = data['updatedAt'] as String?;
  final technicianName = data['technicianName'] as String?;
  final priority = data['priority'] as String?;
  
  final finalPropertyName = propertyTitle ?? propertyName;
  final finalCreatedAt = timestamp ?? createdAt;
  final finalCategory = subCategory ?? category;
  
  debugPrint('🎯 Ticket notification - showing complete details');
  debugPrint('   Ticket ID: $finalTicketId');
  debugPrint('   Display ID: $displayTicketId');
  debugPrint('   Image URL: $imageUrl');
  debugPrint('   Type: $notificationType');
  
  // Build content widgets for dialog
  List<Widget> contentWidgets = [];
  
  // Ticket ID/Number
  if (displayTicketId != null && displayTicketId.isNotEmpty) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.confirmation_number, size: 18, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ticket Number',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayTicketId,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Status and Category row
  if (status != null || finalCategory != null) {
    contentWidgets.add(
      Row(
        children: [
          if (status != null) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (status != null && finalCategory != null) const SizedBox(width: 8),
          if (finalCategory != null) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      finalCategory,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Priority
  if (priority != null && priority.isNotEmpty) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _getPriorityColor(priority),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, size: 14, color: _getPriorityIconColor(priority)),
            const SizedBox(width: 6),
            Text(
              'Priority: $priority',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getPriorityIconColor(priority),
              ),
            ),
          ],
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Complainant Name
  if (complainant != null && complainant.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.person_outline, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Complainant: $complainant',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Property Name and Unit Address
  if (finalPropertyName != null || unitAddress != null) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (finalPropertyName != null) ...[
              Row(
                children: [
                  const Icon(Icons.home, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      finalPropertyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (unitAddress != null) ...[
              if (finalPropertyName != null) const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      unitAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Technician Name
  if (technicianName != null && technicianName.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.engineering, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Assigned to: $technicianName',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Description
  if (description != null && description.isNotEmpty) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 6),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Reply
  if (reply != null && reply.isNotEmpty) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[200]!, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.reply, size: 16, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text(
                  'Technician Reply',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              reply,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Message
  if (message != null && message.isNotEmpty && message != reply && message != description) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Timestamps
  if (finalCreatedAt != null || updatedAt != null) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (finalCreatedAt != null) ...[
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Created: ${_formatTimestamp(finalCreatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
            if (updatedAt != null && updatedAt != finalCreatedAt) ...[
              if (finalCreatedAt != null) const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.update, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Updated: ${_formatTimestamp(updatedAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  // Show dialog
  Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.primaryColor,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.support_agent, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getTicketTitle(notificationType),
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: contentWidgets.isNotEmpty
                ? contentWidgets
                : [
                    const Text(
                      'Your ticket has been updated',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ],
          ),
        ),
      ),
      actions: [
        // ✅ UPDATED: View Full Ticket button with image and timestamp
        if (finalTicketId != null && finalTicketId.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              Get.back(); // Close the dialog first
              
              // ✅ Navigate with all parameters like in buildTicketCard
              Get.to(() => TicketDetailsScreen(
                complaintId: finalTicketId,
                previewImageUrl: imageUrl, // Pass the extracted image
                previewImageTimestamp: finalTimestamp, // Pass the timestamp
              ));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View Full Ticket', style: TextStyle(fontSize: 16)),
          ),
        // Close button
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Close', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}

// ✅ NEW: Helper method to extract preview image from notification data
String? _extractPreviewImage(Map<String, dynamic> data) {
  // Try different possible image field names from notification data
  final imageUrl = data['imageUrl'] as String?;
  final image = data['image'] as String?;
  final complaintImage = data['complaintImage'] as String?;
  final previewImage = data['previewImage'] as String?;
  
  // Try to get from images array
  final images = data['images'];
  if (images != null) {
    if (images is List && images.isNotEmpty) {
      return images.first as String?;
    } else if (images is Map) {
      // Handle ComplaintImages structure
      final tenantUploaded = images['tenantUploaded'] as List?;
      if (tenantUploaded != null && tenantUploaded.isNotEmpty) {
        return tenantUploaded.first as String?;
      }
      
      final adminUploaded = images['adminUploaded'] as List?;
      if (adminUploaded != null && adminUploaded.isNotEmpty) {
        return adminUploaded.first as String?;
      }
      
      final technicianUploaded = images['technicianUploaded'] as List?;
      if (technicianUploaded != null && technicianUploaded.isNotEmpty) {
        return technicianUploaded.first as String?;
      }
      
      final adminTechnicianUploaded = images['adminTechnicianUploaded'] as List?;
      if (adminTechnicianUploaded != null && adminTechnicianUploaded.isNotEmpty) {
        return adminTechnicianUploaded.first as String?;
      }
    }
  }
  
  // Return first available image URL
  final result = previewImage ?? imageUrl ?? image ?? complaintImage;
  
  debugPrint('📸 Extracted preview image: ${result ?? "none"}');
  return result;
}

// ✅ NEW: Format timestamp helper
String _formatTimestamp(String timestamp) {
  try {
    final dateTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  } catch (e) {
    return timestamp;
  }
}

// ✅ Helper: Get ticket title based on type
String _getTicketTitle(String type) {
  switch (type) {
    case 'complaint_reply':
    case 'ticket_reply':
      return 'New Reply on Ticket';
    case 'ticket_update':
    case 'complaint_status_update':
      return 'Ticket Status Updated';
    case 'complaint':
      return 'Complaint Details';
    case 'new_complaint':  // ✅ ADD THIS
      return 'New Complaint Registered';
    case 'new_ticket':  // ✅ ADD THIS
      return 'New Ticket Created';
    case 'tenant_ticket':
      return 'Support Ticket Details';
    default:
      return 'Ticket Update';
  }
}
// ✅ Helper: Get status color
Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
    case 'open':
      return Colors.orange[100]!;
    case 'in progress':
    case 'assigned':
      return Colors.blue[100]!;
    case 'resolved':
    case 'completed':
    case 'closed':
      return Colors.green[100]!;
    case 'rejected':
    case 'cancelled':
      return Colors.red[100]!;
    default:
      return Colors.grey[100]!;
  }
}

// ✅ Helper: Get priority color
Color _getPriorityColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
    case 'urgent':
      return Colors.red[100]!;
    case 'medium':
      return Colors.orange[100]!;
    case 'low':
      return Colors.green[100]!;
    default:
      return Colors.grey[100]!;
  }
}

// ✅ Helper: Get priority icon color
Color _getPriorityIconColor(String priority) {
  switch (priority.toLowerCase()) {
    case 'high':
    case 'urgent':
      return Colors.red[700]!;
    case 'medium':
      return Colors.orange[700]!;
    case 'low':
      return Colors.green[700]!;
    default:
      return Colors.grey[700]!;
  }
}

void _handlePropertyInterestNavigation(
  Map<String, dynamic> data, {
  bool hasLink = false,
  String? link,
}) {
  final message = data['message'] as String?;
  final customerName = data['customerName'] as String?;
  final customerPhone = data['customerPhone'] as String?;
  final propertyName = data['propertyName'] as String?;
  final propertyId = data['propertyId'] as String?;
  final interestType = data['interestType'] as String?;
  
  debugPrint('📞 Property interest notification tapped');
  debugPrint('   Customer: $customerName');
  debugPrint('   Property: $propertyName');
  debugPrint('   Interest Type: $interestType');
  
  // Build detailed content
  List<Widget> contentWidgets = [];
  
  // Interest Type Badge
  if (interestType != null) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: interestType == 'call' ? Colors.green[100] : Colors.blue[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              interestType == 'call' ? Icons.phone : Icons.chat,
              size: 16,
              color: interestType == 'call' ? Colors.green[700] : Colors.blue[700],
            ),
            const SizedBox(width: 4),
            Text(
              interestType == 'call' ? 'Call Interest' : 'Chat Interest',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: interestType == 'call' ? Colors.green[700] : Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 16));
  }
  
  // Customer Info
  if (customerName != null && customerName.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.person, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Phone Number
  if (customerPhone != null && customerPhone.isNotEmpty) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone, size: 20, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                customerPhone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.call, color: Colors.green),
              onPressed: () async {
                final uri = Uri.parse('tel:$customerPhone');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              tooltip: 'Call Now',
            ),
          ],
        ),
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Property Name
  if (propertyName != null && propertyName.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.home, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              propertyName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Message
  if (message != null && message.isNotEmpty) {
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
  
  // Show dialog
  Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.primaryColor,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.notification_important, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'New Property Interest',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: contentWidgets.isNotEmpty 
              ? contentWidgets 
              : [
                  const Text(
                    'A customer is interested in your property',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
          ),
        ),
      ),
      actions: [
        // Call button
        if (customerPhone != null && customerPhone.isNotEmpty)
          TextButton.icon(
            onPressed: () async {
              final uri = Uri.parse('tel:$customerPhone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Call', style: TextStyle(fontSize: 16)),
          ),
        
        // View property button
        if (propertyId != null && propertyId.isNotEmpty)
          TextButton.icon(
            onPressed: () {
              Get.back();
              Get.toNamed('/propertyDetails', arguments: {'propertyId': propertyId});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            icon: const Icon(Icons.home, size: 18),
            label: const Text('View Property', style: TextStyle(fontSize: 16)),
          ),
        
        // Close button
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Close', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}

// Follow-up notes handler
// Add this helper method to extract and validate location from notes
// ✅ UPDATED: Extract location URL from notes (supports both formats)
String? _extractLocation(String notes) {
  // Pattern 1: Look for Google Maps URL
  final urlPattern = RegExp(
    r'Location:\s*(https?://(?:www\.)?google\.com/maps[^\s\n]+)',
    multiLine: true,
  );
  final urlMatch = urlPattern.firstMatch(notes);
  
  if (urlMatch != null && urlMatch.group(1) != null) {
    final url = urlMatch.group(1)!.trim();
    debugPrint('✅ Found Google Maps URL: $url');
    return url;
  }
  
  // Pattern 2: Look for plain coordinates (format: "Location: lat,lng")
  final coordPattern = RegExp(
    r'Location:\s*(-?\d+\.?\d*),\s*(-?\d+\.?\d*)',
    multiLine: true,
  );
  final coordMatch = coordPattern.firstMatch(notes);
  
  if (coordMatch != null) {
    final lat = coordMatch.group(1);
    final lng = coordMatch.group(2);
    
    if (lat != null && lng != null && lat != '0.0' && lng != '0.0') {
      // Convert coordinates to Google Maps URL
      final url = 'https://www.google.com/maps?q=$lat,$lng';
      debugPrint('✅ Found coordinates, converted to URL: $url');
      return url;
    }
  }
  
  debugPrint('⚠️ No location found in notes');
  return null;
}

// ✅ UPDATED: Open location directly (URL or coordinates)
Future<void> _openLocationInMaps(String location) async {
  try {
    Uri uri;
    
    // Check if it's already a URL
    if (location.startsWith('http://') || location.startsWith('https://')) {
      uri = Uri.parse(location);
      debugPrint('📍 Opening URL directly: $location');
    } 
    // Check if it's coordinates (format: lat,lng)
    else {
      final coordPattern = RegExp(r'^(-?\d+\.?\d*),\s*(-?\d+\.?\d*)$');
      final coordMatch = coordPattern.firstMatch(location.trim());
      
      if (coordMatch != null) {
        final lat = coordMatch.group(1);
        final lng = coordMatch.group(2);
        uri = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
        debugPrint('📍 Opening coordinates: $lat,$lng');
      } else {
        // Treat as address text
        final encodedLocation = Uri.encodeComponent(location);
        uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedLocation');
        debugPrint('📍 Opening address: $location');
      }
    }
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      debugPrint('✅ Successfully opened location in maps');
    } else {
      throw Exception('Could not launch maps');
    }
  } catch (e) {
    debugPrint('❌ Error opening maps: $e');
    Get.snackbar(
      'Error',
      'Could not open location in maps',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// ✅ UPDATED: Copy location (URL or coordinates)
Future<void> _copyLocation(String location) async {
  try {
    await Clipboard.setData(ClipboardData(text: location));
    
    // Determine what was copied for better UX
    String copiedType = 'Location';
    if (location.startsWith('http')) {
      copiedType = 'Google Maps link';
    } else if (location.contains(',') && !location.contains(' ')) {
      copiedType = 'Coordinates';
    }
    
    Get.snackbar(
      '$copiedType Copied',
      '$copiedType copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      icon: const Icon(Icons.check_circle, color: Colors.white),
    );
    debugPrint('✅ Copied to clipboard: $location');
  } catch (e) {
    debugPrint('❌ Error copying location: $e');
    Get.snackbar(
      'Error',
      'Failed to copy location',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// ✅ UPDATED: Follow-up navigation with improved location handling
void _handleFollowUpNavigation(
  Map<String, dynamic> data, {
  bool hasLink = false,
  String? link,
}) {
  final notes = data['notes'] as String?;
  
  debugPrint('📝 Follow-up notification tapped');
  debugPrint('   Notes available: ${notes != null && notes.isNotEmpty}');
  
  if (notes != null && notes.isNotEmpty) {
    // Extract location URL from notes
    final location = _extractLocation(notes);
    
    debugPrint('   Location found: ${location != null}');
    if (location != null) {
      debugPrint('   Location value: $location');
    }
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.primaryColor,
        title: const Row(
          children: [
            Icon(Icons.event_note, color: Colors.blue, size: 24),
            SizedBox(width: 8),
            Text('Visit Notes', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Notes text
                Text(
                  notes,
                  style: const TextStyle(
                    fontSize: 16, 
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                
                // ✅ Location section (only if location URL exists)
                if (location != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 18, color: Colors.green[700]),
                            const SizedBox(width: 6),
                            Text(
                              'Site Visit Location',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Show URL preview or coordinates
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            location.startsWith('http') 
                              ? 'Google Maps Link'
                              : location,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Copy button
                            TextButton.icon(
                              onPressed: () => _copyLocation(location),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.green[700],
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              ),
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('Copy', style: TextStyle(fontSize: 13)),
                            ),
                            const SizedBox(width: 8),
                            // Open in Maps button
                            ElevatedButton.icon(
                              onPressed: () => _openLocationInMaps(location),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.map, size: 16),
                              label: const Text('Open Map', style: TextStyle(fontSize: 13)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                
                // ✅ Additional link if present (separate from location)
                if (hasLink && link != null) ...[
                  const SizedBox(height: 12),
                  _buildLinkActions(link),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('Close', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  } else {
    Get.snackbar(
      'No Notes',
      'No visit notes available for this notification',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.info_outline, color: Colors.white),
    );
  }
}
// Booking details handler
void _handleBookingNavigation(Map<String, dynamic> data) {
  
  final message = data['message'] as String?;
  final customerName = data['customerName'] as String?;
  final propertyName = data['propertyName'] as String?;
  final bookingDate = data['bookingDate'] as String?;
  final propertyId = data['propertyId'] as String?;
  final customerPhone = data['customerPhone'] as String?;
  final bookingId = data['bookingId'] as String?;
  final notes = data['notes'] as String?;
  
  debugPrint('🏠 Booking notification tapped');
  debugPrint('   Customer: $customerName');
  debugPrint('   Property: $propertyName');
  debugPrint('   Date: $bookingDate');
  
  // Build detailed content
  List<Widget> contentWidgets = [];
  
  // Customer Info
  if (customerName != null && customerName.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.person, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customerName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Phone Number
  if (customerPhone != null && customerPhone.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.phone, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            customerPhone,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Property Name
  if (propertyName != null && propertyName.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.home, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              propertyName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Booking Date
  if (bookingDate != null && bookingDate.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'Date: $bookingDate',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Booking ID
  if (bookingId != null && bookingId.isNotEmpty) {
    contentWidgets.add(
      Row(
        children: [
          const Icon(Icons.confirmation_number, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            'Booking ID: $bookingId',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
    contentWidgets.add(const SizedBox(height: 12));
  }
  
  // Message or Notes
  if ((message != null && message.isNotEmpty) || (notes != null && notes.isNotEmpty)) {
    final displayText = notes ?? message ?? '';
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          displayText,
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
  
  // Show dialog
  Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.primaryColor,
      title: const Row(
        children: [
          Icon(Icons.event_available, color: Colors.green, size: 24),
          SizedBox(width: 8),
          Text('Property Booking', style: TextStyle(fontSize: 18)),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: contentWidgets.isNotEmpty 
              ? contentWidgets 
              : [
                  const Text(
                    'You have a new property booking',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ],
          ),
        ),
      ),
      actions: [
        if (propertyId != null && propertyId.isNotEmpty)
          TextButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/propertyDetails', arguments: {'propertyId': propertyId});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('View Property', style: TextStyle(fontSize: 16)),
          ),
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
          child: const Text('Close', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}

// Add this method to NotificationController

// Add this method to NotificationController for debugging
  void debugNotificationStorage() {
    debugPrint('=== NOTIFICATION STORAGE DEBUG ===');
    debugPrint('Current User ID: $_currentUserId');
    debugPrint('Storage Current User: ${_storage.read(_currentUserKey)}');
    debugPrint('Storage Key: $_storageKey');
    debugPrint('In-memory notifications count: ${notifications.length}');

    final storedData = _storage.read(_storageKey);
    if (storedData != null) {
      try {
        final List<dynamic> jsonList = json.decode(storedData);
        debugPrint('Stored notifications count: ${jsonList.length}');
      } catch (e) {
        debugPrint('Error reading storage: $e');
      }
    } else {
      debugPrint('No stored data found at key: $_storageKey');
    }

    // Check all storage keys
    debugPrint('All storage keys: ${_storage.getKeys()}');
    debugPrint('=================================');
  }

  void debugStorage() {
    debugPrint('=== STORAGE DEBUG ===');
    debugPrint('Current user ID: $_currentUserId');
    debugPrint('Storage current user: ${_storage.read(_currentUserKey)}');
    debugPrint('Storage keys: ${_storage.getKeys()}');

    // Check user-specific storage
    if (_currentUserId != null) {
      final userKey = '$_storageKeyPrefix$_currentUserId';
      final userData = _storage.read(userKey);
      debugPrint('User notifications key: $userKey');
      debugPrint('User notifications exist: ${userData != null}');
      if (userData != null) {
        try {
          final List<dynamic> jsonList = json.decode(userData);
          debugPrint('User notifications count: ${jsonList.length}');
        } catch (e) {
          debugPrint('Error parsing user notifications: $e');
        }
      }
    }

    // Check pending buffer
    final pendingData = _storage.read('pending_notifications');
    debugPrint('Pending notifications exist: ${pendingData != null}');
    if (pendingData != null) {
      try {
        final List<dynamic> jsonList = json.decode(pendingData);
        debugPrint('Pending notifications count: ${jsonList.length}');
      } catch (e) {
        debugPrint('Error parsing pending notifications: $e');
      }
    }
    debugPrint('===================');
  }

// Helper method to parse sale status
  int _parseSaleStatus(dynamic status) {
    if (status is int) return status;
    if (status is String) {
      final intValue = int.tryParse(status);
      if (intValue != null) return intValue;

      switch (status.toLowerCase()) {
        case 'property visit pending':
          return 1;
        case 'property visit scheduled':
          return 2;
        case 'property visited':
          return 3;
        case 'property agreed':
          return 4;
        default:
          return 1;
      }
    }
    return 1;
  }
}
