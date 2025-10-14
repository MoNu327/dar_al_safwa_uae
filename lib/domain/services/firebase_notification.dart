import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
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

      // // Handle notification when app is terminated and opened via notification
      // FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      //   if (message != null) {
      //     debugPrint('App opened from terminated state via notification: ${message.data}');
      //     _notificationController.addNotificationFromRemoteMessage(message);
      //     _notificationController.markAsRead(message.messageId ?? '');
      //     // Delay navigation to ensure app is fully loaded
      //     Future.delayed(const Duration(milliseconds: 1500), () {
      //       _handleNotificationNavigation(message.data);
      //     });
      //   }
      // });

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

      // Start listening for auth state changes
      _setupAuthStateListener();
      
      debugPrint('Firebase notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase notifications: $e');
    }
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

  // NEW: Handle link and PDF downloads
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

      // Notify Android MediaStore about the new file
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

      // Wait a moment for media scanner, then open
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

// Add this new method
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
}// Helper method to open PDF file
Future<void> _openPdfFile(String filePath) async {
  try {
    if (Platform.isAndroid) {
      // Use Android-specific method to open file
      const platform = MethodChannel('com.majan.app/file_opener');
      await platform.invokeMethod('openFile', {'path': filePath});
      debugPrint('File opened using native method');
    } else {
      // For iOS, try url_launcher
      final uri = Uri.file(filePath);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  } catch (e) {
    debugPrint('Error in _openPdfFile: $e');
    throw e;
  }
}

  // NEW: Open URL in browser or external app
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
    // Ensure we handle this on the main thread
    Future.delayed(Duration.zero, () {
      _handleLinkOrPdfAction(data);
    });
    return; // Don't navigate to other screens if it's a link/PDF notification
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
        case 'chat':
        case 'message':
          final chatId = data['chatId'] as String?;
          final userId = data['userId'] as String?;
          final userName = data['userName'] as String?;
          
          // Navigate to agent chat screen (based on your routes)
          Get.toNamed('/agent', arguments: {
            'chatId': chatId,
            'userId': userId,
            'userName': userName,
          });
          break;

        case 'technician_assignment':
        case 'technician_ticket':
        case 'job_update':
          final ticketId = data['ticketId'] as String?;
          final assignmentId = data['assignmentId'] as String?;
          final jobId = data['jobId'] as String?;
          
          if (ticketId != null || assignmentId != null || jobId != null) {
            // Navigate to technician tickets view
            Get.toNamed('/technician-tickets', arguments: {
              'ticketId': ticketId,
              'assignmentId': assignmentId,
              'jobId': jobId,
            });
          } else {
            // Fallback to technician dashboard
            Get.toNamed('/technicianDashboard');
          }
          break;

        case 'ticket':
        case 'complaint':
        case 'tenant_ticket':
          final ticketId = data['ticketId'] as String?;
          final complaintId = data['complaintId'] as String?;
          
          if (ticketId != null || complaintId != null) {
            // For now, navigate to dashboard since tenantTicketDetails route is commented out
            // When you uncomment the route, use this:
            // Get.toNamed('/tenantTicketDetails', arguments: {
            //   'ticketId': ticketId ?? complaintId,
            // });
            
            // For now, navigate to dashboard
            Get.toNamed('/navbar');
          }
          break;

        case 'property':
        case 'property_update':
          final propertyId = data['propertyId'] as String?;
          
          if (propertyId != null) {
            Get.toNamed('/propertyDetails', arguments: {
              'propertyId': propertyId,
            });
          } else {
            // Navigate to properties list
            Get.toNamed('/properties');
          }
          break;

        case 'tenant_property':
          // Navigate to tenant properties list
          Get.toNamed('/tenantPropertyList');
          break;

        case 'tenant_documents':
          // Navigate to tenant documents
          Get.toNamed('/tenantDocumentsList');
          break;

        case 'tenant_complaint':
          final propertyName = data['propertyName'] as String?;
          final propertyId = data['propertyId'];
          final unitAddressId = data['unitAddressId'];
          
          Get.toNamed('/tenantComplaintReg', arguments: {
            'propertyName': propertyName ?? '',
            'propertyId': propertyId ?? 0,
            'unitAddressId': unitAddressId ?? 0,
          });
          break;

        case 'technician_rectify':
          final complaintId = data['complaintId'] as String?;
          final category = data['category'] as String?;
          
          Get.toNamed('/technician-rectify-ticket', arguments: {
            'complaintId': complaintId ?? '',
            'category': category ?? '',
          });
          break;

        case 'profile':
        case 'technician_profile':
          // Check if user is technician and navigate accordingly
          Get.toNamed('/technician-profile');
          break;

        case 'enquiry':
        case 'customer_enquiry':
          Get.toNamed('/enquiry');
          break;

        case 'property_listing':
          Get.toNamed('/propertyListing');
          break;

        case 'inbox':
          Get.toNamed('/inbox');
          break;

        case 'search':
          Get.toNamed('/search');
          break;

        case 'user_details':
          Get.toNamed('/userDetailsSubmission');
          break;

        case 'approval_pending':
          Get.toNamed('/approvalPendingPage');
          break;

        // NEW: Handle lease renewal and other document notifications
        case 'lease_renewal':
        case 'document':
        case 'letter':
          // Check if there's a link or PDF to handle
          _handleLinkOrPdfAction(data);
          break;

        default:
          // Navigate to dashboard as fallback
          debugPrint('Unknown notification type: $notificationType, navigating to dashboard');
          Get.offAllNamed('/navbar');
          break;
      }
    } catch (e) {
      debugPrint('Error navigating with GetX: $e');
      // Fallback to navigator key
      if (navigatorKey.currentContext != null) {
        _navigateUsingNavigatorKey(data);
      } else {
        // Ultimate fallback to dashboard
        Get.offAllNamed('/navbar');
      }
    }
  }

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

        case 'technician_assignment':
        case 'technician_ticket':
        case 'job_update':
          Navigator.of(context).pushNamed('/technician-tickets', arguments: data);
          break;

        case 'ticket':
        case 'complaint':
        case 'tenant_ticket':
          Navigator.of(context).pushNamed('/navbar', arguments: data);
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

        // NEW: Handle lease renewal and other document notifications
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
      // Fallback to dashboard
      Navigator.of(context).pushNamedAndRemoveUntil('/navbar', (route) => false);
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
        _cleanupToken();
      }
    });
  }

  Future<void> _handleAuthStateChange(User user) async {
    await _cleanupToken();
    await _setupTokenManagement(user);
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

  Future<void> _cleanupToken() async {
    _tokenRefreshSubscription?.cancel();
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String? token, User user) async {
    if (token == null) return;
    try {
        final response = await _apiService.getFCMtokenforagent(token, user.uid);
            debugPrint('FCM token saved to backend: $response');
      final isTechnician = await _isUserTechnician(user.uid);
      final collectionName = isTechnician ? 'technicians' : 'users';
      await FirebaseFirestore.instance.collection(collectionName).doc(user.uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
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
        return 'Ticket Update';
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
      default:
        return 'New Notification';
    }
  }

  String _getDefaultBody(Map<String, dynamic> data) {
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