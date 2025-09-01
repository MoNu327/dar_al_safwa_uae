import 'package:majan/core/theme/app_colors.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'dart:math';
import 'dart:convert';

class SmsService extends GetxController {
  static const String _baseUrl = 'http://isms.infosatme.com:8080/websmpp/websms';
  static const String _accessKey = 'HLHvTnQuhJKE7Hp';
  static const String _sid = 'WAYTRACK';
  
  var isLoading = false.obs;
  var lastSentOtp = ''.obs;
  var otpTimestamp = DateTime.now().obs;
  
  // Generate a 6-digit OTP
  String generateOtp() {
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    lastSentOtp.value = otp;
    otpTimestamp.value = DateTime.now();
    return otp;
  }
  
  // Send OTP via SMS
  Future<bool> sendOtp({
    required String phoneNumber,
    String? customMessage,
  }) async {
    try {
      isLoading.value = true;
      
      // Generate OTP
      final otp = generateOtp();
      
      // Create SMS message
      final message = customMessage ?? 'Your verification code is: $otp. This code will expire in 5 minutes. Do not share this code with anyone.';
      
      // Clean phone number (remove + and spaces)
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      
      // Prepare API parameters
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'accesskey': _accessKey,
        'sid': _sid,
        'mno': cleanPhoneNumber,
        'type': '3',
        'text': message,
      });
      
      // Send HTTP request
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        // Parse response to check if SMS was sent successfully
        final responseBody = response.body.toLowerCase();
        
        if (responseBody.contains('success') || responseBody.contains('sent')) {
          Get.snackbar(
            'Success',
            'OTP sent successfully to $phoneNumber',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Get.theme.primaryColor,
            colorText: AppColors.white,
          );
          return true;
        } else {
          throw Exception('SMS gateway error: ${response.body}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send OTP: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: AppColors.redColor,
        colorText: AppColors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  // Verify OTP
  bool verifyOtp(String enteredOtp) {
    if (lastSentOtp.value.isEmpty) {
      Get.snackbar('Error', 'No OTP was sent');
      return false;
    }
    
    // Check if OTP is expired (5 minutes)
    final now = DateTime.now();
    final difference = now.difference(otpTimestamp.value);
    
    if (difference.inMinutes > 5) {
      Get.snackbar('Error', 'OTP has expired. Please request a new one.');
      return false;
    }
    
    // Verify OTP
    if (enteredOtp.trim() == lastSentOtp.value) {
      Get.snackbar(
        'Success',
        'Phone number verified successfully',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.primaryColor,
        colorText: AppColors.white,
      );
      return true;
    } else {
      Get.snackbar('Error', 'Invalid OTP. Please try again.');
      return false;
    }
  }
  
  // Resend OTP
  Future<bool> resendOtp(String phoneNumber) async {
    return await sendOtp(phoneNumber: phoneNumber);
  }
  
  // Clear OTP data
  void clearOtpData() {
    lastSentOtp.value = '';
    otpTimestamp.value = DateTime.now();
  }
}