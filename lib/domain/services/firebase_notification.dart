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

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _authSubscription;
  StreamSubscription? _tokenRefreshSubscription;

  Future<void> initialize() async {
    try {
      // Initialize notification infrastructure
      await _requestPermissions();
      await _initLocalNotifications();

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Start listening for auth state changes
      _setupAuthStateListener();
    } catch (e) {
      debugPrint('Error initializing Firebase notifications: $e');
    }
  }

  void _setupAuthStateListener() {
    // Cancel any existing subscription
    _authSubscription?.cancel();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _handleAuthStateChange(user!);
    });
  }

  Future<void> _handleAuthStateChange(User user) async {
    // Clean up previous token if user logged out

    await _cleanupToken();

    // User is logged in - setup token management

    await _setupTokenManagement(user);
  }

  Future<void> _setupTokenManagement(User user) async {
    _tokenRefreshSubscription?.cancel();

    // Force token refresh by deleting old token first
    await _forceTokenRefresh(user);

    // Listen for automatic token refreshes
    _tokenRefreshSubscription =
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken, user);
    });
  }

  Future<void> _forceTokenRefresh(User user) async {
    try {
      // Delete the old token
      await _firebaseMessaging.deleteToken();
      debugPrint('Successfully deleted old FCM token');

      // Get new token
      final token = await _firebaseMessaging.getToken();
      debugPrint('New FCM token generated: $token');

      // Save to Firestore
      await _saveTokenToFirestore(token, user);
    } catch (e) {
      debugPrint('Error forcing token refresh: $e');
    }
  }

  Future<void> _cleanupToken() async {
    debugPrint("deleting fcm token");
    // Cancel token refresh subscription
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    // Optionally delete the token from server
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
      final collectionName = user.displayName != null ? 'users' : 'agents';
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

  Future<void> _requestPermissions() async {
    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings();

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _flutterLocalNotificationsPlugin.initialize(settings);
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final data = message.data;

      if (notification == null && data.isEmpty) return;

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'chat_channel',
        'Chat Notifications',
        channelDescription: 'Incoming chat messages',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        notification?.title ?? 'New Message',
        notification?.body ?? data['message'] ?? '',
        platformDetails,
        payload: jsonEncode(data),
      );
    } catch (e, stack) {
      debugPrint('Error handling foreground message: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  Future<void> dispose() async {
    _authSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    final service = FirebaseNotificationService();
    await service._handleForegroundMessage(message);
  } catch (e) {
    debugPrint('Error in background handler: $e');
  }
}
