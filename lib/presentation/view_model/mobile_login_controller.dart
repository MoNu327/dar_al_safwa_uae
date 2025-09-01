import 'package:country_code_picker/country_code_picker.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/core/utils/sms_services.dart';
import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class MobileLoginController extends GetxController {
  // Dependencies
  // final AuthService _authService = Get.find<AuthService>();
  final SmsService _smsService = Get.put(SmsService()); // Add SMS service
  
  // Observable variables
  var selectedCountryCode = '+968'.obs;
  var isLoading = false.obs;
  var currentPhoneNumber = ''.obs;
  var verificationId = ''.obs; // Can keep for consistency, but won't use Firebase ID
  
  // Text controllers
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  
  @override
  void onClose() {
    mobileNumberController.dispose();
    otpController.dispose();
    fullNameController.dispose();
    super.onClose();
  }
  
  // Method to change the country code
  void changeCountryCode(CountryCode newCode) {
    selectedCountryCode.value = newCode.dialCode ?? '';
  }
  
  // Validate phone number
  bool _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      Get.snackbar('Error', 'Please enter your mobile number');
      return false;
    }
    
    if (phoneNumber.length < 10 || phoneNumber.length > 15) {
      Get.snackbar('Error', 'Please enter a valid mobile number');
      return false;
    }
    
    return true;
  }
  
  // Send OTP using your SMS Service instead of Firebase
  Future<void> sendOtp() async {
    try {
      isLoading.value = true;
      
      final phoneNumber = '${selectedCountryCode.value}${mobileNumberController.text.trim()}';
      
      if (!_validatePhoneNumber(mobileNumberController.text.trim())) {
        return;
      }
      
      currentPhoneNumber.value = phoneNumber;
      
      // Use your SMS service instead of Firebase
      final success = await _smsService.sendOtp(phoneNumber: phoneNumber);
      
      if (success) {
        // Navigate to OTP screen
        Get.toNamed(AppRoute.mobileLoginOtp, arguments: {
          'phoneNumber': phoneNumber,
        });
      }
      
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      Get.snackbar('Error', 'Failed to send OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Verify OTP using your SMS Service instead of Firebase
  Future<void> verifyOtp() async {
    try {
      isLoading.value = true;
      
      final enteredOtp = otpController.text.trim();
      
      if (enteredOtp.isEmpty) {
        Get.snackbar('Error', 'Please enter the OTP');
        return;
      }
      
      if (enteredOtp.length != 6) {
        Get.snackbar('Error', 'Please enter a valid 6-digit OTP');
        return;
      }
      
      // Verify OTP with your SMS service
      final isValidOtp = _smsService.verifyOtp(enteredOtp);
      
      if (isValidOtp) {
        // Handle successful verification
        // You might want to create user account or login here
        if (fullNameController.text.trim().isNotEmpty) {
          // Handle new user registration
          await _handleNewUserRegistration();
        } else {
          // Handle existing user login
          await _handleExistingUserLogin();
        }
        
        // Clear sensitive data
        _clearControllers();
        
        // Navigate to home
        navigateToHome();
        debugPrint('Phone verification successful');
      }
      
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      Get.snackbar('Error', 'Invalid OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Handle new user registration
  Future<void> _handleNewUserRegistration() async {
    // Implement your user registration logic here
    // You might want to save user data to your backend/database
    debugPrint('Registering new user: ${fullNameController.text.trim()}');
    debugPrint('Phone number: ${currentPhoneNumber.value}');
    
    // Example:
    // await _authService.registerNewUser(
    //   name: fullNameController.text.trim(),
    //   phoneNumber: currentPhoneNumber.value,
    // );
  }
  
  // Handle existing user login
  Future<void> _handleExistingUserLogin() async {
    // Implement your existing user login logic here
    debugPrint('Logging in existing user with phone: ${currentPhoneNumber.value}');
    
    // Example:
    // await _authService.loginExistingUser(
    //   phoneNumber: currentPhoneNumber.value,
    // );
  }
  
  // Resend OTP using your SMS Service
  Future<void> resendOtp() async {
    if (currentPhoneNumber.value.isEmpty) {
      Get.snackbar('Error', 'Phone number not found. Please go back and try again.');
      return;
    }
    
    try {
      isLoading.value = true;
      
      final success = await _smsService.resendOtp(currentPhoneNumber.value);
      
      if (success) {
        Get.snackbar(
          'Success', 
          'OTP has been resent to ${currentPhoneNumber.value}',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[800],
        );
      }
      
    } catch (e) {
      debugPrint('Error resending OTP: $e');
      Get.snackbar('Error', 'Failed to resend OTP. Please try again.');
    } finally {
      isLoading.value = false;
    }
  }
  
  // Clear all controllers
  void _clearControllers() {
    otpController.clear();
    mobileNumberController.clear();
    fullNameController.clear();
    currentPhoneNumber.value = '';
    verificationId.value = '';
    _smsService.clearOtpData(); // Clear SMS service data
  }
  
  // Check if resend is enabled (you'll need to implement this in SMS service)
  bool get canResend => !_smsService.isLoading.value;
  
  // Get remaining seconds for resend timer (you might want to add this to SMS service)
  int get resendSecondsRemaining => 0; // Implement timer logic if needed
  
  // Navigation methods
  void navigateToBack() {
    Get.back();
  }
  
  void navigateToHome() {
    Get.offAllNamed(AppRoute.navbar);
  }
  
  void navigateToMobileLoginOtp() {
    Get.toNamed(AppRoute.mobileLoginOtp);
  }
}