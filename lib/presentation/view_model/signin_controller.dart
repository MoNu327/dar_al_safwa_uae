import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:get/get.dart';

class SigninController extends GetxController {
  var isPasswordVisible = true.obs;

  // Method to toggle password visibility
  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // Methods for navigation
  void navigateToHomeScreen() {
    Get.toNamed(AppRoute.home);
  }

  void navigateToSignUp() {
    Get.offNamed(AppRoute.signup);
  }
}
