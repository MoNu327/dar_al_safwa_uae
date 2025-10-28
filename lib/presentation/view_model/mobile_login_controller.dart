// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:country_code_picker/country_code_picker.dart';
// import 'package:dar_al_safwa/core/routes/app_route.dart';
// import 'package:dar_al_safwa/data/model/user_model.dart';
// import 'package:dar_al_safwa/data/repositories/api_services.dart';
// import 'package:get/get.dart';
// import 'package:flutter/material.dart';

// class MobileLoginController extends GetxController {
//   // Dependencies
//   final ApiService _apiService = Get.put(ApiService());
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Observable variables
//   var selectedCountryCode = '+968'.obs;
//   var isLoading = false.obs;
//   var currentUser = Rxn<UserModel>();
  
//   // Text controllers
//   final TextEditingController mobileNumberController = TextEditingController();
  
//   @override
//   void onClose() {
//     mobileNumberController.dispose();
//     super.onClose();
//   }
  
//   // Method to change the country code
//   void changeCountryCode(CountryCode newCode) {
//     selectedCountryCode.value = newCode.dialCode ?? '+968';
//   }
  
//   // Validate phone number
//   bool _validatePhoneNumber(String phoneNumber) {
//     if (phoneNumber.isEmpty) {
//       Get.snackbar('Error', 'Please enter your mobile number');
//       return false;
//     }
    
//     if (phoneNumber.length < 8 || phoneNumber.length > 15) {
//       Get.snackbar('Error', 'Please enter a valid mobile number');
//       return false;
//     }
    
//     return true;
//   }
  

// //   Future<UserModel?> loginWithPhone(String phone) async {
// //   final snapshot = await FirebaseFirestore.instance
// //       .collection("users")
// //       .where("mobile", isEqualTo: phone)
// //       .limit(1)
// //       .get();

// //   if (snapshot.docs.isNotEmpty) {
// //     final data = snapshot.docs.first.data();
// //     return UserModel.fromJson(data);
// //   } else {
// //     return null; // user not found
// //   }
// // }

// // Send OTP - but now we just check if the number exists in Firestore
// Future<void> sendOtp() async {
//   try {
//     isLoading.value = true;

//     final String phoneNumber = mobileNumberController.text.trim();
//     final String fullPhoneNumber = '${selectedCountryCode.value}$phoneNumber';

//     if (!_validatePhoneNumber(phoneNumber)) {
//       return;
//     }

//     debugPrint('Checking if phone number exists in Firebase: $fullPhoneNumber');

//     // Verify user in Firestore
//     final user = await _verifyUserInFirebase(fullPhoneNumber);

//     if (user != null) {
//       currentUser.value = user;

//       // Update last login timestamp
//       await _firestore.collection('users').doc(user.uid).update({
//         'lastLogin': FieldValue.serverTimestamp(),
//         'lastUpdated': FieldValue.serverTimestamp(),
//         'isFirstTime': false,
//       });

//       Get.snackbar(
//         'Success',
//         'Login successful!',
//         backgroundColor: Colors.green[100],
//         colorText: Colors.green[800],
//       );

//       Get.offAllNamed(AppRoute.navbar);
//     } else {
//       Get.snackbar(
//         'Error',
//         'This number is not registered. Please contact the admin.',
//         backgroundColor: Colors.red[100],
//         colorText: Colors.red[800],
//       );
//     }
//   } catch (e) {
//     debugPrint('Error in sendOtp: $e');
//     Get.snackbar('Error', 'Login failed. Please try again.');
//   } finally {
//     isLoading.value = false;
//   }
// }

// // ✅ Only checks existing users,
// Future<UserModel?> _verifyUserInFirebase(String fullPhoneNumber) async {
//   try {
//     final QuerySnapshot result = await _firestore
//         .collection('users')
//         .where('phoneNumber', isEqualTo: fullPhoneNumber)
//         .limit(1)
//         .get();
        

//     if (result.docs.isNotEmpty) {
//       final doc = result.docs.first;
//       final userData = doc.data() as Map<String, dynamic>;

//       return UserModel.fromJson({
//         ...userData,
//         'uid': doc.id,
//         'photoUrl': userData['photoUrl'] ?? userData['imageUrl'] ?? '',
//       });
//     }
//     return null; // not found
//   } catch (e) {
//     debugPrint('Error verifying user in Firebase: $e');
//     return null;
//   }
// }

  
//   // Get user by UID
//   Future<UserModel?> getUserById(String uid) async {
//     try {
//       final doc = await _firestore.collection('users').doc(uid).get();
//       if (doc.exists) {
//         return UserModel.fromJson({...doc.data()!, 'uid': doc.id});
//       }
//       return null;
//     } catch (e) {
//       debugPrint('Error getting user by ID: $e');
//       return null;
//     }
//   }
  
