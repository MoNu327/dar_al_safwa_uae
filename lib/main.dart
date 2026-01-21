// import 'package:firebase_app_check/firebase_app_check.dart';
// import 'package:flutter/foundation.dart';
// import 'package:majan/core/theme/app_colors.dart';
// import 'package:majan/core/routes/app_route.dart';
// import 'package:majan/domain/controller/technician_controller.dart';
// import 'package:majan/domain/services/firebase_notification.dart';
// import 'package:majan/presentation/controllers/network_controller.dart';
// import 'package:majan/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
// import 'package:majan/presentation/view/profile/controller/profile_controller.dart';
// import 'package:majan/presentation/view/search/controllers/search_screen_controller.dart';
// import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';
// import 'domain/controller/agent_controller.dart';
// import 'domain/controller/user_controller.dart';
// import 'firebase_options.dart';
// import 'presentation/view_model/localization_controller.dart';
// late FirebaseNotificationService notificationService;
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);
//   await _initializeFirebase();
//   await _initializeNotifications();

//   _initializeControllers();
//   runApp(
//     FutureBuilder<User?>(
//       future: FirebaseAuth.instance.authStateChanges().first,
//       builder: (context, snapshot) {
//         return MyApp(
//           isAuthenticated: snapshot.hasData && snapshot.data != null,
//         );
//       },
//     ),
//   );
// }

// Future<void> _initializeFirebase() async {
//   try {
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     // 🆕 SMART APP CHECK SETUP - WORKS FOR BOTH TESTING & PRODUCTION
//     await _initializeAppCheck();
//     debugPrint('Firebase initialized successfully');
//   } catch (e) {
//     debugPrint('Firebase initialization error: $e');
//   }
// }

// Future<void> _initializeAppCheck() async {
//   try {
//     if (kReleaseMode) {
//       // 🚀 PRODUCTION MODE - Play Store & App Store
//       await FirebaseAppCheck.instance.activate(
//         androidProvider: AndroidProvider.playIntegrity,
//         appleProvider: AppleProvider.deviceCheck,
//       );
//       debugPrint('App Check: PRODUCTION mode (Play Integrity + DeviceCheck)');
//     } else {
//       // 🧪 DEVELOPMENT/TESTING MODE - Debug providers
//       await FirebaseAppCheck.instance.activate(
//         androidProvider: AndroidProvider.debug,
//         appleProvider: AppleProvider.debug,
//       );
//       debugPrint('App Check: DEVELOPMENT mode (Debug providers)');

//       // Get debug tokens for testing
//       _setupDebugTokenListener();
//     }
//   } catch (e) {
//     debugPrint('App Check initialization error: $e');
//   }
// }

// void _setupDebugTokenListener() {
//   // Listen for debug tokens in development
//   FirebaseAppCheck.instance.onTokenChange.listen((token) {
//     debugPrint('🎯 App Check Debug Token: $token');
//     debugPrint(
//         '📝 Add this token to Firebase Console → App Check → Manage debug tokens');
//   });
// }

// Future<void> _initializeNotifications() async {
//   try {
//     notificationService =
//         FirebaseNotificationService(navigatorKey: navigatorKey);
//     await notificationService.initialize();
//     const AndroidNotificationChannel channel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       description: 'This channel is used for important notifications.',
//       importance: Importance.max,
//       playSound: true,
//       enableVibration: true,
//     );

//     final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
//         FlutterLocalNotificationsPlugin();

//     await flutterLocalNotificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.createNotificationChannel(channel);

//     debugPrint('Notifications initialized successfully');
//   } catch (e) {
//     debugPrint('Notification initialization error: $e');
//   }
// }

// void _initializeControllers() {
//   Get.put(NetworkController(), permanent: true);
//   Get.put(AgentController(), permanent: true);
//   Get.put(UserController(), permanent: true);
//   Get.put(AuthService(), permanent: true);
//   Get.put(LocalizationController(), permanent: true);
//   Get.put(TechnicianController(), permanent: true);
//   Get.put(TenantsTicketsController(), permanent: true);
//   Get.put(SearchScreenController(), permanent: true);
//   Get.put(ProfileController(), permanent: true);
//   debugPrint('Controllers initialized successfully');
// }

