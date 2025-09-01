// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class FirebaseNotificationService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   Future<void> initialize() async {
//     try {
//       // Request permissions
//       await _requestPermissions();

//       // Initialize local notifications
//       await _initLocalNotifications();

//       // Set up foreground message handler
//       FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

//       // Set up background handler
//       FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

//       // await handleAuthStateChange();
//       // // Get token
//       // final token = await _firebaseMessaging.getToken();
//       // debugPrint('FCM Token: $token');

//       // // Save this token to Firestore
//       // await _saveTokenToFirestore(token);

//       // Handle token refresh
//       // _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
//     } catch (e) {
//       debugPrint('Error initializing Firebase notifications: $e');
//     }
//   }

//   Future<void> handleAuthStateChange() async {
//     final currentUserId = FirebaseAuth.instance.currentUser;

//     // Determine which collection to use

//     // Clear previous user's token if they logged out
//     if (currentUserId != null) {
//       final collectionName =
//           currentUserId.displayName != null ? 'users' : 'agents';
//       await _removeTokenFromFirestore(currentUserId.uid, collectionName);
//     }

//     // Get and save new token if user is logged in
//     if (currentUserId != null) {
//       final token = await _firebaseMessaging.getToken();
//       await _saveTokenToFirestore(token);

//       // Set up token refresh listener
//       _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
//     }
//   }

//   Future<void> _removeTokenFromFirestore(
//       String userId, String collection) async {
//     try {
//       await FirebaseFirestore.instance
//           .collection(collection)
//           .doc(userId)
//           .update({
//         'fcmToken': FieldValue.delete(),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       });
//       debugPrint('Removed FCM token for $userId from $collection');
//     } catch (e) {
//       debugPrint('Error removing token: $e');
//     }
//   }

//   Future<void> _requestPermissions() async {
//     try {
//       await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//       );
//     } catch (e) {
//       debugPrint('Error requesting notification permissions: $e');
//     }
//   }

//   Future<void> _initLocalNotifications() async {
//     try {
//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/launcher_icon');

//       const DarwinInitializationSettings iosSettings =
//           DarwinInitializationSettings();

//       const InitializationSettings settings = InitializationSettings(
//         android: androidSettings,
//         iOS: iosSettings,
//       );

//       await _flutterLocalNotificationsPlugin.initialize(settings);
//     } catch (e) {
//       debugPrint('Error initializing local notifications: $e');
//     }
//   }

//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     try {
//       // Handle both notification and data payloads
//       final notification = message.notification;
//       final data = message.data;

//       if (notification == null && data.isEmpty) return;

//       const AndroidNotificationDetails androidDetails =
//           AndroidNotificationDetails(
//         'chat_channel', // Same channel ID as in FCM payload
//         'Chat Notifications', // Channel name
//         channelDescription: 'Incoming chat messages',
//         importance: Importance.max, // Use max for heads-up notifications
//         priority: Priority.high,
//         showWhen: true,
//         playSound: true,
//         enableVibration: true,
//         visibility: NotificationVisibility.public,
//       );

//       const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );

//       const NotificationDetails platformDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );

//       await _flutterLocalNotificationsPlugin.show(
//         DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
//         notification?.title ?? 'New Message', // Fallback title
//         notification?.body ?? data['message'] ?? '', // Fallback body
//         platformDetails,
//         payload: jsonEncode(data), // Pass data for navigation
//       );
//     } catch (e, stack) {
//       debugPrint('Error handling foreground message: $e');
//       debugPrint('Stack trace: $stack');
//     }
//   }

//   // Future<void> _handleForegroundMessage(RemoteMessage message) async {
//   //   try {
//   //     if (message.notification == null) return;

//   //     final notification = message.notification!;

//   //     const AndroidNotificationDetails androidDetails =
//   //         AndroidNotificationDetails(
//   //       'chat_channel',
//   //       'Chat Messages',
//   //       importance: Importance.high,
//   //       priority: Priority.high,
//   //       showWhen: true,
//   //     );

