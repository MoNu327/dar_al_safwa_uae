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
import 'package:majan/presentation/view_model/firebase_auth_controller.dart';
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
  bool _validatePhoneNumber(String phoneNumber) {
    if (phoneNumber.isEmpty) {
      Get.snackbar('Error', 'Please enter your mobile number');
      return false;
    }

    String digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

    if (selectedCountryCode.value == '+971') {
      // UAE: 9 digits, must start with 5
      if (digitsOnly.length != 9) {
        Get.snackbar('Error', 'UAE mobile number should be 9 digits (e.g. 501234567)');
        return false;
      }
      if (!digitsOnly.startsWith('5')) {
        Get.snackbar('Error', 'UAE mobile number must start with 5');
        return false;
      }
    } else if (selectedCountryCode.value == '+968') {
      // Oman: 8 digits
      if (digitsOnly.length != 8) {
        Get.snackbar('Error', 'Oman mobile number should be 8 digits');
        return false;
      }
    } else if (selectedCountryCode.value == '+966') {
      // Saudi Arabia: 9 digits, starts with 5
      if (digitsOnly.length != 9) {
        Get.snackbar('Error', 'Saudi mobile number should be 9 digits');
        return false;
      }
      if (!digitsOnly.startsWith('5')) {
        Get.snackbar('Error', 'Saudi mobile number must start with 5');
        return false;
      }
    } else if (selectedCountryCode.value == '+974') {
      // Qatar: 8 digits
      if (digitsOnly.length != 8) {
        Get.snackbar('Error', 'Qatar mobile number should be 8 digits');
        return false;
      }
    } else if (selectedCountryCode.value == '+965') {
      // Kuwait: 8 digits
      if (digitsOnly.length != 8) {
        Get.snackbar('Error', 'Kuwait mobile number should be 8 digits');
        return false;
      }
    } else if (selectedCountryCode.value == '+973') {
      // Bahrain: 8 digits
      if (digitsOnly.length != 8) {
        Get.snackbar('Error', 'Bahrain mobile number should be 8 digits');
        return false;
      }
    } else if (selectedCountryCode.value == '+1') {
      // US: 10 digits
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

    if (!RegExp(r'^[0-9+\-\s\(\)]*$').hasMatch(phoneNumber)) {
      Get.snackbar('Error', 'Phone number contains invalid characters');
      return false;
    }

    debugPrint('Phone number validation passed: $digitsOnly digits');
    return true;
  }

  // ── Send OTP (first time only — no forceResendingToken) ──────────────────
  Future<void> sendOtp() async {
    // ✅ Guard: prevent multiple simultaneous requests
    if (isLoading.value || isResending.value) return;

    try {
      isLoading.value = true;

      final String phoneNumber = mobileNumberController.text.trim();
      final String fullPhoneNumber = '${selectedCountryCode.value}$phoneNumber';

      debugPrint('=== OTP SEND DEBUG INFO ===');
      debugPrint('Country Code: ${selectedCountryCode.value}');
      debugPrint('Phone Number: $phoneNumber');
      debugPrint('Full Phone Number: $fullPhoneNumber');

      if (!_validatePhoneNumber(phoneNumber)) {
        isLoading.value = false;
        return;
      }

      debugPrint('Starting Firebase Phone Verification...');

      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        // ✅ FIX: forceResendingToken is null on first send — only used in resendOtp()
        forceResendingToken: null,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('✅ Verification completed automatically');
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Verification failed: ${e.code} — ${e.message}');
          isLoading.value = false;

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

          Get.snackbar(
            'Error',
            userMessage,
            backgroundColor: Colors.red[100],
            colorText: Colors.red[800],
            duration: const Duration(seconds: 5),
          );
        },
        codeSent: (String vid, int? resendToken) {
          debugPrint('✅ Code sent successfully. Verification ID: $vid');
          isLoading.value = false;
          verificationId.value = vid;
          _resendToken = resendToken;

          // ✅ FIX: only navigate if not already on OTP screen
          if (Get.currentRoute != AppRoute.mobileLoginOtp) {
            Get.toNamed(AppRoute.mobileLoginOtp, arguments: {
              'phoneNumber': fullPhoneNumber,
            });
          }

          startResendTimer();
        },
        codeAutoRetrievalTimeout: (String vid) {
          debugPrint('⏰ Code auto retrieval timeout. Verification ID: $vid');
          verificationId.value = vid;
          isLoading.value = false;
        },
      );
    } catch (e) {
      debugPrint('🚨 Exception in sendOtp: ${e.toString()}');
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to send OTP: ${e.toString()}');
    }
  }

  // ── Resend OTP (uses forceResendingToken) ────────────────────────────────
  Future<void> resendOtp() async {
    if (!canResend.value) return;
    // ✅ Guard: prevent multiple simultaneous requests
    if (isLoading.value || isResending.value) return;

    try {
      isResending.value = true;

      final String phoneNumber = mobileNumberController.text.trim();
      final String fullPhoneNumber = '${selectedCountryCode.value}$phoneNumber';

      debugPrint('=== OTP RESEND ===');
      debugPrint('Full Phone Number: $fullPhoneNumber');
      debugPrint('Resend Token: $_resendToken');

      await _auth.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        timeout: const Duration(seconds: 60),
        // ✅ FIX: forceResendingToken only used here during resend
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('❌ Resend failed: ${e.code} — ${e.message}');
          Get.snackbar(
            'Error',
            'Failed to resend OTP: ${e.message}',
            backgroundColor: Colors.red[100],
            colorText: Colors.red[800],
          );
        },
        codeSent: (String vid, int? resendToken) {
          debugPrint('✅ OTP resent successfully');
          verificationId.value = vid;
          _resendToken = resendToken;
          resetResendTimer();
        },
        codeAutoRetrievalTimeout: (String vid) {
          verificationId.value = vid;
        },
      );
    } catch (e) {
      debugPrint('🚨 Exception in resendOtp: ${e.toString()}');
      Get.snackbar('Error', 'Failed to resend OTP: ${e.toString()}');
    } finally {
      isResending.value = false;
    }
  }

  // ── Verify OTP ───────────────────────────────────────────────────────────
  Future<void> verifyOtp() async {
    if (isVerifying.value) return;

    try {
      isVerifying.value = true;
      final String smsCode = otpController.text.trim();

      if (smsCode.isEmpty || smsCode.length != 6) {
        Get.snackbar('Error', 'Please enter a valid 6-digit OTP');
        isVerifying.value = false;
        return;
      }

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

  // ── Sign in with credential ──────────────────────────────────────────────
  Future<void> _signInWithCredential(AuthCredential credential) async {
    // Suppress AuthService.handleAuthChanged during this flow to avoid race
    // condition where it finds no Firestore doc (not yet written) and signs out.
    AuthService? authService;
    try {
      authService = Get.find<AuthService>();
      authService.isVerifyPhone.value = true;
    } catch (_) {}

    try {
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          await _createNewPhoneUser(userCredential.user!);
        } else {
          await _handleExistingPhoneUser(userCredential.user!);
        }

        Get.offAllNamed(AppRoute.navbar);
      }
    } catch (e) {
      isVerifying.value = false;
      Get.snackbar('Error', 'Authentication failed: ${e.toString()}');
    } finally {
      authService?.isVerifyPhone.value = false;
    }
  }

  // ── Timer helpers ────────────────────────────────────────────────────────
  void startResendTimer() {
    canResend.value = false;
    resendSecondsRemaining.value = 60;

    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsRemaining.value > 0) {
        resendSecondsRemaining.value--;
      } else {
        canResend.value = true;
        timer.cancel();
      }
    });
  }

  void resetResendTimer() {
    _resendTimer?.cancel();
    startResendTimer();
  }

  // ── Firestore helpers ────────────────────────────────────────────────────
  Future<void> _handleExistingPhoneUser(User user) async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(user.uid).get();

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

  Future<void> _updateUserInController(UserModel userModel) async {
    try {
      final userController = Get.find<UserController>();
      userController.currentUser = userModel;
      debugPrint('User details stored: ${userModel.toJson()}');
    } catch (e) {
      debugPrint('Error updating user controller: $e');
      rethrow;
    }
  }

  // Navigation
  void navigateToBack() {
    Get.back();
  }
}