// class MyApp extends StatefulWidget {
//   final bool isAuthenticated;

//   const MyApp({super.key, required this.isAuthenticated});

//   @override
//   State<MyApp> createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _setupAppLifecycleHandling();
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     notificationService.dispose();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     switch (state) {
//       case AppLifecycleState.resumed:
//         debugPrint('App resumed - checking for pending notifications');
//         _handleAppResume();
//         break;
//       case AppLifecycleState.paused:
//         debugPrint('App paused');
//         break;
//       case AppLifecycleState.detached:
//         debugPrint('App detached');
//         break;
//       case AppLifecycleState.inactive:
//         debugPrint('App inactive');
//         break;
//       case AppLifecycleState.hidden:
//         debugPrint('App hidden');
//         break;
//     }
//   }

//   void _setupAppLifecycleHandling() {
//     debugPrint('App lifecycle handling setup complete');
//   }

//   void _handleAppResume() {}

//   @override
//   Widget build(BuildContext context) {
//     return MediaQuery(
//       data: MediaQuery.of(context).copyWith(
//         textScaler: const TextScaler.linear(1),
//         devicePixelRatio: 1.0,
//       ),
//       child: GetMaterialApp(
//         title: 'Dar Al Safwa',
//         theme: _buildAppTheme(),
//         debugShowCheckedModeBanner: false,
//         locale: const Locale('en'),
//         fallbackLocale: const Locale('en'),
//         navigatorKey: navigatorKey,
//         defaultTransition: Transition.fadeIn,
//         transitionDuration: const Duration(milliseconds: 300),
//         initialRoute:
//             widget.isAuthenticated ? AppRoute.navbar : AppRoute.initial,
//         getPages: AppRoute.routes,
//         initialBinding: AppBindings(),
//         navigatorObservers: [
//           NotificationNavigationObserver(),
//         ],
//         unknownRoute: GetPage(
//           name: '/unknown',
//           page: () => const Scaffold(
//             body: Center(
//               child: Text('Page not found'),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   ThemeData _buildAppTheme() {
//     return ThemeData(
//       scaffoldBackgroundColor: AppColors.white,
//       appBarTheme: const AppBarTheme(
//         color: AppColors.primaryColor,
//         systemOverlayStyle: SystemUiOverlayStyle(
//           statusBarColor: Colors.transparent,
//           statusBarIconBrightness: Brightness.dark,
//         ),
//       ),
//       primaryColor: AppColors.primaryColor,
//       colorScheme: ColorScheme.fromSeed(
//         seedColor: AppColors.secondaryColor,
//         brightness: Brightness.light,
//       ),
//       useMaterial3: true,
//     );
//   }
// }

// class AppBindings extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
//     Get.lazyPut<AgentController>(() => AgentController(), fenix: true);
//     Get.lazyPut<UserController>(() => UserController(), fenix: true);
//     Get.lazyPut<LocalizationController>(() => LocalizationController(),
//         fenix: true);
//     Get.lazyPut<TechnicianController>(() => TechnicianController(),
//         fenix: true);
//     Get.lazyPut<TenantsTicketsController>(() => TenantsTicketsController(),
//         fenix: true);
//     Get.put(notificationService, permanent: true);
//     Get.put(TenantsTicketsController(), permanent: true);
//     Get.put(notificationService, permanent: true);
//     Get.put(ProfileController(), permanent: true);
//   }
// }

// class NotificationNavigationObserver extends NavigatorObserver {
//   @override
//   void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
//     super.didPush(route, previousRoute);
//     debugPrint('Navigation: Pushed ${route.settings.name}');
//     if (route.settings.arguments != null) {
//       debugPrint('Navigation: Route arguments: ${route.settings.arguments}');
//     }
//   }

//   @override
//   void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
//     super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
//     debugPrint(
//         'Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
//   }

//   @override
//   void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
//     super.didPop(route, previousRoute);
//     debugPrint('Navigation: Popped ${route.settings.name}');
//   }

//   @override
//   void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
//     super.didRemove(route, previousRoute);
//     debugPrint('Navigation: Removed ${route.settings.name}');
//   }
// }


import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/core/utils/auto_update_services.dart';
import 'package:majan/domain/controller/technician_controller.dart';
import 'package:majan/domain/services/firebase_notification.dart';
import 'package:majan/presentation/controllers/network_controller.dart';
import 'package:majan/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
import 'package:majan/presentation/view/profile/controller/profile_controller.dart';
import 'package:majan/presentation/view/search/controllers/search_screen_controller.dart';
import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:upgrader/upgrader.dart';
import 'dart:io'; // ✅ ADD THIS
import 'domain/controller/agent_controller.dart';
import 'domain/controller/user_controller.dart';
import 'firebase_options.dart';
import 'presentation/view_model/localization_controller.dart';

// ✅ Required imports
import 'package:majan/data/repositories/api_services.dart';
import 'package:majan/domain/controller/notification_controller.dart';
import 'package:get_storage/get_storage.dart';

late FirebaseNotificationService notificationService;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // ✅ Initialize GetStorage first
  await GetStorage.init();
  
  await _initializeFirebase();
  
  // ✅ CRITICAL: Initialize core dependencies BEFORE notifications
  await _initializeCoreDependencies();
  
  await _initializeNotifications();

  _initializeControllers();
  
  runApp(
    FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        return MyApp(
          isAuthenticated: snapshot.hasData && snapshot.data != null,
        );
      },
    ),
  );
}