//   //     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

//   //     const NotificationDetails platformDetails = NotificationDetails(
//   //       android: androidDetails,
//   //       iOS: iosDetails,
//   //     );

//   //     await _flutterLocalNotificationsPlugin.show(
//   //       0, // Notification ID
//   //       notification.title,
//   //       notification.body,
//   //       platformDetails,
//   //     );
//   //   } catch (e) {
//   //     debugPrint('Error handling foreground message: $e');
//   //   }
//   // }

//   Future<void> _saveTokenToFirestore(String? token) async {
//     if (token == null) return;

//     debugPrint('[FCM] Current FCM Token: $token');

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       if (user == null) return;

//       // Determine which collection to use
//       final collectionName = user.displayName != null ? 'users' : 'agents';
//       final docRef =
//           FirebaseFirestore.instance.collection(collectionName).doc(user.uid);

//       // Use set with merge to create document if it doesn't exist
//       await docRef.set({
//         'fcmToken': token,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));

//       debugPrint(
//           '[FCM] Successfully saved token to $collectionName collection for ${user.uid}');
//     } catch (e) {
//       debugPrint('[FCM] Error saving token to Firestore: $e');
//     }
//   }

//   Future<String?> refreshFcmToken() async {
//     try {
//       // Delete the old token (optional)
//       await FirebaseMessaging.instance.deleteToken();

//       // Fetch a new token
//       String? newToken = await FirebaseMessaging.instance.getToken();
//       await _saveTokenToFirestore(newToken);
//       return newToken;
//     } catch (e) {
//       debugPrint('Error refreshing FCM token: $e');
//       return null;
//     }
//   }
// }

// @pragma('vm:entry-point')
// Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   try {
//     await Firebase.initializeApp();
//     final service = FirebaseNotificationService();
//     await service._handleForegroundMessage(message);
//   } catch (e) {
//     debugPrint('Error in background handler: $e');
//   }
// }

// import 'dart:async';
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// import 'dart:convert';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_core/firebase_core.dart';

// class FirebaseNotificationService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   StreamSubscription? _authSubscription;
//   StreamSubscription? _tokenRefreshSubscription;

//   // Notification channels for different types
//   static const String _chatChannelId = 'chat_channel';
//   static const String _techChannelId = 'tech_channel';
//   static const String _orderChannelId = 'order_channel';

//   Future<void> initialize() async {
//     try {
//       // Initialize notification infrastructure
//       await _requestPermissions();
//       await _initLocalNotifications();
//       await _createNotificationChannels();

//       // Set up message handlers
//       FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
//       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//       // Start listening for auth state changes
//       _setupAuthStateListener();
//     } catch (e) {
//       debugPrint('Error initializing Firebase notifications: $e');
//     }
//   }

//   Future<void> _createNotificationChannels() async {
//     // Chat channel (already exists in your code)
//     const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
//       _chatChannelId,
//       'Chat Notifications',
//       description: 'Incoming chat messages',
//       importance: Importance.max,
//     );

//     // Technician-specific channel
//     const AndroidNotificationChannel techChannel = AndroidNotificationChannel(
//       _techChannelId,
//       'Technician Notifications',
//       description: 'Notifications for technician assignments and updates',
//       importance: Importance.high,
//     );

//     // Order updates channel
//     const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
//       _orderChannelId,
//       'Order Updates',
//       description: 'Notifications about order status changes',
//       importance: Importance.defaultImportance,
//     );

//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(chatChannel);

//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(techChannel);

//     await _flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(orderChannel);
//   }

//   void _setupAuthStateListener() {
//     _authSubscription?.cancel();
//     _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
//       if (user != null) {
//         _handleAuthStateChange(user);
//       } else {
//         _cleanupToken();
//       }
//     });
//   }

//   Future<void> _handleAuthStateChange(User user) async {
//     await _cleanupToken();
//     await _setupTokenManagement(user);
//   }

//   Future<void> _setupTokenManagement(User user) async {
//     _tokenRefreshSubscription?.cancel();

