import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/domain/services/firebase_notification.dart';
import 'package:dar_al_safwa/presentation/controllers/network_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenant_dashboard.dart';
import 'package:dar_al_safwa/presentation/view_model/firebase_auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'domain/controller/agent_controller.dart';
import 'domain/controller/user_controller.dart';
import 'firebase_options.dart';
import 'presentation/view/dashboard/widgets/tenants_documents_widget.dart';
import 'presentation/view/dashboard/widgets/tenants_tickets_list_widget.dart';
import 'presentation/view/profile/widgets/technician_profile_page.dart';
import 'presentation/view/profile/widgets/tenant_edit_profile_widget.dart';
import 'presentation/view_model/localization_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Get.put(NetworkController());

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase
  await _initializeFirebase();
  await _initializeNotifications();
  // Initialize controllers
  _initializeControllers();

  // Run the app after authentication check
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

    // Uncomment when ready to use notifications
    // await _initializeNotifications();
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Handle error appropriately for your app
  }
}

Future<void> _initializeNotifications() async {
  try {
    await FirebaseNotificationService().initialize();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  } catch (e) {
    debugPrint('Notification initialization error: $e');
  }
}

void _initializeControllers() {
  Get.put(AgentController(), permanent: true);
  Get.put(UserController(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(LocalizationController(), permanent: true);
}

class MyApp extends StatelessWidget {
  final bool isAuthenticated;

  const MyApp({super.key, required this.isAuthenticated});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: const TextScaler.linear(1),
        devicePixelRatio: 1.0,
      ),
      child: GetMaterialApp(
        title: 'Dar Al Safwa',
        theme: _buildAppTheme(),
        debugShowCheckedModeBanner: false,
        locale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        home: TechnicianProfileScreen(),
        // initialRoute:
        //     isAuthenticated ? AppRoute.navbar : AppRoute.initial, //navbar
        getPages: AppRoute.routes,
        initialBinding: AppBindings(),
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
    Get.lazyPut<LocalizationController>(() => LocalizationController(),
        fenix: true);
  }
}
