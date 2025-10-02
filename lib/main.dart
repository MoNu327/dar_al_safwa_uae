import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/domain/controller/technician_controller.dart';
import 'package:majan/domain/services/firebase_notification.dart';
import 'package:majan/presentation/controllers/network_controller.dart';
import 'package:majan/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
import 'package:majan/presentation/view/profile/controller/profile_controller.dart';
import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'domain/controller/agent_controller.dart';
import 'domain/controller/user_controller.dart';
import 'firebase_options.dart';
import 'presentation/view_model/localization_controller.dart';
late FirebaseNotificationService notificationService;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, 
  ]);
  await _initializeFirebase();
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

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
}

Future<void> _initializeNotifications() async {
  try {
    notificationService = FirebaseNotificationService(navigatorKey: navigatorKey);
    await notificationService.initialize();
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

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('Notifications initialized successfully');
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }
}

void _initializeControllers() {

  Get.put(NetworkController(), permanent: true);
  Get.put(AgentController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(LocalizationController(), permanent: true);
  Get.put(TechnicianController(), permanent: true);
  Get.put(TenantsTicketsController(), permanent: true);
  Get.put(ProfileController(), permanent: true);
  
  debugPrint('Controllers initialized successfully');
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

  void _handleAppResume() {
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
        devicePixelRatio: 1.0,
      ),
      child: GetMaterialApp(
        title: 'Majan',
        theme: _buildAppTheme(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        navigatorKey: navigatorKey,
        defaultTransition: Transition.fadeIn,
        transitionDuration: const Duration(milliseconds: 300),
        initialRoute: widget.isAuthenticated ? AppRoute.navbar : AppRoute.initial,
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
    Get.lazyPut<AuthService>(() => AuthService(), fenix: true);
    Get.lazyPut<AgentController>(() => AgentController(), fenix: true);
    Get.lazyPut<UserController>(() => UserController(), fenix: true);
    Get.lazyPut<LocalizationController>(() => LocalizationController(), fenix: true);
    Get.lazyPut<TechnicianController>(() => TechnicianController(), fenix: true);
    Get.put(TenantsTicketsController(), permanent: true);
    Get.put(notificationService, permanent: true);
      Get.put(ProfileController(), permanent: true);

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
    debugPrint('Navigation: Replaced ${oldRoute?.settings.name} with ${newRoute?.settings.name}');
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