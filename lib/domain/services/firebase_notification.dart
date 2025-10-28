import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:majan/core/theme/app_colors.dart';
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
        Get.snackbar(
          'Error',
          'No link or file found in this notification',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      }
    }

    // Download and open PDF
 Future<void> _downloadAndOpenPdf(String url, String fileName) async {
  try {
    debugPrint('Starting PDF download for: $url');
    
    // ✅ Request permissions based on platform
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

    // ✅ CHANGED: Show persistent downloading snackbar (no duration)
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

      // ✅ CHANGED: Close downloading snackbar before showing success
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
        await _openPdfFile(filePath);
      } catch (e) {
        debugPrint('Error opening PDF: $e');
        Get.snackbar(
          'File Saved',
          Platform.isAndroid
            ? 'PDF saved to Downloads. Open it from your file manager.'
            : 'PDF saved to Documents. You can open it from the Files app.',
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

    void _handleNotificationNavigation(Map<String, dynamic> data, {int retryCount = 0}) {
      debugPrint('=== NOTIFICATION TAP DETECTED ===');
      debugPrint('Attempting navigation with data: $data');
      
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
        _navigateUsingGetX(data);
      } else if (navigatorKey.currentContext != null) {
        _navigateUsingNavigatorKey(data);
      } else {
        debugPrint('No navigation context available, retrying in 2 seconds... (attempt $retryCount)');
        Future.delayed(const Duration(seconds: 2), () {
          _handleNotificationNavigation(data, retryCount: retryCount + 1);
        });
      }
    }

  void _navigateUsingGetX(Map<String, dynamic> data) {
    final notificationType = data['type'] as String?;
    debugPrint('Navigating using GetX for type: $notificationType');
    
    try {
      switch (notificationType) {
        
        // ✅ CHAT - Show message dialog
        case 'chat':
        case 'message':
          final message = data['message'] as String?;
          final userName = data['userName'] as String? ?? 'User';
          
          if (message != null && message.isNotEmpty) {
            Get.dialog(
              AlertDialog(
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
                    child: Text(
                      message,
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
      AlertDialog(
        backgroundColor: AppColors.primaryColor,
        title: const Row(
          children: [
            Icon(Icons.event_available, color: Colors.green, size: 24),
            SizedBox(width: 8),
            Text('New Property Booking', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
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
        actions: [
          if (propertyId != null)
            TextButton(
              onPressed: () {
                Get.back();
                // Navigate to booking details or property details
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
    break;

        // ✅ FOLLOW-UP - Show notes dialog (KEEP AS IS - WORKING)
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
            // Extract location from notes
            final location = _extractLocation(notes);
            
            debugPrint('   Notes available: true');
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
          
          final content = message ?? jobDetails ?? 'You have a new assignment';
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.work, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('Assignment Details', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ticketId != null) ...[
                        Text('Ticket ID: $ticketId', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                      ],
                      Text(content, 
                        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
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
          
          final content = message ?? 'Property information has been updated';
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.home, color: Colors.purple, size: 24),
                  SizedBox(width: 8),
                  Text('Property Update', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (propertyName != null) ...[
                        Text(propertyName, 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 12),
                      ],
                      if (propertyId != null) ...[
                        Text('Property ID: $propertyId', 
                          style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                      ],
                      Text(content, 
                        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87)),
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
          break;

        // ✅ DOCUMENTS - Show document notification dialog
        case 'tenant_documents':
          final message = data['message'] as String?;
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.description, color: Colors.teal, size: 24),
                  SizedBox(width: 8),
                  Text('Documents Update', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Text(
                    message ?? 'Your documents have been updated',
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

        // ✅ COMPLAINT REGISTRATION - Show dialog
        case 'tenant_complaint':
          final message = data['message'] as String?;
          final propertyName = data['propertyName'] as String?;
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.report_problem, color: Colors.red, size: 24),
                  SizedBox(width: 8),
                  Text('Complaint Notice', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (propertyName != null) ...[
                        Text('Property: $propertyName', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'A complaint has been registered',
                        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                      ),
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
          break;

        // ✅ TECHNICIAN RECTIFY - Show details dialog
        case 'technician_rectify':
          final message = data['message'] as String?;
          final complaintId = data['complaintId'] as String?;
          final category = data['category'] as String?;
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.build, color: Colors.orange, size: 24),
                  SizedBox(width: 8),
                  Text('Rectification Required', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (complaintId != null) ...[
                        Text('Complaint ID: $complaintId', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                      ],
                      if (category != null) ...[
                        Text('Category: $category', 
                          style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'This ticket requires rectification',
                        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                      ),
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
          break;

        // ✅ ENQUIRY - Show enquiry dialog
        case 'enquiry':
        case 'customer_enquiry':
          final message = data['message'] as String?;
          final customerName = data['customerName'] as String?;
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.question_answer, color: Colors.indigo, size: 24),
                  SizedBox(width: 8),
                  Text('Customer Enquiry', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (customerName != null) ...[
                        Text('From: $customerName', 
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        message ?? 'You have a new customer enquiry',
                        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                      ),
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
          break;

        // ✅ APPROVAL PENDING - Show dialog
        case 'approval_pending':
          final message = data['message'] as String?;
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text('Approval Pending', style: TextStyle(fontSize: 18)),
                ],
              ),
              content: Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  child: Text(
                    message ?? 'Your request is pending approval',
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
              backgroundColor: AppColors.primaryColor,
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
  final customerPhone = data['customerPhone'] as String?;
  final propertyName = data['propertyName'] as String?;
  final propertyId = data['propertyId'] as String?;
  final interestType = data['interestType'] as String?; // 'chat' or 'call'
  
  // Build content widgets
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
  
  // Customer Name
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
  
  // Phone Number (with call button)
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
        // Call button if phone available
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
  break;


        // ✅ UNKNOWN - Show generic notification
        default:
          debugPrint('Unknown notification type: $notificationType');
          final message = data['message'] as String?;
          
          Get.dialog(
            AlertDialog(
              backgroundColor: AppColors.primaryColor,
              title: const Row(
                children: [
                  Icon(Icons.info, color: Colors.grey, size: 24),
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
        case 'followup':
        case 'site_visit':
        case 'property_visit_scheduled':
        case 'property_visit_pending':
        case 'property_visited':
        case 'property_agreed':
          final notes = data['notes'] as String?;
          
          if (notes != null && notes.isNotEmpty) {
            showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) => AlertDialog(
                backgroundColor: AppColors.primaryColor,
                title: const Row(
                  children: [
                    Icon(Icons.event_note, color: Colors.blue, size: 24),
                    SizedBox(width: 8),
                    Text('Visit Notes', style: TextStyle(fontSize: 18)),
                  ],
                ),
                content: Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: SingleChildScrollView(
                    child: Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 16, 
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                    child: const Text('Close', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            );
          }
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
    final ticketId = data['ticketId'] as String?;
  final complaintId = data['complaintId'] as String?;
  final complaintIdFromData = data['complaint_id']?.toString();
  final complaintNumber = data['complaint_number'] as String?;  // ✅ NEW
  
  final finalTicketId = complaintIdFromData ?? ticketId ?? complaintId;
  final displayTicketId = complaintNumber ?? finalTicketId;  // ✅ Use complaint_number if available
  
  final message = data['message'] as String?;
  final reply = data['reply'] as String?;
  final category = data['category'] as String?;
  final subCategory = data['sub_category'] as String?;  // ✅ NEW
  final status = data['status'] as String?;
  final description = data['description'] as String?;
  final propertyName = data['propertyName'] as String?;
  final propertyTitle = data['property_title'] as String?;  // ✅ NEW
  final unitAddress = data['unit_address'] as String?;  // ✅ NEW
  final complainant = data['complainant'] as String?;  // ✅ NEW
  final createdAt = data['createdAt'] as String?;
  final updatedAt = data['updatedAt'] as String?;
  final timestamp = data['timestamp'] as String?;  // ✅ NEW
  final technicianName = data['technicianName'] as String?;
  final priority = data['priority'] as String?;
  
  // Use property_title if propertyName is not available
  final finalPropertyName = propertyTitle ?? propertyName;
  
  // Use timestamp if createdAt is not available
  final finalCreatedAt = timestamp ?? createdAt;
  
  // Use sub_category if available, otherwise category
  final finalCategory = subCategory ?? category;
  
  debugPrint('🎯 Ticket notification - showing complete details');
  debugPrint('   Ticket ID: $finalTicketId');
  debugPrint('   Display ID: $displayTicketId');
  debugPrint('   Type: $notificationType');
  debugPrint('   Category: $finalCategory');
  debugPrint('   Status: $status');
  
  // Build content widgets
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
  
  // Priority (if available)
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
  
  // ✅ NEW: Complainant Name
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
  
  // Reply (if this is a reply notification)
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
  
  // Message (if different from reply and description)
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
              _getTicketTitle(notificationType!),
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
        // View Full Ticket button
      // View Full Ticket button
if (finalTicketId != null && finalTicketId.isNotEmpty)
  TextButton.icon(
    onPressed: () {
      Get.back(); // Close the dialog first
      
      // Navigate directly to TicketDetailsScreen
      Get.to(() => TicketDetailsScreen(
        complaintId: finalTicketId,
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
   
   case 'property_interest':
case 'customer_interest':
case 'property_enquiry':
  return _orderChannelId;
        default:
          return _chatChannelId;
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