// ✅ Initialize core dependencies first
Future<void> _initializeCoreDependencies() async {
  try {
    debugPrint('🔧 Initializing core dependencies...');
    
    // 1️⃣ ApiService - Required by TokenHandler
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService(), permanent: true);
      debugPrint('✅ ApiService initialized');
    }
    
    // 2️⃣ NotificationController - Required by many controllers
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
      debugPrint('✅ NotificationController initialized');
    }
    
    debugPrint('✅ Core dependencies initialized successfully');
  } catch (e) {
    debugPrint('❌ Core dependencies initialization error: $e');
  }
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // 🆕 SMART APP CHECK SETUP - WORKS FOR BOTH TESTING & PRODUCTION
    await _initializeAppCheck();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

Future<void> _initializeAppCheck() async {
  try {
    if (kReleaseMode) {
      // 🚀 PRODUCTION MODE - Play Store & App Store
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.playIntegrity,
        appleProvider: AppleProvider.deviceCheck,
      );
      debugPrint('App Check: PRODUCTION mode (Play Integrity + DeviceCheck)');
    } else {
      // 🧪 DEVELOPMENT/TESTING MODE - Debug providers
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
      debugPrint('App Check: DEVELOPMENT mode (Debug providers)');

      // Get debug tokens for testing
      _setupDebugTokenListener();
    }
  } catch (e) {
    debugPrint('App Check initialization error: $e');
  }
}

void _setupDebugTokenListener() {
  // Listen for debug tokens in development
  FirebaseAppCheck.instance.onTokenChange.listen((token) {
    debugPrint('🎯 App Check Debug Token: $token');
    debugPrint(
        '📝 Add this token to Firebase Console → App Check → Manage debug tokens');
  });
}

Future<void> _initializeNotifications() async {
  try {
    // ✅ Double-check dependencies exist before notification service
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService(), permanent: true);
      debugPrint('⚠️ ApiService not found, initializing now');
    }
    
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
      debugPrint('⚠️ NotificationController not found, initializing now');
    }
    
    notificationService =
        FirebaseNotificationService(navigatorKey: navigatorKey);
    await notificationService.initialize();
    
    // ✅ FIXED: Android notification channel setup
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(channel);
        debugPrint('✅ Android notification channel created');
      }
    }

    debugPrint('✅ Notifications initialized successfully');
  } catch (e) {
    debugPrint('❌ Notification initialization error: $e');
  }
}

