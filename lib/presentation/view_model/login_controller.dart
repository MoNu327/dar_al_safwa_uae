import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Rx<bool> isGoogleLoading = false.obs;

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