//     await _forceTokenRefresh(user);

//     _tokenRefreshSubscription =
//         _firebaseMessaging.onTokenRefresh.listen((newToken) {
//       _saveTokenToFirestore(newToken, user);
//     });
//   }

//   Future<void> _forceTokenRefresh(User user) async {
//     try {
//       await _firebaseMessaging.deleteToken();
//       debugPrint('Successfully deleted old FCM token');

//       final token = await _firebaseMessaging.getToken();
//       debugPrint('New FCM token generated: $token');

//       await _saveTokenToFirestore(token, user);
//     } catch (e) {
//       debugPrint('Error forcing token refresh: $e');
//     }
//   }

//   Future<void> _cleanupToken() async {
//     debugPrint("Deleting FCM token");
//     _tokenRefreshSubscription?.cancel();
//     _tokenRefreshSubscription = null;

//     try {
//       await _firebaseMessaging.deleteToken();
//     } catch (e) {
//       debugPrint('Error deleting FCM token: $e');
//     }
//   }

//   Future<void> _saveTokenToFirestore(String? token, User user) async {
//     if (token == null) return;

//     debugPrint('[FCM] Saving token for user ${user.uid}: $token');

//     try {
//       // Determine if user is technician (you might need to adjust this logic)
//       final isTechnician = await _isUserTechnician(user.uid);
//       final collectionName = isTechnician ? 'technicians' : 'users';

//       await FirebaseFirestore.instance
//           .collection(collectionName)
//           .doc(user.uid)
//           .set({
//         'fcmToken': token,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     } catch (e) {
//       debugPrint('[FCM] Error saving token: $e');
//     }
//   }

//   Future<bool> _isUserTechnician(String uid) async {
//     // Implement your logic to check if user is technician
//     // This might involve checking a specific collection or user role field
//     try {
//       final doc = await FirebaseFirestore.instance
//           .collection('technicians')
//           .doc(uid)
//           .get();
//       return doc.exists;
//     } catch (e) {
//       debugPrint('Error checking technician status: $e');
//       return false;
//     }
//   }

//   Future<void> _requestPermissions() async {
//     try {
//       await _firebaseMessaging.requestPermission(
//         alert: true,
//         badge: true,
//         sound: true,
//         provisional: false, // For iOS - request full permissions immediately
//       );
//     } catch (e) {
//       debugPrint('Error requesting notification permissions: $e');
//     }
//   }

//   Future<void> _initLocalNotifications() async {
//     try {
//       const AndroidInitializationSettings androidSettings =
//           AndroidInitializationSettings('@mipmap/launcher_icon');

//       const DarwinInitializationSettings iosSettings =
//           DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//         defaultPresentAlert: true,
//         defaultPresentBadge: true,
//         defaultPresentSound: true,
//       );

//       const InitializationSettings settings = InitializationSettings(
//         android: androidSettings,
//         iOS: iosSettings,
//       );

//       await _flutterLocalNotificationsPlugin.initialize(
//         settings,
//         onDidReceiveNotificationResponse: (NotificationResponse response) {
//           // Handle notification tap
//           _handleNotificationTap(response.payload);
//         },
//       );
//     } catch (e) {
//       debugPrint('Error initializing local notifications: $e');
//     }
//   }

//   void _handleNotificationTap(String? payload) {
//     if (payload == null) return;
    
//     try {
//       final data = jsonDecode(payload) as Map<String, dynamic>;
//       // Handle the notification tap based on the data
//       // You might navigate to specific screens based on notification type
//       debugPrint('Notification tapped with payload: $data');
      
//       // Example: If it's a technician assignment notification
//       if (data['type'] == 'technician_assignment') {
//         // Navigate to the assignment screen
//         // navigationService.navigateTo('/assignment/${data['assignmentId']}');
//       }
//     } catch (e) {
//       debugPrint('Error handling notification tap: $e');
//     }
//   }

//   Future<void> _handleForegroundMessage(RemoteMessage message) async {
//     try {
//       final notification = message.notification;
//       final data = message.data;