void _initializeControllers() {
  try {
    debugPrint('🔧 Initializing controllers...');
    
    Get.put(NetworkController(), permanent: true);
    Get.put(AgentController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.put(LocalizationController(), permanent: true);
    Get.put(TechnicianController(), permanent: true);
    Get.put(TenantsTicketsController(), permanent: true);
    Get.put(SearchScreenController(), permanent: true);
    Get.put(ProfileController(), permanent: true);
    
    debugPrint('✅ Controllers initialized successfully');
  } catch (e) {
    debugPrint('❌ Controllers initialization error: $e');
  }
}

class MyApp extends StatefulWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupAppLifecycleHandling();
      _checkForUpdates(); // ✅ Check for updates on app launch
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    notificationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('App resumed - checking for pending notifications');
        _handleAppResume();
        _checkForUpdates(); // ✅ Check for updates when app resumes
        break;
      case AppLifecycleState.paused:
        debugPrint('App paused');
        break;
      case AppLifecycleState.detached:
        debugPrint('App detached');
        break;
      case AppLifecycleState.inactive:
        debugPrint('App inactive');
        break;
      case AppLifecycleState.hidden:
        debugPrint('App hidden');
        break;
    }
  }

  void _setupAppLifecycleHandling() {
    debugPrint('App lifecycle handling setup complete');
  }

  void _handleAppResume() {}

  // ✅ NEW METHOD: Check for app updates
  Future<void> _checkForUpdates() async {
    try {
      // Delay to avoid blocking app startup
      await Future.delayed(const Duration(seconds: 3));
      await AppUpdateService().checkForUpdates();
    } catch (e, stackTrace) {
      debugPrint('❌ Update check error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
        devicePixelRatio: 1.0,
      ),
      // ✅ FIXED: Simplified UpgradeAlert - only for iOS
      child: Platform.isIOS
          ? UpgradeAlert(
              upgrader: Upgrader(
                durationUntilAlertAgain: const Duration(days: 1),
              ),
              child: _buildGetMaterialApp(),
            )
          : _buildGetMaterialApp(), // Android uses in_app_update instead
    );
  }

  // ✅ Extracted GetMaterialApp to avoid duplication
  Widget _buildGetMaterialApp() {
    return GetMaterialApp(
      title: 'Dar Al Safwa',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      fallbackLocale: const Locale('en'),
      navigatorKey: navigatorKey,
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),
      initialRoute:
          widget.isAuthenticated ? AppRoute.navbar : AppRoute.initial,
      getPages: AppRoute.routes,
      initialBinding: AppBindings(),
      navigatorObservers: [
        NotificationNavigationObserver(),
      ],
      unknownRoute: GetPage(
        name: '/unknown',
        page: () => const Scaffold(
          body: Center(
            child: Text('Page not found'),
          ),
        ),
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.white,
      appBarTheme: const AppBarTheme(
        color: AppColors.primaryColor,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      primaryColor: AppColors.primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.secondaryColor,
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );
  }
}

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // ✅ Ensure core dependencies are available
    if (!Get.isRegistered<ApiService>()) {
      Get.put(ApiService(), permanent: true);
    }
    
    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
    }
    
    // Lazy load controllers
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<AgentController>(() => AgentController(), fenix: true);
    Get.lazyPut<UserController>(() => UserController(), fenix: true);
    Get.lazyPut<LocalizationController>(() => LocalizationController(),
        fenix: true);
    Get.lazyPut<TechnicianController>(() => TechnicianController(),
        fenix: true);
    Get.lazyPut<TenantsTicketsController>(() => TenantsTicketsController(),
        fenix: true);
    Get.lazyPut<ProfileController>(() => ProfileController(), fenix: true);
    
    // Put notification service
    if (!Get.isRegistered<FirebaseNotificationService>()) {
      Get.put(notificationService, permanent: true);
    }
  }
}

class NotificationNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    debugPrint('Navigation: Pushed ${route.settings.name}');
    if (route.settings.arguments != null) {
      debugPrint('Navigation: Route arguments: ${route.settings.arguments}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    debugPrint(
        'Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    debugPrint('Navigation: Popped ${route.settings.name}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    debugPrint('Navigation: Removed ${route.settings.name}');
  }
}
