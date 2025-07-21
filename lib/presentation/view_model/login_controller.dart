import 'dart:convert';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dar_al_safwa/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:dar_al_safwa/presentation/view/property_details/widgets/user_details_submission.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ApiService _service = ApiService();

  Rx<bool> isGoogleLoading = false.obs;
  final image = Rx<String?>(null);
  final errorMessage = Rx<String?>(null);
  final isLoading = false.obs;

  /// 🔁 Holds redirection info after login
  Map<String, dynamic>? postLoginRedirectArgs;

  @override
  void onInit() {
    super.onInit();
    debugPrint("🔄 LoginController initialized.");
    fetchDynamicImage();
  }

  /// 🔁 Called after login to redirect user accordingly
  void handlePostLogin() {
    debugPrint("🔁 handlePostLogin called.");
    final args = postLoginRedirectArgs;
    debugPrint("PostLoginRedirectArgs: $args");

    if (args != null && args['redirectToBooking'] == true) {
      final propertyId = int.tryParse(args['propertyId']?.toString() ?? '0') ?? 0;
      debugPrint("Redirecting to property details with propertyId: $propertyId");

      if (propertyId > 0) {
        Get.offNamedUntil(AppRoute.propertyDetails, (route) => false, arguments: {
          'propertyId': propertyId,
        });
      } else {
        debugPrint("PropertyId is invalid. Redirecting to navbar.");
        Get.offAllNamed(AppRoute.navbar);
      }
    } else {
      debugPrint("No redirect arguments found. Navigating to navbar.");
      Get.offAllNamed(AppRoute.navbar);
    }
  }

  /// 🔐 Google Sign-In flow
  Future<void> loginWithGoogle() async {
    debugPrint("🔐 Starting loginWithGoogle");
    try {
      isGoogleLoading.value = true;
      debugPrint("Google loading state: ${isGoogleLoading.value}");

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      debugPrint("GoogleSignIn user: $googleUser");

      if (googleUser == null) {
        debugPrint("❌ Google Sign-In canceled by user.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint("Google AccessToken: ${googleAuth.accessToken}");
      debugPrint("Google IdToken: ${googleAuth.idToken}");

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint("✅ Google sign-in success: ${userCredential.user?.displayName}");
      debugPrint("User UID: ${userCredential.user?.uid}");
      debugPrint("User Email: ${userCredential.user?.email}");

      // ✅ Post-login redirection
      handlePostLogin();
    } catch (e) {
      debugPrint("❌ Error signing in with Google: $e");
    } finally {
      isGoogleLoading.value = false;
      debugPrint("Google loading state set to: ${isGoogleLoading.value}");
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
