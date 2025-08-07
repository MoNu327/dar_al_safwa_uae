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
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _authSubscription;
  StreamSubscription? _tokenRefreshSubscription;

  // Add navigation key for global navigation
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // Notification channels for different types
  static const String _chatChannelId = 'chat_channel';
  static const String _techChannelId = 'tech_channel';
  static const String _orderChannelId = 'order_channel';

  Future<void> initialize() async {
    try {
      // Initialize notification infrastructure
      await _requestPermissions();
      await _initLocalNotifications();
      await _createNotificationChannels();

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle notification opened app (when app is opened from background)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpenedApp);
      
      // Check for initial message (when app is launched from notification)
      _checkForInitialMessage();

      // Start listening for auth state changes
      _setupAuthStateListener();
      
      debugPrint('Firebase notification service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase notifications: $e');
    }
  }

  // Enhanced method to check for initial message
  Future<void> _checkForInitialMessage() async {
    try {
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('App launched from notification: ${initialMessage.data}');
        // Delay navigation to ensure app is fully initialized
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationOpenedApp(initialMessage);
        });
      }
    } catch (e) {
      debugPrint('Error checking initial message: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    // Chat channel with high importance
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      _chatChannelId,
      'Chat Notifications',
      description: 'Incoming chat messages',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Technician-specific channel
    const AndroidNotificationChannel techChannel = AndroidNotificationChannel(
      _techChannelId,
      'Technician Notifications',
      description: 'Notifications for technician assignments and updates',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Order updates channel
    const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
      _orderChannelId,
      'Order Updates',
      description: 'Notifications about order status changes',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    final androidPlugin = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

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

    _tokenRefreshSubscription =
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken, user);
    });
  }

  Future<void> _forceTokenRefresh(User user) async {
    try {
      await _firebaseMessaging.deleteToken();
      debugPrint('Successfully deleted old FCM token');

      final token = await _firebaseMessaging.getToken();
      debugPrint('New FCM token generated: $token');

      await _saveTokenToFirestore(token, user);
    } catch (e) {
      debugPrint('Error forcing token refresh: $e');
    }
  }

  Future<void> _cleanupToken() async {
    debugPrint("Deleting FCM token");
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String? token, User user) async {
    if (token == null) return;

    debugPrint('[FCM] Saving token for user ${user.uid}: $token');

    try {
      final isTechnician = await _isUserTechnician(user.uid);
      final collectionName = isTechnician ? 'technicians' : 'users';

      await FirebaseFirestore.instance
          .collection(collectionName)
          .doc(user.uid)
          .set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  Future<bool> _isUserTechnician(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking technician status: $e');
      return false;
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        carPlay: false,
        announcement: false,
      );
      
      debugPrint('Notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
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
      
      debugPrint('Local notifications initialized successfully');
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  // Enhanced notification tap handler with navigation
  void _handleNotificationTap(String? payload) {
    if (payload == null) return;
    
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('Notification tapped with payload: $data');
      
      // Add a small delay to ensure the app is ready for navigation
      Future.delayed(const Duration(milliseconds: 300), () {
        _navigateBasedOnNotificationType(data);
      });
    } catch (e) {
      debugPrint('Error handling notification tap: $e');
    }
  }

  // Handle notification when app is opened from background/terminated state
  void _handleNotificationOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened app: ${message.data}');
    
    // Add a delay to ensure the app context is available
    Future.delayed(const Duration(milliseconds: 500), () {
      _navigateBasedOnNotificationType(message.data);
    });
  }

  // Enhanced navigation logic based on notification type
  void _navigateBasedOnNotificationType(Map<String, dynamic> data) {
    debugPrint('Attempting navigation with data: $data');
    
    // Try multiple navigation approaches
    if (Get.context != null) {
      _navigateUsingGetX(data);
    } else if (navigatorKey.currentContext != null) {
      _navigateUsingNavigatorKey(data);
    } else {
      // Retry navigation after a delay
      debugPrint('No navigation context available, retrying...');
      Future.delayed(const Duration(seconds: 1), () {
        _navigateBasedOnNotificationType(data);
      });
    }
  }

  void _navigateUsingGetX(Map<String, dynamic> data) {
    final notificationType = data['type'] as String?;
    debugPrint('Navigating using GetX for type: $notificationType');
    
    try {
      switch (notificationType) {
        case 'chat':
          _navigateToChatGetX(data);
          break;
        case 'technician_assignment':
          _navigateToTechnicianAssignmentGetX(data);
          break;
        case 'order_update':
          _navigateToOrderDetailsGetX(data);
          break;
        case 'job_update':
          _navigateToJobDetailsGetX(data);
          break;
        case 'appointment':
          _navigateToAppointmentGetX(data);
          break;
        case 'ticket':
          _navigateToTicketDetailsGetX(data);
          break;
        default:
          Get.offAllNamed('/home');
      }
    } catch (e) {
      debugPrint('Error navigating with GetX: $e');
      // Fallback to navigator key
      if (navigatorKey.currentContext != null) {
        _navigateUsingNavigatorKey(data);
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
    
    switch (notificationType) {
      case 'chat':
        _navigateToChat(context, data);
        break;
      case 'technician_assignment':
        _navigateToTechnicianAssignment(context, data);
        break;
      case 'order_update':
        _navigateToOrderDetails(context, data);
        break;
      case 'job_update':
        _navigateToJobDetails(context, data);
        break;
      case 'appointment':
        _navigateToAppointment(context, data);
        break;
      case 'ticket':
        _navigateToTicketDetails(context, data);
        break;
      default:
        _navigateToHome(context);
    }
  }

  // GetX Navigation Methods
  void _navigateToChatGetX(Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final userId = data['userId'] as String?;
    final userName = data['userName'] as String?;
    
    if (chatId != null) {
      Get.toNamed('/chat', arguments: {
        'chatId': chatId,
        'userId': userId,
        'userName': userName,
      });
    }
  }

  void _navigateToTechnicianAssignmentGetX(Map<String, dynamic> data) {
    final assignmentId = data['assignmentId'] as String?;
    final jobId = data['jobId'] as String?;
    
    if (assignmentId != null || jobId != null) {
      Get.toNamed('/technician-assignment', arguments: {
        'assignmentId': assignmentId,
        'jobId': jobId,
      });
    }
  }

  void _navigateToOrderDetailsGetX(Map<String, dynamic> data) {
    final orderId = data['orderId'] as String?;
    
    if (orderId != null) {
      Get.toNamed('/order-details', arguments: {
        'orderId': orderId,
      });
    }
  }

  void _navigateToJobDetailsGetX(Map<String, dynamic> data) {
    final jobId = data['jobId'] as String?;
    
    if (jobId != null) {
      Get.toNamed('/job-details', arguments: {
        'jobId': jobId,
      });
    }
  }

  void _navigateToAppointmentGetX(Map<String, dynamic> data) {
    final appointmentId = data['appointmentId'] as String?;
    
    if (appointmentId != null) {
      Get.toNamed('/appointment', arguments: {
        'appointmentId': appointmentId,
      });
    }
  }

  void _navigateToTicketDetailsGetX(Map<String, dynamic> data) {
    final ticketId = data['ticketId'] as String?;
    
    if (ticketId != null) {
      Get.toNamed('/ticket-details', arguments: {
        'ticketId': ticketId,
      });
    }
  }

  // Navigator Key Navigation Methods (Original methods with improvements)
  void _navigateToChat(BuildContext context, Map<String, dynamic> data) {
    final chatId = data['chatId'] as String?;
    final userId = data['userId'] as String?;
    final userName = data['userName'] as String?;
    
    if (chatId != null) {
      Navigator.of(context).pushNamed(
        '/chat',
        arguments: {
          'chatId': chatId,
          'userId': userId,
          'userName': userName,
        },
      );
    }
  }

  void _navigateToTechnicianAssignment(BuildContext context, Map<String, dynamic> data) {
    final assignmentId = data['assignmentId'] as String?;
    final jobId = data['jobId'] as String?;
    
    if (assignmentId != null || jobId != null) {
      Navigator.of(context).pushNamed(
        '/technician-assignment',
        arguments: {
          'assignmentId': assignmentId,
          'jobId': jobId,
        },
      );
    }
  }

  void _navigateToOrderDetails(BuildContext context, Map<String, dynamic> data) {
    final orderId = data['orderId'] as String?;
    
    if (orderId != null) {
      Navigator.of(context).pushNamed(
        '/order-details',
        arguments: {
          'orderId': orderId,
        },
      );
    }
  }

  void _navigateToJobDetails(BuildContext context, Map<String, dynamic> data) {
    final jobId = data['jobId'] as String?;
    
    if (jobId != null) {
      Navigator.of(context).pushNamed(
        '/job-details',
        arguments: {
          'jobId': jobId,
        },
      );
    }
  }

  void _navigateToAppointment(BuildContext context, Map<String, dynamic> data) {
    final appointmentId = data['appointmentId'] as String?;
    
    if (appointmentId != null) {
      Navigator.of(context).pushNamed(
        '/appointment',
        arguments: {
          'appointmentId': appointmentId,
        },
      );
    }
  }

  void _navigateToTicketDetails(BuildContext context, Map<String, dynamic> data) {
    final ticketId = data['ticketId'] as String?;
    
    if (ticketId != null) {
      Navigator.of(context).pushNamed(
        '/ticket-details',
        arguments: {
          'ticketId': ticketId,
        },
      );
    }
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (route) => false,
    );
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      debugPrint('Received foreground message: ${message.toMap()}');

      if (notification == null && data.isEmpty) return;

      // Determine which channel to use
      String channelId = _getChannelId(data['type']);
      String channelName = _getChannelName(data['type']);

      // Handle image notification
      String? imageUrl;
      if (notification?.android?.imageUrl != null) {
        imageUrl = notification!.android!.imageUrl;
      } else if (data['image'] != null) {
        imageUrl = data['image'];
      }

      // Create notification details
      final NotificationDetails platformDetails = await _createNotificationDetails(
        channelId: channelId,
        channelName: channelName,
        imageUrl: imageUrl,
      );

      // Show the notification
      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification?.title ?? _getDefaultTitle(data),
        notification?.body ?? _getDefaultBody(data),
        platformDetails,
        payload: jsonEncode(data),
      );
      
      debugPrint('Foreground notification shown successfully');
    } catch (e, stack) {
      debugPrint('Error handling foreground message: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  String _getChannelId(String? type) {
    switch (type) {
      case 'technician_assignment':
      case 'job_update':
        return _techChannelId;
      case 'order_update':
        return _orderChannelId;
      case 'chat':
      default:
        return _chatChannelId;
    }
  }

  String _getChannelName(String? type) {
    switch (type) {
      case 'technician_assignment':
        return 'Technician Assignment';
      case 'job_update':
        return 'Job Update';
      case 'order_update':
        return 'Order Update';
      case 'chat':
      default:
        return 'Chat Notifications';
    }
  }

  Future<NotificationDetails> _createNotificationDetails({
    required String channelId,
    required String channelName,
    String? imageUrl,
  }) async {
    // Android specific settings
    AndroidNotificationDetails androidDetails;
    
    if (imageUrl != null) {
      // Create big picture style for notifications with images
      final bigPictureStyle = BigPictureStyleInformation(
        FilePathAndroidBitmap(imageUrl), // For local files
        // OR use UrlAndroidBitmap for remote images:
        // UriAndroidBitmap(imageUrl),
        largeIcon: FilePathAndroidBitmap(imageUrl),
        contentTitle: channelName,
        htmlFormatContentTitle: true,
        summaryText: '',
        htmlFormatSummaryText: true,
      );

      androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Incoming notifications',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: bigPictureStyle,
        largeIcon: FilePathAndroidBitmap(imageUrl),
        enableVibration: true,
        playSound: true,
        autoCancel: true,
      );
    } else {
      androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Incoming notifications',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
      );
    }

    // iOS specific settings
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
      interruptionLevel: InterruptionLevel.active,
    );

    return NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  String _getDefaultTitle(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'technician_assignment':
        return 'New Assignment';
      case 'order_update':
        return 'Order Update';
      case 'job_update':
        return 'Job Update';
      case 'ticket':
        return 'Ticket Update';
      case 'appointment':
        return 'Appointment Reminder';
      case 'chat':
        return 'New Message';
      default:
        return 'New Notification';
    }
  }

  String _getDefaultBody(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'technician_assignment':
        return 'You have been assigned a new job';
      case 'order_update':
        return 'Your order status has been updated';
      case 'job_update':
        return 'Job status has been updated';
      case 'ticket':
        return 'Ticket has been updated';
      case 'appointment':
        return 'You have an upcoming appointment';
      case 'chat':
        return data['message'] ?? 'You have a new message';
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
    debugPrint('Background message received: ${message.data}');
    
    // Store the notification data for later processing when app opens
    // You might want to save this to local storage or handle it appropriately
    
  } catch (e) {
    debugPrint('Error in background handler: $e');
  }
}