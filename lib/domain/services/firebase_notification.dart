import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/core/utils/timezonehelper.dart';
import 'package:majan/data/model/notification_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:majan/domain/controller/notification_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart';
import 'package:majan/presentation/widgets/notification_detail_sheet.dart';
import 'package:majan/presentation/widgets/pdf_viewer_widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
class FirebaseNotificationService {
    final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
    final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    StreamSubscription? _authSubscription;
    StreamSubscription? _tokenRefreshSubscription;

    final GlobalKey<NavigatorState> navigatorKey;

    // Notification channels for different types
    static const String _chatChannelId = 'chat_channel';
    static const String _techChannelId = 'tech_channel';
    static const String _orderChannelId = 'order_channel';

    // Constructor that accepts the navigator key
    FirebaseNotificationService({required this.navigatorKey});
    final ApiService _apiService = Get.put(ApiService());

    // Get the notification controller
    NotificationController get _notificationController {
      if (!Get.isRegistered<NotificationController>()) {
        Get.put(NotificationController());
      }
      return Get.find<NotificationController>();
    }

    Future<void> initialize() async {
      try {
        // Initialize notification controller first
        Get.put(NotificationController());
        
        // Initialize notification infrastructure
        await _requestPermissions();
        await _initLocalNotifications();
        await _createNotificationChannels();

        // CHANGED: Get and save FCM token immediately on initialization
        // This ensures token is available even when app is closed
        await _initializeFCMToken();

        // Set up message handlers with storage
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Handle notification opened app (when app is opened from background)
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('=== NOTIFICATION OPENED APP FROM BACKGROUND ===');
          debugPrint('Message ID: ${message.messageId}');
          debugPrint('Notification data: ${message.data}');
          debugPrint('Notification title: ${message.notification?.title}');
          debugPrint('Notification body: ${message.notification?.body}');
          
          _notificationController.addNotificationFromRemoteMessage(message);
          _notificationController.markAsRead(message.messageId ?? '');
          _handleNotificationNavigation(message.data);
        });

        // Handle notification when app is terminated and opened via notification
        FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
          if (message != null) {
            debugPrint('=== APP OPENED FROM TERMINATED STATE ===');
            debugPrint('Message ID: ${message.messageId}');
            debugPrint('Notification data: ${message.data}');
            debugPrint('Notification title: ${message.notification?.title}');
            debugPrint('Notification body: ${message.notification?.body}');
            
            _notificationController.addNotificationFromRemoteMessage(message);
            _notificationController.markAsRead(message.messageId ?? '');
            
            // Wait for GetX to be fully ready
            _waitForGetXAndNavigate(message.data);
          }
        });

        // Start listening for auth state changes (for token updates)
        _setupAuthStateListener();
        
        // CHANGED: Listen for token refresh independently of auth state
        _setupTokenRefreshListener();
        
        debugPrint('Firebase notification service initialized successfully');
      } catch (e) {
        debugPrint('Error initializing Firebase notifications: $e');
      }
    }

    // NEW: Initialize FCM token on app start
    Future<void> _initializeFCMToken() async {
      try {
        final token = await _firebaseMessaging.getToken();
        if (token != null) {
          debugPrint('FCM Token obtained: $token');
          
          // Store token locally for use when offline
          final storage = GetStorage();
          storage.write('fcm_token', token);
          
          // Try to save to backend and Firestore if user is logged in
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await _saveTokenToFirestore(token, currentUser);
          } else {
            // Save token locally to be synced when user logs in
            debugPrint('No user logged in, token saved locally for later sync');
          }
        }
      } catch (e) {
        debugPrint('Error initializing FCM token: $e');
      }
    }


    // ✅ NEW: Parse payment details from notification body text
Map<String, dynamic> _parsePaymentDetailsFromBody(String body) {
  debugPrint('🔍 === PARSING PAYMENT BODY ===');
  debugPrint('Body text: $body');
  
  final Map<String, dynamic> parsedData = {};
  
  try {
    // Extract tenant name (after "Hi " and before newline)
    final tenantMatch = RegExp(r'Hi\s+([^\n]+)').firstMatch(body);
    if (tenantMatch != null) {
      parsedData['tenantName'] = tenantMatch.group(1)?.trim();
    }
    
    // Extract property name (after "Property: " and before newline)
    final propertyMatch = RegExp(r'Property:\s+([^\n]+)').firstMatch(body);
    if (propertyMatch != null) {
      parsedData['property_title'] = propertyMatch.group(1)?.trim();
    }
    
    // Extract unit number (after "Unit Number: " and before newline)
    final unitMatch = RegExp(r'Unit Number:\s+([^\n]+)').firstMatch(body);
    if (unitMatch != null) {
      parsedData['unit_number'] = unitMatch.group(1)?.trim();
    }
    
    // Extract amount (after "Amount: OMR " and before newline)
    final amountMatch = RegExp(r'Amount:\s*OMR\s+([\d,.]+)').firstMatch(body);
    if (amountMatch != null) {
      final amountStr = amountMatch.group(1)?.replaceAll(',', '');
      parsedData['amount'] = double.tryParse(amountStr ?? '0') ?? 0.0;
    }
    
    // Extract due date
    final dueDateMatch = RegExp(r'Due Date:\s+([^\n]+?)(?:\n|Payment Method|$)').firstMatch(body);
    if (dueDateMatch != null) {
      parsedData['expected_date'] = dueDateMatch.group(1)?.trim();
    }
    
    // Extract payment method and details
    final methodMatch = RegExp(r'Payment Method:\s+([^\n]+)').firstMatch(body);
    if (methodMatch != null) {
      final method = methodMatch.group(1)?.trim() ?? '';
      parsedData['payment_method'] = method;
      
      // Extract method-specific details
      if (method.toLowerCase() == 'cheque') {
        final chequeNumMatch = RegExp(r'Cheque Number:\s+([^\n]+)').firstMatch(body);
        if (chequeNumMatch != null) parsedData['cheque_number'] = chequeNumMatch.group(1)?.trim();
        
        final chequeDateMatch = RegExp(r'Cheque Date:\s+([^\n]+)').firstMatch(body);
        if (chequeDateMatch != null) parsedData['cheque_date'] = chequeDateMatch.group(1)?.trim();
        
        final bankMatch = RegExp(r'Bank:\s+([^\n]+)').firstMatch(body);
        if (bankMatch != null) parsedData['cheque_bank_name'] = bankMatch.group(1)?.trim();
      }
      // Add similar extractors for cash and transfer...
    }
    
    debugPrint('✅ Parsed payment data: $parsedData');
  } catch (e) {
    debugPrint('❌ Error parsing payment body: $e');
  }
  
  return parsedData;
}

    // NEW: Setup token refresh listener (independent of auth)
    Future<void> _setupTokenRefreshListener() async {
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM Token refreshed: $newToken');
        
        // Store token locally
        final storage = GetStorage();
        storage.write('fcm_token', newToken);
        
        // Try to save to backend and Firestore if user is logged in
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _saveTokenToFirestore(newToken, currentUser);
        }
      });
    }

    void _waitForGetXAndNavigate(Map<String, dynamic> data, {int attempts = 0}) {
      if (attempts > 10) {
        debugPrint('Max navigation attempts reached, giving up');
        return;
      }
      
      // Check if GetX context is ready
      if (Get.context != null && Get.key.currentState?.mounted == true) {
        debugPrint('GetX ready, navigating now (attempt ${attempts + 1})');
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleNotificationNavigation(data);
        });
      } else {
        debugPrint('GetX not ready yet, waiting... (attempt ${attempts + 1})');
        Future.delayed(const Duration(milliseconds: 500), () {
          _waitForGetXAndNavigate(data, attempts: attempts + 1);
        });
      }
    }

    // Handle link and PDF downloads
    Future<void> _handleLinkOrPdfAction(Map<String, dynamic> data) async {
      debugPrint('=== HANDLING LINK/PDF ACTION ===');
      
      // Check for both snake_case and camelCase variations
      final link = data['link'] as String?;
      final pdfUrl = (data['pdfUrl'] ?? data['pdf_url']) as String?;
      final fileUrl = (data['fileUrl'] ?? data['file_url']) as String?;
      final fileName = (data['fileName'] ?? data['file_name']) as String?;
      final fileType = (data['fileType'] ?? data['file_type']) as String?;
      
      debugPrint('Link: $link');
      debugPrint('PdfUrl: $pdfUrl');
      debugPrint('FileUrl: $fileUrl');
      
      // Priority: check for link, pdfUrl, or fileUrl
      final urlToHandle = link ?? pdfUrl ?? fileUrl;
      
      if (urlToHandle != null && urlToHandle.isNotEmpty) {
        debugPrint('URL to handle: $urlToHandle');
        
        // Check if it's a PDF
        final isPdf = urlToHandle.toLowerCase().endsWith('.pdf') || 
            fileType?.toLowerCase() == 'pdf' ||
            urlToHandle.toLowerCase().contains('.pdf');
        
        debugPrint('Is PDF: $isPdf');
        
        if (isPdf) {
          await _downloadAndOpenPdf(
            urlToHandle, 
            fileName ?? 'letter_${DateTime.now().millisecondsSinceEpoch}.pdf'
          );
        } else {
          // Open as regular link
          await _openUrl(urlToHandle);
        }
      } else {
        debugPrint('No valid URL found in notification data');
        // Get.snackbar(
        //   'Error',
        //   'No link or file found in this notification',
        //   snackPosition: SnackPosition.BOTTOM,
        //   backgroundColor: Colors.orange,
        //   colorText: Colors.white,
        // );
      }
    }

   // ✅ OPTIMIZED: Fast PDF download - WORKS ON BOTH iOS & ANDROID
