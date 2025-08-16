import 'package:majan/core/routes/app_route.dart';
import 'package:get/get.dart';

class SignupController extends GetxController {
  var isPasswordObscured = true.obs;
  var isTermsAccepted = false.obs;
  var selectedCountryCode = '+1'.obs;
  final List<String> countryCodes = ['+1', '+44', '+91'];

  // Method to toggle password visibility
  void togglePasswordVisibility() {
    isPasswordObscured.value = !isPasswordObscured.value;
  }

  // Method for control checkbox
  void toggleTermsAcceptance(bool? value) {
    if (value != null) {
      isTermsAccepted.value = value;
    }
  }

  // Method to change selected country code
  void changeCountryCode(String? newCode) {
    if (newCode != null) {
      selectedCountryCode.value = newCode;
    }
  }

  // Method to navigate login
  void navigateToSignin() {
    Get.offNamed(AppRoute.signin);
  }
}