//       if (notification == null && data.isEmpty) return;

//       // Determine which channel to use based on message type
//       String channelId = _chatChannelId;
//       String channelName = 'Chat Notifications';
      
//       if (data['type'] == 'technician_assignment') {
//         channelId = _techChannelId;
//         channelName = 'Technician Assignment';
//       } else if (data['type'] == 'order_update') {
//         channelId = _orderChannelId;
//         channelName = 'Order Update';
//       }

//       final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
//         channelId,
//         channelName,
//         channelDescription: 'Incoming chat messages',
//         importance: Importance.max,
//         priority: Priority.high,
//         showWhen: true,
//         playSound: true,
//         enableVibration: true,
//         visibility: NotificationVisibility.public,
//       );


//       const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//         badgeNumber: 1,
//         threadIdentifier: _techChannelId,
//       );

//       final NotificationDetails platformDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );

//       await _flutterLocalNotificationsPlugin.show(
//         DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         notification?.title ?? _getDefaultTitle(data),
//         notification?.body ?? _getDefaultBody(data),
//         platformDetails,
//         payload: jsonEncode(data),
//       );
//     } catch (e, stack) {
//       debugPrint('Error handling foreground message: $e');
//       debugPrint('Stack trace: $stack');
//     }
//   }

//   String _getDefaultTitle(Map<String, dynamic> data) {
//     if (data['type'] == 'technician_assignment') {
//       return 'New Assignment';
//     } else if (data['type'] == 'order_update') {
//       return 'Order Update';
//     }
//     return 'New Notification';
//   }

//   String _getDefaultBody(Map<String, dynamic> data) {
//     if (data['type'] == 'technician_assignment') {
//       return 'You have been assigned a new job';
//     } else if (data['type'] == 'order_update') {
//       return 'Your order status has been updated';
//     } else if (data['message'] != null) {
//       return data['message'];
//     }
//     return 'You have a new notification';
//   }

//   Future<void> dispose() async {
//     _authSubscription?.cancel();
//     _tokenRefreshSubscription?.cancel();
//   }
// }

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   try {
//     await Firebase.initializeApp();
//     final service = FirebaseNotificationService();
//     await service._handleForegroundMessage(message);
//   } catch (e) {
//     debugPrint('Error in background handler: $e');
//   }
// }






import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:majan/domain/controller/notification.dart';

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
        debugPrint('Notification opened app: ${message.data}');
        _notificationController.addNotificationFromRemoteMessage(message);
        _notificationController.markAsRead(message.messageId ?? '');
        _handleNotificationNavigation(message.data);
      });

      // Handle notification when app is terminated and opened via notification
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('App opened from terminated state via notification: ${message.data}');
          _notificationController.addNotificationFromRemoteMessage(message);
          _notificationController.markAsRead(message.messageId ?? '');
          // Delay navigation to ensure app is fully loaded
          Future.delayed(const Duration(milliseconds: 1500), () {
            _handleNotificationNavigation(message.data);
          });
        }
      });

      // Start listening for auth state changes
      _setupAuthStateListener();
      
      debugPrint('Firebase notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase notifications: $e');
    }
  }

  void _handleNotificationNavigation(Map<String, dynamic> data) {
    debugPrint('Attempting navigation with data: $data');
    
    // Try GetX first (more reliable in Flutter apps using GetX)
    if (Get.context != null) {
      _navigateUsingGetX(data);
    } else if (navigatorKey.currentContext != null) {
      _navigateUsingNavigatorKey(data);
    } else {
      // Retry navigation after a delay
      debugPrint('No navigation context available, retrying in 2 seconds...');
      Future.delayed(const Duration(seconds: 2), () {
        _handleNotificationNavigation(data);
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
    if (payload == null) return;
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      Future.delayed(const Duration(milliseconds: 300), () {
        _handleNotificationNavigation(data);
      });
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
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
  } catch (e) {
    debugPrint('Error in background handler with storage: $e');
  }
}