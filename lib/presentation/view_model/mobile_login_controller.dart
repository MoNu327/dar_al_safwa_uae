import 'package:country_code_picker/country_code_picker.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:get/get.dart';

class MobileLoginController extends GetxController {
  // final List<String> countryCodes = ['+1', '+44', '+91', '+33', '+61'].obs;
  var selectedCountryCode = '+968'.obs;

// Method to change the country code
  // void changeCountryCode(String newCode) {
  //   selectedCountryCode.value = newCode;
  // }

  // Method to change the country code
  void changeCountryCode(CountryCode newCode) {
    selectedCountryCode.value = newCode.dialCode ?? '';
  }

  // Method for navigation
  void navigateToBack() {
    Get.back();
  }

  void navigateToHome() {
    Get.toNamed(AppRoute.home);
  }

  void navigateToMobileLoginOtp() {
    Get.toNamed(AppRoute.mobileLoginOtp);
  }
}
