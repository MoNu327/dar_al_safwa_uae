import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:majan/presentation/view/property_details/widgets/user_details_submission.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _service = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Rx<bool> isGoogleLoading = false.obs;
  final image = Rx<String?>(null);
  final errorMessage = Rx<String?>(null);
  final isLoading = false.obs;
  final isGoogleSigningIn = false.obs;

  /// 🔁 Holds redirection info after login
  Map<String, dynamic>? postLoginRedirectArgs;

  @override
  void onInit() {
    super.onInit();
    debugPrint("🔄 LoginController initialized.");
    fetchDynamicImage();
  }

  /// Get platform information
  String _getPlatformInfo() {
    if (Platform.isIOS) {
      return 'ios';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isMacOS) {
      return 'macos';
    } else if (Platform.isLinux) {
      return 'linux';
    } else {
      return 'web';
    }
  }

  /// Log user activity after successful login
  Future<void> logLoginActivity(String uid) async {
    try {
      debugPrint('📊 [logLoginActivity] Starting for user: $uid');

      // Determine which collection the user belongs to
      String collection = 'users';
      
      // Check if user is an agent
      final agentDoc = await _firestore.collection('agents').doc(uid).get();
      if (agentDoc.exists && agentDoc.data()?['role'] == 'agent') {
        collection = 'agents';
      } else {
        // Check if user is a technician
        final techDoc = await _firestore.collection('technicians').doc(uid).get();
        if (techDoc.exists && techDoc.data()?['role'] == 'technician') {
          collection = 'technicians';
        }
      }

      // Fetch user document to get platform data
      final userDoc = await _firestore.collection(collection).doc(uid).get();

      String mode;
      String modeUpdated;

      if (userDoc.exists) {
        final userData = userDoc.data();
        mode = userData?['mode'] ?? _getPlatformInfo();
        modeUpdated = userData?['modeupdated'] ?? _getPlatformInfo();
        debugPrint('✅ [logLoginActivity] Platform data from $collection - mode: $mode, modeupdated: $modeUpdated');
      } else {
        // Fallback to detected platform
        mode = _getPlatformInfo();
        modeUpdated = _getPlatformInfo();
        debugPrint('⚠️ [logLoginActivity] Using detected platform: $mode');
      }

      // Call the API
      debugPrint('🔄 [logLoginActivity] Calling API...');
      final response = await _service.getuserlogactivity(uid, mode, modeUpdated);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [logLoginActivity] Login activity logged successfully');
        debugPrint('📦 [logLoginActivity] Response: ${response.data}');
      } else {
        debugPrint('⚠️ [logLoginActivity] Failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [logLoginActivity] Error: $e');
      debugPrint('📝 [logLoginActivity] Stack trace: $stackTrace');
      // Don't block login flow if logging fails
    }
  }

  /// 🔓 Logout the current user
  Future<void> logout() async {
    debugPrint("🔓 Logging out user...");
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      debugPrint("✅ User successfully logged out.");
      Get.offAllNamed(AppRoute.login);
    } catch (e) {
      debugPrint("❌ Error signing out: $e");
    }
  }

  /// 🔄 Dynamic image for login UI
  Future<void> fetchDynamicImage() async {
    debugPrint("📸 fetchDynamicImage called.");
    try {
      isLoading(true);
      errorMessage(null);
      debugPrint("Loading dynamic image...");

      final response = await _service.getDynamicImage();
      debugPrint('🎉 API response status: ${response.statusCode}');
      debugPrint('🎉 API response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseImage = response.data;
        image(responseImage['data']?['image']);
        debugPrint('👌 Image loaded successfully: ${image.value}');
      } else {
        debugPrint('😔 Failed to load image: ${response.statusMessage}');
        throw Exception("Failed to load image details");
      }
    } catch (e) {
      debugPrint('❌ Error in fetching image: $e');
      errorMessage(e.toString());
    } finally {
      isLoading(false);
      debugPrint('fetchDynamicImage completed. isLoading = ${isLoading.value}');
    }
  }

  /// Navigation methods
  void navigateToHome() {
    debugPrint("➡ Navigating to Home");
    Get.toNamed(AppRoute.navbar);
  }

  void navigateToMobileLogin() {
    debugPrint("➡ Navigating to Mobile Login");
    Get.toNamed(AppRoute.mobileLogin);
  }

  void navigateToBack() {
    debugPrint("⬅ Navigating Back");
    Get.back();
  }

  void navigateToSignup() {
    debugPrint("➡ Navigating to Signup");
    Get.toNamed(AppRoute.signup);
  }

  void navigateToAgentLogin() {
    debugPrint("➡ Navigating to Agent Login");
    Get.toNamed(AppRoute.signin, arguments: {'isAgentSignIn': true});
  }

  void navigateToTechnicianLogin() {
    debugPrint("➡ Navigating to Technician Login");
    Get.toNamed(AppRoute.signin, arguments: {'isAgentSignIn': false});
  }
}