Future<void> _downloadAndOpenPdf(String url, String fileName) async {
  try {
    debugPrint('Opening PDF viewer for: $url');
    
    // ✅ Show inline PDF viewer with download option
    Get.dialog(
      InlinePdfViewer(
        pdfUrl: url,
        title: fileName.replaceAll('.pdf', ''),
        showDownloadButton: true,
        onDownload: () async {
          await _downloadToDevice(url, fileName);
        },
      ),
      barrierDismissible: false,
    );

  } catch (e) {
    debugPrint('Error opening PDF viewer: $e');
    Get.snackbar(
      'Error',
      'Could not open PDF viewer',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}

// ✅ NEW: Separate method for downloading to device storage
Future<void> _downloadToDevice(String url, String fileName) async {
  try {
    Get.snackbar(
      'Downloading',
      'Saving PDF to Downloads...',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      showProgressIndicator: true,
      isDismissible: false,
      duration: const Duration(seconds: 2),
    );

    debugPrint('Downloading to device: $url');
    final response = await http.get(Uri.parse(url));

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
      } else {
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/$finalFileName';
      }

      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      if (Platform.isAndroid) {
        await _notifyMediaScanner(filePath);
      }

      debugPrint('PDF saved to: $filePath');

      Get.snackbar(
        'Download Complete',
        Platform.isAndroid
            ? 'File saved to Downloads\n$finalFileName'
            : 'File saved\n$finalFileName',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );
    } else {
      throw Exception('Failed to download: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error downloading to device: $e');
    Get.snackbar(
      'Download Failed',
      'Could not save file to device',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}
// ✅ ALTERNATIVE: Download with progress percentage (even faster feedback)
Future<void> _downloadAndOpenPdfWithProgress(String url, String fileName) async {
  try {
    debugPrint('Starting PDF download for: $url');
    
    // Permission checks (same as above)...
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
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
      
      if (!status.isGranted && sdkInt < 33) {
        Get.snackbar(
          'Permission Required',
          'Storage permission is needed',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }
    }

    // Prepare file path
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
    } else {
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$finalFileName';
    }

    // Show initial progress
    Get.snackbar(
      'Downloading',
      '0%',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      showProgressIndicator: true,
      isDismissible: false,
      duration: null,
    );

    // Download with progress tracking
    final client = http.Client();
    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request).timeout(
      const Duration(seconds: 30),
    );
    
    if (response.statusCode == 200) {
      final file = File(filePath);
      final sink = file.openWrite();
      
      final contentLength = response.contentLength ?? 0;
      var downloadedBytes = 0;
      
      try {
        await for (var chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          
          // Update progress every 10%
          if (contentLength > 0) {
            final progress = (downloadedBytes / contentLength * 100).toInt();
            if (progress % 10 == 0) {
              debugPrint('Download progress: $progress%');
            }
          }
        }
        
        await sink.flush();
        await sink.close();
        
        if (Platform.isAndroid) {
          await _notifyMediaScanner(filePath);
        }

        Get.closeAllSnackbars();

        Get.snackbar(
          'Download Complete',
          Platform.isAndroid 
            ? 'Saved to Downloads\n$finalFileName'
            : 'Saved successfully\n$finalFileName',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );

        // Open immediately
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done) {
          debugPrint('Could not auto-open: ${result.message}');
        }
      } finally {
        client.close();
      }
    } else {
      Get.closeAllSnackbars();
      throw Exception('Download failed: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Error: $e');
    Get.closeAllSnackbars();
    Get.snackbar(
      'Download Failed',
      'Could not download. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  }
}


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

    // Helper method to open PDF file
  Future<void> _openPdfFile(String filePath) async {
  try {
    debugPrint('Attempting to open file: $filePath');
    
    // ✅ Use open_filex for both platforms
    final result = await OpenFilex.open(filePath);
    
    debugPrint('File open result: ${result.type} - ${result.message}');
    
    if (result.type == ResultType.done) {
      debugPrint('File opened successfully');
    } else if (result.type == ResultType.noAppToOpen) {
      Get.snackbar(
        'No App Available',
        'Please install a PDF viewer app to open this file',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } else if (result.type == ResultType.fileNotFound) {
      Get.snackbar(
        'File Not Found',
        'The file could not be found. Please try downloading again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else if (result.type == ResultType.permissionDenied) {
      Get.snackbar(
        'Permission Denied',
        'Permission required to open this file',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } else {
      throw Exception('Failed to open file: ${result.message}');
    }
  } catch (e) {
    debugPrint('Error in _openPdfFile: $e');
    throw e;
  }
}

    // Open URL in browser or external app
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

    void _handleNotificationNavigation(Map<String, dynamic> data, {int retryCount = 0, String? body}) {
  debugPrint('=== NOTIFICATION TAP DETECTED ===');
  debugPrint('Attempting navigation with data: $data');
  debugPrint('Body available: ${body != null}');
  
  // Check for both snake_case and camelCase variations
  final link = data['link'] as String?;
  final pdfUrl = (data['pdfUrl'] ?? data['pdf_url']) as String?;
  final fileUrl = (data['fileUrl'] ?? data['file_url']) as String?;
  final notificationType = data['type'] as String?;
  
  final hasLink = link != null || pdfUrl != null || fileUrl != null;
  final isDocumentType = notificationType == 'letter' || 
                        notificationType == 'document' || 
                        notificationType == 'lease_renewal';
  
  debugPrint('Has link: $hasLink');
  debugPrint('Link: $link, PdfUrl: $pdfUrl, FileUrl: $fileUrl');
  debugPrint('Notification type: $notificationType');
  
  // PRIORITY: Handle PDF/document downloads first
  if (hasLink || isDocumentType) {
    debugPrint('Link/PDF detected, handling download/open');
    Future.delayed(Duration.zero, () {
      _handleLinkOrPdfAction(data);
    });
    return;
  }
  
  // Add retry limit for other navigation types
  if (retryCount > 3) {
    debugPrint('Max retries reached, giving up navigation');
    return;
  }
  
  if (Get.context != null) {
    _navigateUsingGetX(data, body: body); // ✅ PASS BODY HERE
  } else if (navigatorKey.currentContext != null) {
    _navigateUsingNavigatorKey(data);
  } else {
    debugPrint('No navigation context available, retrying in 2 seconds... (attempt $retryCount)');
    Future.delayed(const Duration(seconds: 2), () {
      _handleNotificationNavigation(data, retryCount: retryCount + 1, body: body); // ✅ PASS BODY IN RETRY
    });
  }
}

  void _navigateUsingGetX(Map<String, dynamic> data, {String? body}) {  // ✅ ADD body PARAMETER
  final notificationType = data['type'] as String?;
  debugPrint('Navigating using GetX for type: $notificationType');
  debugPrint('Body parameter: $body');
    
    try {
      // ── Unified detail sheet ──────────────────────────────────────────────
      // PDF/document types keep their own download-and-view flow below.
      // Every other type is shown in the professional NotificationDetailSheet.
      const pdfOnlyTypes = [
        'lease_renewal', 'document', 'letter',
        'custom_notice', 'pdf_notice', 'notice_pdf', 'tenant_notice',
      ];
      if (!pdfOnlyTypes.contains(notificationType)) {
        final notification = NotificationModel(
          id: 'fcm_${DateTime.now().millisecondsSinceEpoch}',
          title: data['title'] as String? ?? '',
          body: body ?? data['body'] as String? ?? '',
          type: notificationType ?? 'general',
          timestamp: DateTime.now(),
          isRead: false,
          data: data,
          imageUrl: data['imageUrl'] as String? ?? data['image_url'] as String?,
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          if (Get.isBottomSheetOpen != true) {
            NotificationDetailSheet.show(notification);
          }
        });
        return;
      }
      // ── PDF/document types continue below ─────────────────────────────────

      switch (notificationType) {

        // ✅ CHAT - Show message dialog
      case 'chat':
case 'message':
  debugPrint('💬 Chat notification detected');
  
  final message = data['message'] as String?;
  final userName = data['userName'] as String? ?? data['user_name'] as String? ?? 'User';
  final chatMessage = data['chatMessage'] as String?;
  
  final displayMessage = message ?? chatMessage;
  
  debugPrint('   User: $userName');
  debugPrint('   Message: $displayMessage');
  
  if (displayMessage != null && displayMessage.isNotEmpty) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (Get.isDialogOpen != true) {
        Get.dialog(
          Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chat_bubble,
                            color: Colors.blue.shade700,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Message from $userName',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                            letterSpacing: 0.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Container(
                    constraints: const BoxConstraints(maxHeight: 480),
                    padding: const EdgeInsets.all(24),
                    child: SingleChildScrollView(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!, width: 1.5),
                        ),
                        child: Text(
                          displayMessage,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade700,
                              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Close',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          barrierDismissible: true,
        );
      }
    });
  } else {
    debugPrint('⚠️ No message content found in chat notification');
    Get.snackbar(
      'New Message',
      'You have a new chat message',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      icon: const Icon(Icons.chat_bubble, color: Colors.white),
    );
  }
  break;

         case 'booking':
case 'property_booking':
case 'new_booking':
case 'booking_confirmed':
  final message = data['message'] as String?;
  final customerName = data['customerName'] as String?;
  final propertyName = data['propertyName'] as String?;
  final bookingDate = data['bookingDate'] as String?;
  final propertyId = data['propertyId'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event_available,
                      color: Colors.teal.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'New Property Booking',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (customerName != null) ...[
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
                        const SizedBox(height: 12),
                      ],
                      if (propertyName != null) ...[
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
                        const SizedBox(height: 12),
                      ],
                      if (bookingDate != null) ...[
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
                        const SizedBox(height: 12),
                      ],
                      if (message != null)
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        )
                      else
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (propertyId != null)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Get.toNamed('/propertyDetails', arguments: {'propertyId': propertyId});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'View Property',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (propertyId != null) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

   case 'contract_expiry':
  debugPrint('📋 Contract expiry notification detected');
  final contractId = data['contractId'] as String?;
  final propertyName = data['propertyName'] as String?;
  final expiryDate = data['expiryDate'] as String?;
  final daysUntilExpiry = data['daysUntilExpiry'];
  final urgency = data['urgency'] as String? ?? data['subType'] as String? ?? 'normal';
  
  int? days;
  if (daysUntilExpiry != null) {
    if (daysUntilExpiry is int) {
      days = daysUntilExpiry;
    } else if (daysUntilExpiry is String) {
      days = int.tryParse(daysUntilExpiry);
    }
  }
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.assignment_late,
                      color: Colors.orange.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Contract Expiry Notice',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (days != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: days <= 0 ? Colors.red : days <= 7 ? Colors.orange : Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                days <= 0 ? 'EXPIRED' : days == 1 ? 'EXPIRES TOMORROW' : 'EXPIRES IN $days DAYS',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (days != null) const SizedBox(height: 16),
                      if (propertyName != null && propertyName.isNotEmpty) ...[
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
                        const SizedBox(height: 12),
                      ],
                      if (expiryDate != null && expiryDate.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Expires: ${TimezoneHelper.formatDateOnly(expiryDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['message'] as String? ?? 
                          'Your contract is expiring soon. Please contact management to renew.',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (contractId != null && contractId.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.toNamed('/contractDetails', arguments: {'contractId': contractId});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text(
                          'View Contract',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (contractId != null && contractId.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;
case 'document_expiry':
  debugPrint('📄 Document expiry notification detected');
  final documentId = data['documentId'] as String?;
  final documentName = data['documentName'] as String?;
  final documentType = data['documentType'] as String?;
  final expiryDate = data['expiryDate'] as String?;
  final daysUntilExpiry = data['daysUntilExpiry'];
  final urgency = data['urgency'] as String? ?? data['subType'] as String? ?? 'normal';
  
  int? days;
  if (daysUntilExpiry != null) {
    if (daysUntilExpiry is int) {
      days = daysUntilExpiry;
    } else if (daysUntilExpiry is String) {
      days = int.tryParse(daysUntilExpiry);
    }
  }
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description,
                      color: Colors.blue.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Document Expiry Notice',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (days != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: days <= 0 ? Colors.red : days <= 7 ? Colors.orange : Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.warning, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                days <= 0 ? 'EXPIRED' : days == 1 ? 'EXPIRES TOMORROW' : 'EXPIRES IN $days DAYS',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (days != null) const SizedBox(height: 16),
                      if (documentName != null && documentName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.insert_drive_file, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                documentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (documentType != null && documentType.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.category, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Type: $documentType',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (expiryDate != null && expiryDate.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Expires: ${TimezoneHelper.formatDateOnly(expiryDate)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          data['message'] as String? ??
                          'Your document is expiring soon. Please renew to avoid any issues.',
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  if (documentId != null && documentId.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.toNamed('/documentDetails', arguments: {'documentId': documentId});
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility, size: 18),
                        label: const Text(
                          'View Document',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  if (documentId != null && documentId.isNotEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

// In _navigateUsingGetX method, add this case:
// ✅ REPLACE THE ENTIRE payment_reminder CASE IN firebase_notification_service.dart
// Location: Inside _navigateUsingGetX method, around line 650

case 'payment_reminder':
case 'upcoming_payment':
  debugPrint('💰 Payment reminder notification detected');
  
  // ✅ SMART DETECTION: Check if data is empty or body has payment info
  Map<String, dynamic> paymentData = Map.from(data);
  
  // If data is mostly empty but body has payment info, parse the body
  if (body != null && body.contains('Amount: OMR') && 
      (data['amount'] == null || data['property_title'] == null)) {
    debugPrint('   ✅ Data incomplete - parsing from body text');
    final parsedFromBody = _parsePaymentDetailsFromBody(body);
    // Merge parsed data with existing data (existing data takes priority)
    parsedFromBody.forEach((key, value) {
      if (!paymentData.containsKey(key) || paymentData[key] == null) {
        paymentData[key] = value;
      }
    });
  }
  
  // Extract data EXACTLY as Laravel sends it (or as parsed from body)
  final paymentId = paymentData['paymentId'] as String?;
  final amount = paymentData['amount']; // Can be string or number
  final propertyName = paymentData['property_title'] as String?;
  final unitNumber = paymentData['unit_number'] as String?;
  final tenantName = paymentData['tenantName'] as String?; // ✅ From body parsing
  final installmentNumber = paymentData['installment_number'];
  final paymentMethod = paymentData['payment_method'] as String?;
  
  // Payment method specific dates
  final cashPaymentDate = paymentData['cash_payment_date'] as String?;
  final chequeDate = paymentData['cheque_date'] as String?;
  final transferDate = paymentData['transfer_date'] as String?;
  final otherpaymentdate = paymentData['otherpaymentdate'] as String?;
  final expectedDate = paymentData['expected_date'] as String?;
  
  // Additional payment details
  final chequeNumber = paymentData['cheque_number'] as String?;
  final chequeBankName = paymentData['cheque_bank_name'] as String?;
  final receiptNumber = paymentData['receipt_number'] as String?;
  final transactionReference = paymentData['transaction_reference'] as String?;
  final transferBankName = paymentData['transfer_bank_name'] as String?;
  final paymentReference = paymentData['payment_reference'] as String?;
  final paymentDescription = paymentData['payment_description'] as String?;
  
  // Calculate effective due date - SAME PRIORITY AS LARAVEL
  final dueDate = expectedDate ?? chequeDate ?? transferDate ?? cashPaymentDate ?? otherpaymentdate;
  
  // Calculate days until due
  int? daysUntilDue;
  String urgency = 'normal';
  if (dueDate != null) {
    try {
      final due = DateTime.parse(dueDate);
      final now = DateTime.now();
      daysUntilDue = due.difference(now).inDays;
      
      // Calculate urgency SAME AS LARAVEL
      if (daysUntilDue < 0) {
        urgency = 'overdue';
      } else if (daysUntilDue <= 1) {
        urgency = 'critical';
      } else if (daysUntilDue <= 3) {
        urgency = 'urgent';
      } else if (daysUntilDue <= 7) {
        urgency = 'high';
      }
    } catch (e) {
      debugPrint('Error parsing due date: $e');
    }
  }
  
  // Parse amount
  double? parsedAmount;
  if (amount != null) {
    if (amount is num) {
      parsedAmount = amount.toDouble();
    } else if (amount is String) {
      parsedAmount = double.tryParse(amount);
    }
  }
  
  debugPrint('   Final payment data summary:');
  debugPrint('      Tenant: $tenantName');
  debugPrint('      Amount: $parsedAmount');
  debugPrint('      Property: $propertyName');
  debugPrint('      Unit: $unitNumber');
  debugPrint('      Method: $paymentMethod');
  debugPrint('      Due: $dueDate');
  debugPrint('      Urgency: $urgency');
  
  Get.dialog(
    AlertDialog(
      backgroundColor: AppColors.splashBackgroundColor,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getUrgencyColor(urgency),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payment,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Payment Reminder',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ✅ Tenant greeting (from body parsing)
              if (tenantName != null && tenantName.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hi $tenantName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Urgency badge
              if (daysUntilDue != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getUrgencyColor(urgency),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        daysUntilDue < 0
                            ? 'OVERDUE'
                            : daysUntilDue == 0
                                ? 'DUE TODAY'
                                : daysUntilDue == 1
                                    ? 'DUE TOMORROW'
                                    : 'DUE IN $daysUntilDue DAYS',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              // Amount Due
              if (parsedAmount != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[50]!, Colors.green[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amount Due',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'OMR ${parsedAmount.toStringAsFixed(3)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              
              // Property info
              if (propertyName != null || unitNumber != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (propertyName != null && propertyName.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.home, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                propertyName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (unitNumber != null && unitNumber.toString().isNotEmpty) ...[
                        if (propertyName != null) const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.apartment, size: 18, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Unit Number: $unitNumber',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Installment number
              if (installmentNumber != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.numbers, size: 18, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Installment: $installmentNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Payment Method Details - EXACTLY AS LARAVEL FORMATS IT
              if (paymentMethod != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.payment, size: 18, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Method: ${paymentMethod.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange[900],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // CHEQUE DETAILS
                      if (paymentMethod.toLowerCase() == 'cheque') ...[
                        if (chequeNumber != null && chequeNumber.isNotEmpty) ...[
                          Text(
                            'Cheque #: $chequeNumber',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (chequeDate != null && chequeDate.isNotEmpty) ...[
                          Text(
                            'Cheque Date: ${_formatDate(chequeDate)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (chequeBankName != null && chequeBankName.isNotEmpty) ...[
                          Text(
                            'Bank: $chequeBankName',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ],
                      
                      // CASH DETAILS
                      if (paymentMethod.toLowerCase() == 'cash') ...[
                        if (cashPaymentDate != null && cashPaymentDate.isNotEmpty) ...[
                          Text(
                            'Cash Date: ${_formatDate(cashPaymentDate)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (receiptNumber != null && receiptNumber.isNotEmpty) ...[
                          Text(
                            'Receipt #: $receiptNumber',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ],
                      
                      // BANK TRANSFER DETAILS
                      if (paymentMethod.toLowerCase() == 'bank transfer') ...[
                        if (transactionReference != null && transactionReference.isNotEmpty) ...[
                          Text(
                            'Reference: $transactionReference',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (transferDate != null && transferDate.isNotEmpty) ...[
                          Text(
                            'Transfer Date: ${_formatDate(transferDate)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (transferBankName != null && transferBankName.isNotEmpty) ...[
                          Text(
                            'Bank: $transferBankName',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ],
                      
                      // OTHER PAYMENT DETAILS
                      if (paymentMethod.toLowerCase() == 'other') ...[
                        if (paymentReference != null && paymentReference.isNotEmpty) ...[
                          Text(
                            'Reference: $paymentReference',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (otherpaymentdate != null && otherpaymentdate.isNotEmpty) ...[
                          Text(
                            'Payment Date: ${_formatDate(otherpaymentdate)}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Due date (effective date - SAME PRIORITY AS LARAVEL)
             if (dueDate != null && dueDate.isNotEmpty) ...[
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.red[50],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(Icons.calendar_today, size: 18, color: Colors.red[700]),
        const SizedBox(width: 8),
        Text(
          'Due: ${TimezoneHelper.formatDateOnly(dueDate)}', // ✅ CHANGED
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.red[900],
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 12),
],
              
              // Payment description if available
              if (paymentDescription != null && paymentDescription.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    paymentDescription,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Please ensure timely payment to avoid any late fees or administrative holds.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        if (paymentId != null && paymentId.isNotEmpty)
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              // Navigate to payment screen if you have one
              // Get.toNamed('/makePayment', arguments: {'paymentId': paymentId});
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.payment, size: 18),
            label: const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        TextButton(
          onPressed: () => Get.back(),
          style: TextButton.styleFrom(foregroundColor: Colors.grey),
          child: const Text('Later', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
    barrierDismissible: true,
  );
  break;
 

        // ✅ FOLLOW-UP - Show notes dialog (KEEP AS IS - WORKING)
     // Replace the follow-up case in _navigateUsingGetX method (around line 950)

case 'follow_up':
case 'followup':
case 'site_visit':
case 'property_visit_scheduled':
case 'property_visit_pending':
case 'property_visited':
case 'property_agreed':
  debugPrint('🎯 Follow-up notification - showing notes with location');
  final notes = data['notes'] as String?;
  
  if (notes != null && notes.isNotEmpty) {
    // Extract location AND phone number from notes
    final location = _extractLocation(notes);
    final phoneNumber = _extractPhoneNumber(notes);  // ✅ ADD THIS
    
    debugPrint('   Notes available: true');
    debugPrint('   Location found: ${location != null}');
    debugPrint('   Phone number found: ${phoneNumber != null}');  // ✅ ADD THIS
    
    if (location != null) {
      debugPrint('   Location value: $location');
    }
    if (phoneNumber != null) {  // ✅ ADD THIS
      debugPrint('   Phone value: $phoneNumber');
    }
    
    // Split notes into parts
    String mainNotes = notes;
    
    // Remove location line
    if (location != null) {
      final locationLinePattern = RegExp(
        r'Location:\s*[^\n]*',
        multiLine: true,
      );
      mainNotes = mainNotes.replaceAll(locationLinePattern, '').trim();
    }
    
    // ✅ NEW: Remove phone line
    if (phoneNumber != null) {
      final phoneLinePattern = RegExp(
        r'(?:Phone|Mobile|Contact|Tel|Call):\s*[^\n]*',
        caseSensitive: false,
        multiLine: true,
      );
      mainNotes = mainNotes.replaceAll(phoneLinePattern, '').trim();
    }
    
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.splashBackgroundColor,
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
                // Main notes text
                Text(
                  mainNotes,
                  style: const TextStyle(
                    fontSize: 16, 
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                
                // ✅ NEW: Phone number section (if exists)
                if (phoneNumber != null) ...[
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      try {
                        final uri = Uri.parse('tel:$phoneNumber');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                          debugPrint('✅ Opened call dialer for: $phoneNumber');
                        } else {
                          throw Exception('Cannot launch phone dialer');
                        }
                      } catch (e) {
                        debugPrint('❌ Error opening call dialer: $e');
                        Get.snackbar(
                          'Error',
                          'Cannot open phone dialer',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[300]!, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.phone, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Contact Number',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phoneNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.call, color: Colors.blue, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to call',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                
                // ✅ Location section (only if location exists)
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
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
  break;

        // ✅ TECHNICIAN ASSIGNMENT - Show details dialog
        case 'technician_assignment':
case 'technician_ticket':
case 'job_update':
  final message = data['message'] as String?;
  final ticketId = data['ticketId'] as String?;
  final jobDetails = data['jobDetails'] as String?;
  final assignedBy = data['assignedBy'] as String?;
  
  final content = message ?? jobDetails ?? 'You have a new assignment';
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.work,
                      color: Colors.orange.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'New Assignment',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ticketId != null) ...[
                        Text(
                          'Ticket ID: $ticketId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (assignedBy != null) ...[
                        Text(
                          'Assigned by: $assignedBy',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

        // ✅ TICKET/COMPLAINT - Show reply/update (KEEP AS IS - WORKING)
     case 'ticket':
case 'complaint':
case 'tenant_ticket':
case 'complaint_reply':
case 'ticket_reply':
case 'ticket_update':
case 'complaint_status_update':
case 'new_complaint':  // ✅ ADD THIS LINE
case 'new_ticket':     // ✅ ADD THIS LINE
  // Show detailed ticket dialog
  _showDetailedTicketDialog(data, notificationType);
  break;

        // ✅ PROPERTY - Show property details dialog
case 'property':
case 'property_update':
case 'tenant_property':
  final message = data['message'] as String?;
  final propertyName = data['propertyName'] as String?;
  final propertyId = data['propertyId'] as String?;
  final updateType = data['updateType'] as String?;
  
  final content = message ?? 'Property information has been updated';
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.home,
                      color: Colors.purple.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Property Update',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (propertyName != null) ...[
                        Text(
                          propertyName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (propertyId != null) ...[
                        Text(
                          'Property ID: $propertyId',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (updateType != null) ...[
                        Text(
                          'Update Type: $updateType',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

        // ✅ DOCUMENTS - Show document notification dialog
       case 'tenant_documents':
  final message = data['message'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.description,
                      color: Colors.teal.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Documents Update',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Text(
                    message ?? 'Your documents have been updated',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;


        // ✅ COMPLAINT REGISTRATION - Show dialog
       case 'tenant_complaint':
case 'complaint':
  final message = data['message'] as String?;
  final complaintId = data['complaintId'] as String?;
  final category = data['category'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.report_problem,
                      color: Colors.red.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Complaint Received',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (complaintId != null) ...[
                        Text(
                          'Complaint ID: $complaintId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'A new complaint has been received',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;
        // ✅ TECHNICIAN RECTIFY - Show details dialog
        case 'technician_rectify':
  final message = data['message'] as String?;
  final ticketId = data['ticketId'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.build,
                      color: Colors.orange.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Rectification Required',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ticketId != null) ...[
                        Text(
                          'Ticket ID: $ticketId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'Rectification work has been assigned to you',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

        // ✅ ENQUIRY - Show enquiry dialog
       case 'enquiry':
case 'customer_enquiry':
  final message = data['message'] as String?;
  final customerName = data['customerName'] as String?;
  final contactNumber = data['contactNumber'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.question_answer,
                      color: Colors.indigo.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'New Enquiry',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (customerName != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.person, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (contactNumber != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              contactNumber,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'You have received a new enquiry',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;


        // ✅ APPROVAL PENDING - Show dialog
      case 'approval_pending':
  final message = data['message'] as String?;
  final itemType = data['itemType'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pending_actions,
                      color: Colors.amber.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Approval Pending',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (itemType != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            itemType,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'An item is pending your approval',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

        // ✅ PDF/DOCUMENT DOWNLOADS - KEEP AS IS (WORKING)
        case 'lease_renewal':
        case 'document':
        case 'letter':
          debugPrint('Document notification - triggering download');
          _handleLinkOrPdfAction(data);
          break;

        // ✅ OTHER TYPES - Show generic dialog
        case 'profile':
        case 'technician_profile':
        case 'property_listing':
        case 'inbox':
        case 'search':
        case 'user_details':
          final message = data['message'] as String?;
          
          Get.dialog(
            AlertDialog(
              backgroundColor:  AppColors.splashBackgroundColor,
              title: const Row(
                children: [
                  Icon(Icons.notifications, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text('Notification', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Text(
                    message ?? 'You have a new notification',
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
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
          break;
         case 'property_interest':
case 'customer_interest':
case 'property_enquiry':
  final message = data['message'] as String?;
  final customerName = data['customerName'] as String?;
  final propertyName = data['propertyName'] as String?;
  final contactNumber = data['contactNumber'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person_add,
                      color: Colors.green.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'New Property Interest',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (customerName != null) ...[
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
                        const SizedBox(height: 12),
                      ],
                      if (propertyName != null) ...[
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
                        const SizedBox(height: 12),
                      ],
                      if (contactNumber != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              contactNumber,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'A customer has shown interest in your property',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

  

  case 'custom_notice':
case 'pdf_notice':
case 'notice_pdf':
case 'tenant_notice':
  debugPrint('📄 Custom PDF notice notification detected');
  final subject = data['subject'] as String?;
  final message = data['message'] as String?;
  final pdfUrl = (data['pdfUrl'] ?? data['pdf_url'] ?? data['link']) as String?;
  final fileName = (data['fileName'] ?? data['file_name']) as String?;
  
  if (pdfUrl != null && pdfUrl.isNotEmpty) {
    // Build content widgets
    List<Widget> contentWidgets = [];
    
    // Subject
    if (subject != null && subject.isNotEmpty) {
      contentWidgets.add(
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.subject, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subject,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[900],
                  ),
                ),
              ),
            ],
          ),
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            message,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ),
      );
      contentWidgets.add(const SizedBox(height: 16));
    }
    
    // PDF Info Card
    contentWidgets.add(
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[50]!, Colors.red[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red[300]!, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PDF Document',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fileName ?? 'Official Notice.pdf',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    
    // Show dialog with PDF viewer option
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.splashBackgroundColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notification_important, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Official Notice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 400, maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: contentWidgets,
            ),
          ),
        ),
        actions: [
          // View PDF inline button
          ElevatedButton.icon(
            onPressed: () {
              Get.back(); // Close notification dialog
              
              // Show inline PDF viewer
              Get.dialog(
                InlinePdfViewer(
                  pdfUrl: pdfUrl,
                  title: subject ?? fileName ?? 'Official Notice',
                ),
                barrierDismissible: false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 2,
            ),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          
          // Download button
          TextButton.icon(
            onPressed: () async {
              Get.back();
              await _downloadAndOpenPdf(pdfUrl, fileName ?? 'notice.pdf');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download', style: TextStyle(fontSize: 16)),
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
  } else {
    Get.snackbar(
      'No PDF Found',
      'This notification does not contain a PDF file',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      icon: const Icon(Icons.warning, color: Colors.white),
    );
  }
  break;



        // ✅ UNKNOWN - Show generic notification
       default:
  debugPrint('Unknown notification type: $notificationType');
  final message = data['message'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.info,
                      color: Colors.grey.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Notification',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Text(
                    message ?? 'You have a new notification',
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

          
      }
    } catch (e) {
      debugPrint('Error handling notification: $e');
      Get.snackbar(
        'Error',
        'Could not display notification',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

// ✅ NEW: Extract phone number from notes
String? _extractPhoneNumber(String notes) {
  // Pattern to match phone numbers in various formats
  final phonePatterns = [
    RegExp(r'(?:Phone|Mobile|Contact|Tel|Call):\s*(\+?\d[\d\s\-\(\)]{7,})', caseSensitive: false, multiLine: true),
    RegExp(r'(\+971\s?\d{1,2}\s?\d{3}\s?\d{4})', multiLine: true),
    RegExp(r'(971\s?\d{1,2}\s?\d{3}\s?\d{4})', multiLine: true),
    RegExp(r'(05\d\s?\d{3}\s?\d{4})', multiLine: true),
  ];
  
  for (var pattern in phonePatterns) {
    final match = pattern.firstMatch(notes);
    if (match != null && match.group(1) != null) {
      final phone = match.group(1)!.replaceAll(RegExp(r'[\s\-\(\)]'), '');
      debugPrint('✅ Found phone number: $phone');
      return phone;
    }
  }
  
  debugPrint('⚠️ No phone number found in notes');
  return null;
}

  // ✅ NEW: Extract preview image URL from notification data
  String? _extractPreviewImage(Map<String, dynamic> data) {
    // Check for image in various field names
    final imageUrl = (data['imageUrl'] ?? data['image_url'] ?? data['image'] ?? data['preview']) as String?;
    
    if (imageUrl != null && imageUrl.isNotEmpty) {
      debugPrint('✅ Preview image found: $imageUrl');
      return imageUrl;
    }
    
    debugPrint('⚠️ No preview image found in notification data');
    return null;
  }

  // ============================================
  // 2. Update _navigateUsingNavigatorKey method
  // ============================================
  void _navigateUsingNavigatorKey(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('Navigation context is null');
      return;
    }

    final notificationType = data['type'] as String?;
    debugPrint('Navigating using Navigator key for type: $notificationType');
    
    try {
      switch (notificationType) {
        case 'chat':
        case 'message':
          Navigator.of(context).pushNamed('/agent', arguments: data);
          break;

        // ✅ NEW: Handle follow-up notifications
       case 'follow_up':
case 'follow_up_reminder':
case 'site_visit':
  final message = data['message'] as String?;
  final propertyName = data['propertyName'] as String?;
  final visitDate = data['visitDate'] as String?;
  final visitTime = data['visitTime'] as String?;
  final location = data['location'] as String?;
  final contactNumber = data['contactNumber'] as String?;
  
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.event,
                      color: Colors.purple.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Follow-up Reminder',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (propertyName != null && propertyName.isNotEmpty) ...[
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
                        const SizedBox(height: 12),
                      ],
                      if (visitDate != null && visitDate.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Date: $visitDate',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (visitTime != null && visitTime.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              'Time: $visitTime',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (location != null && location.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (contactNumber != null && contactNumber.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              contactNumber,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (message != null && message.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple[50],
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
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
  break;

        case 'technician_assignment':
        case 'technician_ticket':
        case 'job_update':
          Navigator.of(context).pushNamed('/technician-tickets', arguments: data);
          break;

        case 'ticket':
        case 'complaint':
        case 'tenant_ticket':
        case 'complaint_reply':
        case 'ticket_reply':
        case 'ticket_update':
          final ticketId = data['ticketId'] as String?;
          final complaintId = data['complaintId'] as String?;
          
          Navigator.of(context).pushNamed('/tenantTicketsList', arguments: {
            'ticketId': ticketId ?? complaintId,
            'highlightTicket': true,
            'openTicket': true,
          });
          break;

        case 'property':
        case 'property_update':
          Navigator.of(context).pushNamed('/propertyDetails', arguments: data);
          break;

        case 'tenant_property':
          Navigator.of(context).pushNamed('/tenantPropertyList', arguments: data);
          break;

        case 'tenant_documents':
          Navigator.of(context).pushNamed('/tenantDocumentsList', arguments: data);
          break;

        case 'tenant_complaint':
          Navigator.of(context).pushNamed('/tenantComplaintReg', arguments: data);
          break;

        case 'technician_rectify':
          Navigator.of(context).pushNamed('/technician-rectify-ticket', arguments: data);
          break;

        case 'profile':
        case 'technician_profile':
          Navigator.of(context).pushNamed('/technician-profile', arguments: data);
          break;

        case 'enquiry':
        case 'customer_enquiry':
          Navigator.of(context).pushNamed('/enquiry', arguments: data);
          break;

        case 'property_listing':
          Navigator.of(context).pushNamed('/propertyListing', arguments: data);
          break;

        case 'inbox':
          Navigator.of(context).pushNamed('/inbox', arguments: data);
          break;

        case 'search':
          Navigator.of(context).pushNamed('/search', arguments: data);
          break;

        case 'user_details':
          Navigator.of(context).pushNamed('/userDetailsSubmission', arguments: data);
          break;

        case 'approval_pending':
          Navigator.of(context).pushNamed('/approvalPendingPage', arguments: data);
          break;

        case 'lease_renewal':
        case 'document':
        case 'letter':
          _handleLinkOrPdfAction(data);
          break;

        default:
          Navigator.of(context).pushNamedAndRemoveUntil('/navbar', (route) => false);
          break;
      }
    } catch (e) {
      debugPrint('Error navigating with Navigator key: $e');
      Navigator.of(context).pushNamedAndRemoveUntil('/navbar', (route) => false);
    }
  }

  int _parseSaleStatusFromNotification(dynamic status) {
    if (status is int) return status;
    if (status is String) {
      // Try to parse as number first
      final intValue = int.tryParse(status);
      if (intValue != null) return intValue;
      
      // If not a number, map text to number
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
    return 1; // Default to pending
  }

  // ✅ NEW: Show detailed ticket dialog
void _showDetailedTicketDialog(Map<String, dynamic> data, String? notificationType) {
  // Extract all data
  final ticketId = data['ticketId'] as String?;
  final complaintId = data['complaintId'] as String?;
  final complaintIdFromData = data['complaint_id']?.toString();
  final complaintNumber = data['complaint_number'] as String?;
  
  final finalTicketId = complaintIdFromData ?? ticketId ?? complaintId;
  final displayTicketId = complaintNumber ?? finalTicketId;
  
  // ✅ FIX: Extract image URL from all possible sources
  String? imageUrl;
  
  // Priority 1: Direct image_url field
  imageUrl = data['image_url'] as String?;
  
  // Priority 2: imageUrl field
  imageUrl ??= data['imageUrl'] as String?;
  
  // Priority 3: original_complaint_images (take first)
  if (imageUrl == null && data['original_complaint_images'] != null) {
    final images = data['original_complaint_images'];
    if (images is List && images.isNotEmpty) {
      imageUrl = images.first?.toString();
    } else if (images is String && images.isNotEmpty) {
      imageUrl = images.split(',').first.trim();
    }
  }
  
  // Priority 4: Try _extractPreviewImage helper
  imageUrl ??= _extractPreviewImage(data);
  
  debugPrint('🖼️ Image URL extraction debug:');
  debugPrint('   - data["image_url"]: ${data['image_url']}');
  debugPrint('   - data["imageUrl"]: ${data['imageUrl']}');
  debugPrint('   - data["original_complaint_images"]: ${data['original_complaint_images']}');
  debugPrint('   - Final imageUrl: $imageUrl');
  
  final timestamp = data['timestamp'] as String?;
  final createdAt = data['createdAt'] as String?;
  final finalTimestamp = timestamp ?? createdAt;
  
  final message = data['message'] as String?;
  final reply = data['reply'] as String?;
  final category = data['category'] as String?;
  final subCategory = data['sub_category'] as String?;
  final status = data['status'] as String?;
  final statusText = data['status_text'] as String?;
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
  final finalStatus = statusText ?? status;
  
  debugPrint('🎯 Ticket notification - showing beautiful message dialog');
  
  // Build message content as TextSpans for rich formatting
  final List<TextSpan> messageSpans = [];
  
  // Ticket number
  if (displayTicketId != null && displayTicketId.isNotEmpty) {
    messageSpans.add(const TextSpan(text: '🎫 '));
    messageSpans.add(TextSpan(
      text: 'Ticket $displayTicketId',
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ));
    messageSpans.add(const TextSpan(text: '\n\n'));
  }
  
  // Status and Category
  if (finalStatus != null || finalCategory != null) {
    if (finalStatus != null) {
      messageSpans.add(const TextSpan(text: '📊 Status: '));
      messageSpans.add(TextSpan(
        text: finalStatus,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      messageSpans.add(const TextSpan(text: '\n'));
    }
    if (finalCategory != null) {
      messageSpans.add(const TextSpan(text: '📂 Category: '));
      messageSpans.add(TextSpan(
        text: finalCategory,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      messageSpans.add(const TextSpan(text: '\n'));
    }
    messageSpans.add(const TextSpan(text: '\n'));
  }
  
  // Priority
  if (priority != null && priority.isNotEmpty) {
    String priorityEmoji = priority.toLowerCase() == 'high' || priority.toLowerCase() == 'urgent' 
        ? '🔴' : priority.toLowerCase() == 'medium' ? '🟡' : '🟢';
    messageSpans.add(TextSpan(text: '$priorityEmoji Priority: '));
    messageSpans.add(TextSpan(
      text: priority,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ));
    messageSpans.add(const TextSpan(text: '\n\n'));
  }
  
  // Property details
  if (finalPropertyName != null) {
    messageSpans.add(const TextSpan(text: '🏠 '));
    messageSpans.add(TextSpan(
      text: finalPropertyName,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ));
    messageSpans.add(const TextSpan(text: '\n'));
  }
  if (unitAddress != null) {
    messageSpans.add(TextSpan(text: '📍 $unitAddress\n'));
  }
  if (finalPropertyName != null || unitAddress != null) {
    messageSpans.add(const TextSpan(text: '\n'));
  }
  
  // Complainant
  if (complainant != null && complainant.isNotEmpty) {
    messageSpans.add(TextSpan(text: '👤 Reported by: $complainant\n\n'));
  }
  
  // Description
  if (description != null && description.isNotEmpty) {
    messageSpans.add(const TextSpan(
      text: '📝 Issue Description:\n',
      style: TextStyle(fontWeight: FontWeight.bold),
    ));
    messageSpans.add(TextSpan(text: '$description\n\n'));
  }
  
  // Technician reply
  if (reply != null && reply.isNotEmpty) {
    messageSpans.add(const TextSpan(
      text: '💬 Technician Reply:\n',
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
    ));
    messageSpans.add(TextSpan(text: '$reply\n\n'));
  }
  
  // Technician assigned
  if (technicianName != null && technicianName.isNotEmpty) {
    messageSpans.add(TextSpan(text: '👨‍🔧 Assigned to: $technicianName\n\n'));
  }
  
  // Additional message
  if (message != null && message.isNotEmpty && message != reply && message != description) {
    messageSpans.add(TextSpan(text: '📢 $message\n\n'));
  }
  
  // Timestamps
  if (finalCreatedAt != null) {
    messageSpans.add(const TextSpan(text: '🕐 Created: '));
    messageSpans.add(TextSpan(
      text: TimezoneHelper.formatNotificationTime(finalCreatedAt),
      style: TextStyle(color: Colors.grey[700]),
    ));
  }
  if (updatedAt != null && updatedAt != finalCreatedAt) {
    if (finalCreatedAt != null) messageSpans.add(const TextSpan(text: '\n'));
    messageSpans.add(const TextSpan(text: '🔄 Updated: '));
    messageSpans.add(TextSpan(
      text: TimezoneHelper.formatNotificationTime(updatedAt),
      style: TextStyle(color: Colors.grey[700]),
    ));
  }
  
  // ✅ Show dialog with WHITE BACKGROUND
  Get.dialog(
    Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ WHITE header with green icon
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.support_agent,
                      color: Colors.green.shade700,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _getTicketTitle(notificationType ?? 'ticket'),
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // ✅ Message bubble with light gray background
            Container(
              constraints: const BoxConstraints(maxHeight: 480),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!, width: 1.5),
                  ),
                  child: messageSpans.isNotEmpty
                      ? SelectableText.rich(
                          TextSpan(
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: Colors.black87,
                            ),
                            children: messageSpans,
                          ),
                        )
                      : const SelectableText(
                          '📬 Your ticket has been updated',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Colors.black87,
                          ),
                        ),
                ),
              ),
            ),
            
            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  // View Full Ticket button
                  if (finalTicketId != null && finalTicketId.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          debugPrint('🔄 Navigating to ticket details:');
                          debugPrint('   - Ticket ID: $finalTicketId');
                          debugPrint('   - Image URL: $imageUrl');
                          debugPrint('   - Timestamp: $finalTimestamp');
                          
                          Get.back();
                          Get.to(() => TicketDetailsScreen(
                            complaintId: finalTicketId,
                            previewImageUrl: imageUrl,
                            previewImageTimestamp: finalTimestamp,
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_rounded, size: 20),
                        label: const Text(
                          'View Ticket',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  
                  if (finalTicketId != null && finalTicketId.isNotEmpty)
                    const SizedBox(width: 12),
                  
                  // Close button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    barrierDismissible: true,
  );
}

// Helper: Get ticket title based on type
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
    case 'new_complaint':
      return 'New Complaint Registered';
    case 'new_ticket':
      return 'New Ticket Created';
    case 'tenant_ticket':
      return 'Support Ticket Details';
    default:
      return 'Ticket Update';
  }
}

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
    Future<void> _createNotificationChannels() async {
      const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
        _chatChannelId,
        'Chat Notifications',
        description: 'Incoming chat messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel techChannel = AndroidNotificationChannel(
        _techChannelId,
        'Technician Notifications',
        description: 'Notifications for technician assignments and updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
        _orderChannelId,
        'Order Updates',
        description: 'Notifications about order status changes',
        importance: Importance.defaultImportance,
        playSound: true,
      );

      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(chatChannel);
      await androidPlugin?.createNotificationChannel(techChannel);
      await androidPlugin?.createNotificationChannel(orderChannel);
    }

    void _setupAuthStateListener() {
      _authSubscription?.cancel();
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _handleAuthStateChange(user);
        } else {
          // CHANGED: Don't delete token when user logs out
          // Keep it for receiving notifications when app is closed
          debugPrint('User logged out, but keeping FCM token for notifications');
        }
      });
    }

    Future<void> _handleAuthStateChange(User user) async {
      // CHANGED: Don't clean up token, just sync it
      await _syncTokenForUser(user);
    }

    // NEW: Sync token for logged-in user
    Future<void> _syncTokenForUser(User user) async {
      try {
        final storage = GetStorage();
        final storedToken = storage.read('fcm_token') as String?;
        
        if (storedToken != null) {
          // Sync stored token with Firestore
          await _saveTokenToFirestore(storedToken, user);
        } else {
          // Get fresh token
          final token = await _firebaseMessaging.getToken();
          if (token != null) {
            storage.write('fcm_token', token);
            await _saveTokenToFirestore(token, user);
          }
        }
      } catch (e) {
        debugPrint('Error syncing token for user: $e');
      }
    }

    Future<void> _setupTokenManagement(User user) async {
      _tokenRefreshSubscription?.cancel();
      await _forceTokenRefresh(user);
      _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken, user);
      });
    }

    Future<void> _forceTokenRefresh(User user) async {
      try {
        await _firebaseMessaging.deleteToken();
        final token = await _firebaseMessaging.getToken();
        await _saveTokenToFirestore(token, user);
      } catch (e) {
        debugPrint('Error forcing token refresh: $e');
      }
    }

    // CHANGED: Removed token cleanup to keep receiving notifications
    Future<void> _cleanupToken() async {
      // Don't delete token anymore - keep it for notifications
      debugPrint('Token cleanup skipped to maintain notification capability');
    }

  Future<void> _saveTokenToFirestore(String? token, User user) async {
    if (token == null) return;
    try {
      final response = await _apiService.getFCMtokenforagent(token, user.uid);
      debugPrint('FCM token saved to backend: $response');
      
      // ✅ Check agent first, then technician, then default to users
      final isAgent = await _isUserAgent(user.uid);
      final isTechnician = isAgent ? false : await _isUserTechnician(user.uid);
      
      String collectionName = 'users';
      if (isAgent) {
        collectionName = 'agents';
      } else if (isTechnician) {
        collectionName = 'technicians';
      }
      
      await FirebaseFirestore.instance.collection(collectionName).doc(user.uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ Token saved to $collectionName/${user.uid}');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  // Add this helper method
  Future<bool> _isUserAgent(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('agents').doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

    Future<bool> _isUserTechnician(String uid) async {
      try {
        final doc = await FirebaseFirestore.instance.collection('technicians').doc(uid).get();
        return doc.exists;
      } catch (e) {
        return false;
      }
    }

    Future<void> _requestPermissions() async {
      try {
        await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );
      } catch (e) {
        debugPrint('Error requesting notification permissions: $e');
      }
    }

    Future<void> _initLocalNotifications() async {
      try {
        const AndroidInitializationSettings androidSettings =
            AndroidInitializationSettings('@mipmap/launcher_icon');
        const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
        const InitializationSettings settings = InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        );

        await _flutterLocalNotificationsPlugin.initialize(
          settings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('Local notification tapped: ${response.payload}');
            _handleNotificationTap(response.payload);
          },
        );
      } catch (e) {
        debugPrint('Error initializing local notifications: $e');
      }
    }

    void _handleNotificationTap(String? payload) {
      debugPrint('=== LOCAL NOTIFICATION TAPPED ===');
      debugPrint('Payload: $payload');
      
      if (payload == null) {
        debugPrint('Payload is null, cannot handle tap');
        return;
      }
      
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        debugPrint('Decoded data: $data');
        
        // Check if this is a PDF/document notification
        final link = data['link'] as String?;
        final pdfUrl = (data['pdfUrl'] ?? data['pdf_url']) as String?;
        final fileUrl = (data['fileUrl'] ?? data['file_url']) as String?;
        final notificationType = data['type'] as String?;
        
        final hasLink = link != null || pdfUrl != null || fileUrl != null;
        final isDocumentType = notificationType == 'letter' || 
                              notificationType == 'document' || 
                              notificationType == 'lease_renewal';
        
        debugPrint('Has link: $hasLink, Is document type: $isDocumentType');
        
        // If it's a document notification with a link/PDF, download it immediately
        if (hasLink || isDocumentType) {
          debugPrint('Document notification detected, triggering download');
          _handleLinkOrPdfAction(data);
        } else {
          // Handle normal navigation
          _handleNotificationNavigation(data);
        }
      } catch (e) {
        debugPrint('Error handling notification tap: $e');
        Get.snackbar(
          'Error',
          'Could not open notification',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }

    Future<void> _handleForegroundMessage(RemoteMessage message) async {
      try {
        // Store the notification locally first
        _notificationController.addNotificationFromRemoteMessage(message);

        // Then show the local notification
        final notification = message.notification;
        final data = message.data;

        if (notification == null && data.isEmpty) return;

        String channelId = _getChannelId(data['type']);
        String channelName = _getChannelName(data['type']);

        final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          channelId,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
          playSound: true,
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        final NotificationDetails platformDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          notification?.title ?? _getDefaultTitle(data),
          notification?.body ?? _getDefaultBody(data),
          platformDetails,
          payload: jsonEncode(data),
        );
      } catch (e) {
        debugPrint('Error handling foreground message: $e');
      }
    }

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

    String _getChannelId(String? type) {
      switch (type) {
        case 'technician_assignment':
        case 'technician_ticket':
        case 'job_update':
        case 'technician_rectify':
          return _techChannelId;
        case 'property':
        case 'property_update':
        case 'tenant_property':
        case 'enquiry':
        case 'lease_renewal':
        case 'document':
        case 'letter':
          return _orderChannelId;
        case 'chat':
        case 'message':
        case 'booking':
  case 'property_booking':
  case 'new_booking':
  case 'booking_confirmed':
   return _orderChannelId;


   case 'custom_notice':
case 'pdf_notice':
case 'notice_pdf':
case 'tenant_notice':
  return _orderChannelId;
   
   case 'property_interest':
case 'customer_interest':
case 'property_enquiry':
  return _orderChannelId;
        default:
          return _chatChannelId;
      }
    }

    Color _getUrgencyColor(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'critical':
    case 'overdue':
    case 'expired':
      return Colors.red[700]!;
    case 'urgent':
    case 'high':
      return Colors.orange[700]!;
    case 'medium':
      return Colors.orange[500]!;
    case 'normal':
    case 'low':
      return Colors.blue[500]!;
    default:
      return Colors.grey[500]!;
  }
}

String _formatDate(String dateString) {
  try {
    // Use TimezoneHelper to format date in Oman time
    return TimezoneHelper.formatDateOnly(dateString);
  } catch (e) {
    debugPrint('Error formatting date: $e');
    return dateString;
  }
}

    String _getChannelName(String? type) {
      switch (type) {
        case 'technician_assignment':
        case 'technician_ticket':
          return 'Technician Assignment';
        case 'job_update':
          return 'Job Update';
        case 'technician_rectify':
          return 'Technician Rectify';
        case 'property':
        case 'property_update':
          return 'Property Update';
        case 'tenant_property':
          return 'Tenant Property';
        case 'enquiry':
          return 'Customer Enquiry';
        case 'lease_renewal':
          return 'Lease Renewal';
        case 'document':
        case 'letter':
          return 'Document Notification';
        case 'chat':
        case 'message':
        case 'booking':
  case 'property_booking':
  case 'new_booking':
  case 'booking_confirmed':
    return 'Property Booking';
    case 'property_interest':
case 'customer_interest':
  return 'Property Interest';
case 'property_enquiry':
  return 'Property Enquiry';
  case 'custom_notice':
case 'pdf_notice':
case 'notice_pdf':
case 'tenant_notice':
  return 'Official Notices';

        default:
          return 'Chat Notifications';
      }
    }

  String _getDefaultTitle(Map<String, dynamic> data) {
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
      case 'complaint_reply':
      case 'ticket_reply':
      case 'ticket_update':
        return 'Ticket Update';

         case 'ticket':
    case 'complaint':
    case 'tenant_ticket':
    case 'complaint_reply':
    case 'ticket_reply':
    case 'ticket_update':
      return 'Ticket Update';
    case 'new_complaint':  // ✅ ADD THIS
      return 'New Complaint Registered';
    case 'new_ticket':  // ✅ ADD THIS
      return 'New Ticket Created';
      // ✅ NEW: Follow-up notification titles
      case 'follow_up':
      case 'followup':
        return 'Follow-up Update';
      case 'site_visit':
      case 'property_visit_scheduled':
        return 'Site Visit Scheduled';
      case 'property_visit_pending':
        return 'Site Visit Pending';
      case 'property_visited':
        return 'Property Visit Completed';
      case 'property_agreed':
        return 'Property Agreement';
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
      case 'lease_renewal':
        return 'Lease Renewal Notice';
      case 'document':
        return 'New Document';
      case 'letter':
        return 'New Letter';

        case 'booking':
  case 'property_booking':
  case 'new_booking':
    return 'New Property Booking';
  case 'booking_confirmed':
    return 'Booking Confirmed';

    case 'property_interest':
case 'customer_interest':
  return 'New Property Interest';
case 'property_enquiry':
  return 'Property Enquiry';

  case 'custom_notice':
case 'pdf_notice':
case 'notice_pdf':
case 'tenant_notice':
  return 'Official Notice';
  
      default:
        return 'New Notification';
        
    }
  }

  // Update _getDefaultBody to handle new types:
  String _getDefaultBody(Map<String, dynamic> data) {
    switch (data['type']) {
       case 'new_complaint':  // ✅ ADD THIS
      return data['description'] ?? 'A new complaint has been registered';
    case 'new_ticket':  // ✅ ADD THIS
      return data['description'] ?? 'A new ticket has been created';
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
        return data['message'] ?? 'Your ticket has been updated';
      case 'complaint_reply':
      case 'ticket_reply':
        return data['message'] ?? 'You have a new reply on your ticket';
      case 'ticket_update':
        return data['message'] ?? 'Your ticket status has been updated';
      // ✅ NEW: Follow-up notification bodies
      case 'follow_up':
      case 'followup':
        return data['message'] ?? 'Customer follow-up has been updated. Tap to view details and notes.';
      case 'site_visit':
      case 'property_visit_scheduled':
        return data['message'] ?? 'A site visit has been scheduled. Tap to view details and notes.';
      case 'property_visit_pending':
        return data['message'] ?? 'A site visit is pending. Tap to view details.';
      case 'property_visited':
        return data['message'] ?? 'Property visit has been completed. Tap to view notes.';
      case 'property_agreed':
        return data['message'] ?? 'Customer has agreed to the property. Tap to view details.';
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
        return data['message'] ?? 'You have a new message';
      case 'approval_pending':
        return 'Your request is pending approval';
      case 'lease_renewal':
        return data['message'] ?? 'A new official letter has been issued. Tap to view.';
      case 'document':
      case 'letter':
        return data['message'] ?? 'Tap to view or download the document';

        case 'booking':
  case 'property_booking':
  case 'new_booking':
    return data['message'] ?? 'You have a new property booking from a customer';
  case 'booking_confirmed':
    return data['message'] ?? 'Property booking has been confirmed';

    case 'property_interest':
case 'customer_interest':
  final interestType = data['interestType'] as String?;
  if (interestType == 'call') {
    return data['message'] ?? 'A customer wants to call you about your property';
  } else if (interestType == 'chat') {
    return data['message'] ?? 'A customer wants to chat about your property';
  }
  return data['message'] ?? 'A customer is interested in your property';
  
case 'property_enquiry':
  return data['message'] ?? 'New enquiry received for your property';

  case 'custom_notice':
case 'pdf_notice':
case 'notice_pdf':
case 'tenant_notice':
  final subject = data['subject'] as String?;
  return subject ?? data['message'] ?? 'You have received an official notice. Tap to view PDF.';

      default:
        return data['message'] ?? 'You have a new notification';
    }
  }
    Future<void> dispose() async {
      _authSubscription?.cancel();
      _tokenRefreshSubscription?.cancel();
    }
  }
  

  @pragma('vm:entry-point')
  Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    try {
      await Firebase.initializeApp();
      await GetStorage.init();
      
      // Initialize notification controller if not already done
      if (!Get.isRegistered<NotificationController>()) {
        Get.put(NotificationController());
      }
      
      // Store the notification
      final notificationController = Get.find<NotificationController>();
      notificationController.addNotificationFromRemoteMessage(message);
      
      debugPrint('Background message received and stored: ${message.data}');
      
      // Check if this is a document notification
      final data = message.data;
      final link = data['link'] as String?;
      final pdfUrl = (data['pdfUrl'] ?? data['pdf_url']) as String?;
      final fileUrl = (data['fileUrl'] ?? data['file_url']) as String?;
      final notificationType = data['type'] as String?;
      
      final hasLink = link != null || pdfUrl != null || fileUrl != null;
      final isDocumentType = notificationType == 'letter' || 
                            notificationType == 'document' || 
                            notificationType == 'lease_renewal';
      
      if (hasLink || isDocumentType) {
        debugPrint('Document notification in background - will download when tapped');
      }
    } catch (e) {
      debugPrint('Error in background handler with storage: $e');
    }
  }