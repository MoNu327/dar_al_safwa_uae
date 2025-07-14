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
    fetchDynamicImage();
  }

  /// 🔁 Called after login to redirect user accordingly
  void handlePostLogin() {
  final args = postLoginRedirectArgs;

  if (args != null && args['redirectToBooking'] == true) {
    final propertyId = int.tryParse(args['propertyId']?.toString() ?? '0') ?? 0;

    if (propertyId > 0) {
      // Just go to PropertyDetailsScreen after login
      Get.offNamedUntil(AppRoute.propertyDetails, (route) => false, arguments: {
        'propertyId': propertyId,
      });
    } else {
      Get.offAllNamed(AppRoute.home);
    }
  } else {
    Get.offAllNamed(AppRoute.home);
  }
}


  /// 🔐 Google Sign-In flow
  Future<void> loginWithGoogle() async {
    try {
      isGoogleLoading.value = true;
      debugPrint("Starting Google sign-in");

      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        debugPrint("Google Sign-In canceled by user.");
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      debugPrint("Google sign-in success: ${userCredential.user?.displayName}");

      // ✅ Post-login redirection
      handlePostLogin();
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    } finally {
      isGoogleLoading.value = false;
    }
  }

  /// 🔓 Logout the current user
  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut();
      await _auth.signOut();
      debugPrint("User successfully logged out.");
      Get.offAllNamed(AppRoute.login);
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  /// 🔄 Dynamic image for login UI
  Future<void> fetchDynamicImage() async {
    try {
      isLoading(true);
      errorMessage(null);
      final response = await _service.getDynamicImage();
      debugPrint('🎉 API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseImage = response.data;
        image(responseImage['data']?['image']);
        debugPrint('👌 Image loaded successfully');
      } else {
        debugPrint('😔 Failed to load image: ${response.statusMessage}');
        throw Exception("Failed to load image details");
      }
    } catch (e) {
      debugPrint('😔 Error in fetching image: $e');
      errorMessage(e.toString());
    } finally {
      isLoading(false);
      debugPrint('fetchDynamicImage completed');
    }
  }

  void navigateToHome() {
    Get.toNamed(AppRoute.navbar);
  }

  void navigateToMobileLogin() {
    Get.toNamed(AppRoute.mobileLogin);
  }

  void navigateToBack() {
    Get.back();
  }

  void navigateToSignup() {
    Get.toNamed(AppRoute.signup);
  }

  void navigateToAgentLogin() {
    Get.toNamed(AppRoute.signin, arguments: {'isAgentSignIn': true});
  }

  void navigateToTechnicianLogin() {
    Get.toNamed(AppRoute.signin, arguments: {'isAgentSignIn': false});
  }
}
