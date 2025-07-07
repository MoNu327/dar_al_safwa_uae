import 'dart:convert';

import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
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

  @override
  void onInit() {
    super.onInit();
    // Set initial value

    fetchDynamicImage();
    // Or do something async:
    // fetchUserProfilePicture();
  }

// Google sing-in
  Future<void> loginWithGoogle() async {
    try {
      isGoogleLoading.value = true;
      debugPrint("Starting Google sign-in");
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        // The user canceled the login flow
        debugPrint("Google Sign-In canceled by user.");
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      debugPrint("Google sign-in success: ${userCredential.user?.displayName}");

      navigateToHome();
    } catch (e) {
      debugPrint("Error signing in with Google: $e");
    } finally {
      isGoogleLoading.value = false;
    }
  }

  // Logout function
  Future<void> logout() async {
    try {
      await GoogleSignIn().signOut(); // Sign out from Google
      await _auth.signOut(); // Sign out from Firebase
      debugPrint("User successfully logged out.");

      // Navigate to login screen after logout
      Get.offAllNamed(AppRoute.login);
    } catch (e) {
      debugPrint("Error signing out: $e");
    }
  }

  Future<void> fetchDynamicImage() async {
    try {
      isLoading(true);
      errorMessage(null);

      final response = await _service.getDynamicImage();
      debugPrint('🎉 API response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // ❗ No jsonDecode here, because Dio has already decoded it
        final responseImage = response.data;

        debugPrint("🔔 property response: ${responseImage['data']?['image']}");
        image(responseImage['data']?['image']);
        debugPrint(
            '👌 Image loaded successfully: ${responseImage['data']?['image']}');
      } else {
        debugPrint(
            '😔 Failed to load image details: ${response.statusMessage}');
        throw Exception("Failed to load image details");
      }
    } catch (e) {
      debugPrint('😔 Error in fetching image: $e');
      errorMessage(e.toString());
    } finally {
      isLoading(false);
      debugPrint('fetchPropertyDetails completed');
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