//   // Update user data
//   Future<void> updateUser(UserModel updatedUser) async {
//     try {
//       await _firestore.collection('users').doc(updatedUser.uid).update({
//         ...updatedUser.toJson(),
//         'lastUpdated': FieldValue.serverTimestamp(),
//       });
//       currentUser.value = updatedUser;
//     } catch (e) {
//       debugPrint('Error updating user: $e');
//       rethrow;
//     }
//   }
  
//   // Navigation methods
//   void navigateToBack() {
//     Get.back();
//   }
// }

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/data/model/user_model.dart';
import 'package:majan/domain/controller/user_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MobileLoginController extends GetxController {
  // Dependencies
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Observable variables
  var selectedCountryCode = '+971'.obs;
  var isLoading = false.obs;
  var isVerifying = false.obs;
  var isResending = false.obs;
  var canResend = false.obs;
  var resendSecondsRemaining = 60.obs;
  var verificationId = ''.obs;
  int? _resendToken;
  
  // Text controllers
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  
  // Timer for resend OTP
  Timer? _resendTimer;
  
  @override
  void onClose() {
    mobileNumberController.dispose();
    otpController.dispose();
    fullNameController.dispose();
    _resendTimer?.cancel();
    super.onClose();
  }
  
  // Method to change the country code
  void changeCountryCode(CountryCode newCode) {
    selectedCountryCode.value = newCode.dialCode ?? '+971';
  }
  
  // Validate phone number
  // Improved phone number validation
bool _validatePhoneNumber(String phoneNumber) {
  if (phoneNumber.isEmpty) {
    Get.snackbar('Error', 'Please enter your mobile number');
    return false;
  }
  
  // Remove any non-digit characters for validation
  String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
  
  // More flexible length validation based on country
  if (selectedCountryCode.value == '+968') { // Oman
    if (digitsOnly.length != 8) {
      Get.snackbar('Error', 'Oman mobile number should be 8 digits');
      return false;
    }
  } else if (selectedCountryCode.value == '+971') { // UAE
    if (digitsOnly.length != 9) {
      Get.snackbar('Error', 'UAE mobile number should be 9 digits');
      return false;
    }
  } else if (selectedCountryCode.value == '+1') { // US
    if (digitsOnly.length != 10) {
      Get.snackbar('Error', 'US mobile number should be 10 digits');
      return false;
    }
  } else {
    // Generic validation for other countries
    if (digitsOnly.length < 7 || digitsOnly.length > 15) {
      Get.snackbar('Error', 'Please enter a valid mobile number');
      return false;
    }
  }
  
  // Additional validation: check if it contains only digits and valid characters
  if (!RegExp(r'^[0-9+\-\s\(\)]*$').hasMatch(phoneNumber)) {
    Get.snackbar('Error', 'Phone number contains invalid characters');
    return false;
  }
  
  debugPrint('Phone number validation passed: $digitsOnly digits');
  return true;
}
  // Send OTP using Firebase Auth
  Future<void> sendOtp() async {
  try {
    isLoading.value = true;
    
    final String phoneNumber = mobileNumberController.text.trim();
    final String fullPhoneNumber = '${selectedCountryCode.value}$phoneNumber';
    
    // Enhanced logging
    debugPrint('=== OTP SEND DEBUG INFO ===');
    debugPrint('Country Code: ${selectedCountryCode.value}');
    debugPrint('Phone Number: $phoneNumber');
    debugPrint('Full Phone Number: $fullPhoneNumber');
    debugPrint('Phone Number Length: ${phoneNumber.length}');
    
    if (!_validatePhoneNumber(phoneNumber)) {
      isLoading.value = false;
      return;
    }
    
    debugPrint('Starting Firebase Phone Verification...');
    
    await _auth.verifyPhoneNumber(
      phoneNumber: fullPhoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        debugPrint('✅ Verification completed automatically');
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        debugPrint('❌ Verification failed');
        debugPrint('Error Code: ${e.code}');
        debugPrint('Error Message: ${e.message}');
        debugPrint('Error Details: ${e.toString()}');
        
        isLoading.value = false;
        
        // More specific error messages
        String userMessage = 'Verification failed: ${e.message}';
        switch (e.code) {
          case 'invalid-phone-number':
            userMessage = 'Invalid phone number format';
            break;
          case 'too-many-requests':
            userMessage = 'Too many requests. Please try again later';
            break;
          case 'quota-exceeded':
            userMessage = 'SMS quota exceeded. Please try again later';
            break;
          case 'missing-phone-number':
            userMessage = 'Phone number is required';
            break;
          case 'app-not-authorized':
            userMessage = 'App not authorized for SMS verification';
            break;
        }
        
        Get.snackbar('Error', userMessage, 
          backgroundColor: Colors.red[100],
          colorText: Colors.red[800],
          duration: const Duration(seconds: 5)
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        debugPrint('✅ Code sent successfully');
        debugPrint('Verification ID: $verificationId');
        debugPrint('Resend Token: $resendToken');
        
        isLoading.value = false;
        this.verificationId.value = verificationId;
        _resendToken = resendToken;
        
        Get.toNamed(AppRoute.mobileLoginOtp, arguments: {
          'phoneNumber': fullPhoneNumber
        });
        startResendTimer();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('⏰ Code auto retrieval timeout');
        debugPrint('Verification ID: $verificationId');
        
        isLoading.value = false;
        this.verificationId.value = verificationId;
      },
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
    );
    
  } catch (e) {
    debugPrint('🚨 Exception in sendOtp: ${e.toString()}');
    debugPrint('Exception type: ${e.runtimeType}');
    
    isLoading.value = false;
    Get.snackbar('Error', 'Failed to send OTP: ${e.toString()}');
  }
}
  
  // Verify OTP
  Future<void> verifyOtp() async {
    try {
      isVerifying.value = true;
      final String smsCode = otpController.text.trim();
      
      if (smsCode.isEmpty || smsCode.length != 6) {
        Get.snackbar('Error', 'Please enter a valid 6-digit OTP');
        isVerifying.value = false;
        return;
      }
      
      // Create credential and sign in
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: smsCode,
      );
      
      await _signInWithCredential(credential);
      
    } catch (e) {
      isVerifying.value = false;
      Get.snackbar('Error', 'Failed to verify OTP: ${e.toString()}');
    }
  }
  
  // Sign in with credential
  Future<void> _signInWithCredential(AuthCredential credential) async {
    try {
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        // Check if user is new or existing
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createNewPhoneUser(userCredential.user!);
        } else {
          await _handleExistingPhoneUser(userCredential.user!);
        }
        
        // Navigate to home
        Get.offAllNamed(AppRoute.navbar);
      }
    } catch (e) {
      isVerifying.value = false;
      Get.snackbar('Error', 'Authentication failed: ${e.toString()}');
    }
  }
  
  // Resend OTP
  Future<void> resendOtp() async {
    if (!canResend.value) return;
    
    try {
      isResending.value = true;
      await sendOtp();
    } catch (e) {
      Get.snackbar('Error', 'Failed to resend OTP: ${e.toString()}');
    } finally {
      isResending.value = false;
    }
  }
  
  // Start resend timer
  void startResendTimer() {
    canResend.value = false;
    resendSecondsRemaining.value = 60;
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsRemaining.value > 0) {
        resendSecondsRemaining.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }
  
  // Reset resend timer
  void resetResendTimer() {
    _resendTimer?.cancel();
    startResendTimer();
  }
  
  // Handle existing phone user
  Future<void> _handleExistingPhoneUser(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final userModel = UserModel(
          uid: userData['uid'],
          phoneNumber: user.phoneNumber,
          name: userData['displayName'] ?? '',
          role: userData['role'] ?? 'user',
          status: userData['status'] ?? 'pending',
        );

        await _updateUserInController(userModel);
      } else {
        await _createNewPhoneUser(user);
      }
    } catch (e) {
      debugPrint('Error handling existing phone user: $e');
      rethrow;
    }
  }

  // Create new phone user
  Future<void> _createNewPhoneUser(User user) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        name: fullNameController.text.trim(),
        email: '',
        role: 'user',
        status: 'pending',
        phoneNumber: user.phoneNumber ?? '',
      );
      
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': null,
        'displayName': fullNameController.text.trim(),
        'photoURL': null,
        'phoneNumber': user.phoneNumber,
        'role': 'user',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _updateUserInController(userModel);
    } catch (e) {
      debugPrint('Error creating new phone user: $e');
      rethrow;
    }
  }

  // Update user in controller
  Future<void> _updateUserInController(UserModel userModel) async {
    try {
      // Assuming you have a user controller
      final userController = Get.find<UserController>();
      userController.currentUser = userModel;
      debugPrint('User details stored: ${userModel.toJson()}');
    } catch (e) {
      debugPrint('Error updating user controller: $e');
      rethrow;
    }
  }
  
  // Navigation methods
  void navigateToBack() {
    Get.back();
  }
}