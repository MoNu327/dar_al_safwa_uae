import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/data/model/agent_model.dart';
import 'package:majan/data/model/technician_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:majan/domain/controller/agent_controller.dart';
import 'package:majan/domain/controller/notification_controller.dart';
import 'package:majan/domain/controller/technician_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../data/model/user_model.dart';
import '../../domain/controller/user_controller.dart';


class AuthService extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );

  final Rxn<User> firebaseUser = Rxn<User>();
  final RxString userRole = RxString('');
  final RxString userTenantId = RxString('');
  final RxString selectedGender = RxString('');
  final RxString selectedDate = RxString('');
  final RxBool selectedWhatsAppStatus = RxBool(false);
  final RxString profilePictureUrl = RxString('');
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileNoController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController whatsAppNumberController = TextEditingController();

  var isSignInAgent = false.obs;
  var isSignInTenant = false.obs;
  var isSignInTechnician = false.obs;
  var isSignInGoogle = false.obs;
  final isSignInApple = false.obs;
  var isSignInPhone = false.obs;
  var isVerifyPhone = false.obs;
  var isRegisterAgent = false.obs;
  var isSignOutAll = false.obs;
  
  // Auto-login state
  final RxBool isAutoLoggingIn = RxBool(false);
  final RxBool hasCheckedAutoLogin = RxBool(false);

  final resendEnabled = false.obs;
  final secondsRemaining = 60.obs;
  Timer? _resendTimer;
  int? _resendToken;
  String verificationId = '';
   NotificationController? get _notificationController {
    try {
      if (Get.isRegistered<NotificationController>()) {
        return Get.find<NotificationController>();
      }
    } catch (e) {
      debugPrint('⚠️ NotificationController not found: $e');
    }
    return null;
  }

  /// Get current platform information
String _getPlatformInfo() {
  if (Platform.isIOS) {
    return 'ios';
  } else if (Platform.isAndroid) {
    return 'android';
  } else if (Platform.isWindows) {
    return 'windows';
  } else if (Platform.isMacOS) {
    return 'macos';
  } else if (Platform.isLinux) {
    return 'linux';
  } else {
    return 'web';
  }
}

/// Get device information including platform
Map<String, dynamic> _getDeviceInfo() {
  return {
    'mode': _getPlatformInfo(),
    'modeupdated': _getPlatformInfo(),
    'lastLoginAt': FieldValue.serverTimestamp(),
  };
}

/// Log user activity after successful login
Future<void> _logLoginActivity(String uid) async {
  try {
    debugPrint('📊 Logging login activity for user: $uid');

    // Determine which collection the user belongs to
    String collection = 'users';
    
    final agentDoc = await _firestore.collection('agents').doc(uid).get();
    if (agentDoc.exists && agentDoc.data()?['role'] == 'agent') {
      collection = 'agents';
      debugPrint('✅ User identified as agent');
    } else {
      final techDoc = await _firestore.collection('technicians').doc(uid).get();
      if (techDoc.exists && techDoc.data()?['role'] == 'technician') {
        collection = 'technicians';
        debugPrint('✅ User identified as technician');
      }
    }

    final userDoc = await _firestore.collection(collection).doc(uid).get();

    String mode;
    String modeUpdated;

    if (userDoc.exists) {
      final userData = userDoc.data();
      mode = userData?['mode'] ?? _getPlatformInfo();
      modeUpdated = userData?['modeupdated'] ?? _getPlatformInfo();
      debugPrint('✅ Platform data from $collection - mode: $mode, modeupdated: $modeUpdated');
    } else {
      mode = _getPlatformInfo();
      modeUpdated = _getPlatformInfo();
      debugPrint('⚠️ Using detected platform: $mode');
    }

    // Call the API
    debugPrint('🔄 Calling login activity API...');
    final response = await ApiService().getuserlogactivity(uid, mode, modeUpdated);

    if (response.statusCode == 200 || response.statusCode == 201) {
      debugPrint('✅ Login activity logged successfully');
      debugPrint('📦 Response: ${response.data}');
    } else {
      debugPrint('⚠️ Login activity API failed with status: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('❌ Error logging login activity: $e');
    // Don't block login flow if logging fails
  }
}

  @override
  void onReady() {
    super.onReady();
    // Bind Firebase auth state changes
    firebaseUser.bindStream(auth.authStateChanges());
    ever(firebaseUser, handleAuthChanged);
    
    // Check for existing session on app start
    checkAutoLogin();
  }

 /// Check if user is already logged in when app starts
Future<void> checkAutoLogin() async {
  if (hasCheckedAutoLogin.value) {
    debugPrint('⏭️ [checkAutoLogin] Already checked, skipping');
    return;
  }
  
  try {
    isAutoLoggingIn(true);
    debugPrint('🔍 [checkAutoLogin] Starting auto-login check...');
    
    final currentUser = auth.currentUser;
    
    if (currentUser != null) {
      debugPrint('✅ [checkAutoLogin] Found existing user session: ${currentUser.uid}');
      debugPrint('📧 [checkAutoLogin] Email: ${currentUser.email}');
      debugPrint('📱 [checkAutoLogin] Phone: ${currentUser.phoneNumber}');
      
      // ✅ Load notifications
      _notificationController?.setUserId(currentUser.uid);
      debugPrint('📱 [checkAutoLogin] Notifications loaded for user: ${currentUser.uid}');
      
      // ✅ CRITICAL: Sync FCM token FIRST (updates platform info)
      debugPrint('🔄 [checkAutoLogin] Calling _syncFCMToken...');
      await _syncFCMToken(currentUser);
      debugPrint('✅ [checkAutoLogin] _syncFCMToken completed');
      
      // ✅ THEN log login activity (reads updated platform info)
      debugPrint('📊 [checkAutoLogin] Calling _logLoginActivity...');
      await _logLoginActivity(currentUser.uid);
      debugPrint('✅ [checkAutoLogin] _logLoginActivity completed');
      
      // Let handleAuthChanged take care of navigation
      debugPrint('✅ [checkAutoLogin] Auto-login setup complete');
    } else {
      debugPrint('❌ [checkAutoLogin] No existing user session found');
      _notificationController?.clearUserId();
      
      if (Get.currentRoute != AppRoute.login) {
        debugPrint('➡️ [checkAutoLogin] Navigating to login');
        Get.offAllNamed(AppRoute.login);
      }
    }
    
    hasCheckedAutoLogin(true);
    debugPrint('✅ [checkAutoLogin] Check completed, flag set to true');
  } catch (e, stackTrace) {
    debugPrint('❌ [checkAutoLogin] ERROR: $e');
    debugPrint('📝 [checkAutoLogin] Stack trace: $stackTrace');
    Get.offAllNamed(AppRoute.login);
  } finally {
    isAutoLoggingIn(false);
    debugPrint('🏁 [checkAutoLogin] Process finished');
  }
}

Future<void> _syncFCMToken(User user) async {
  try {
    debugPrint('🔄 [_syncFCMToken] Starting for user: ${user.uid}');
    
    final fcmToken = await FirebaseMessaging.instance.getToken();
    
    if (fcmToken == null) {
      debugPrint('⚠️ [_syncFCMToken] FCM token is null');
      return;
    }
    
    debugPrint('✅ [_syncFCMToken] FCM Token: ${fcmToken.substring(0, 20)}...');
    
    // Determine collection
    String collection = 'users';
    
    debugPrint('🔍 [_syncFCMToken] Checking agents collection...');
    final agentDoc = await _firestore.collection('agents').doc(user.uid).get();
    if (agentDoc.exists && agentDoc.data()?['role'] == 'agent') {
      collection = 'agents';
      debugPrint('✅ [_syncFCMToken] User is agent');
    } else {
      debugPrint('🔍 [_syncFCMToken] Checking technicians collection...');
      final techDoc = await _firestore.collection('technicians').doc(user.uid).get();
      if (techDoc.exists && techDoc.data()?['role'] == 'technician') {
        collection = 'technicians';
        debugPrint('✅ [_syncFCMToken] User is technician');
      } else {
        debugPrint('✅ [_syncFCMToken] User is regular user');
      }
    }
    
    debugPrint('📁 [_syncFCMToken] Target collection: $collection');
    
    // Get current document to check if this is first time
    debugPrint('📖 [_syncFCMToken] Reading current document...');
    final userDoc = await _firestore.collection(collection).doc(user.uid).get();
    final currentData = userDoc.data();
    
    final currentPlatform = _getPlatformInfo();
    debugPrint('📱 [_syncFCMToken] Current platform: $currentPlatform');
    
    if (currentData != null) {
      debugPrint('📊 [_syncFCMToken] Existing data:');
      debugPrint('   - mode: ${currentData['mode']}');
      debugPrint('   - modeupdated: ${currentData['modeupdated']}');
      debugPrint('   - originalPlatform: ${currentData['originalPlatform']}');
    } else {
      debugPrint('⚠️ [_syncFCMToken] Document does not exist!');
    }
    
    // ✅ Prepare update data with ALL timestamp fields
    Map<String, dynamic> updateData = {
      'fcmToken': fcmToken,
      'lastTokenUpdate': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(), // ✅ FIX: Add this!
      'updatedAt': FieldValue.serverTimestamp(),    // ✅ FIX: Add this too!
      'mode': currentPlatform,
      'modeupdated': currentPlatform,
    };
    
    debugPrint('📝 [_syncFCMToken] Update data prepared:');
    debugPrint('   - mode: $currentPlatform');
    debugPrint('   - modeupdated: $currentPlatform');
    
    // Only set 'originalPlatform' if it doesn't exist
    if (currentData == null || !currentData.containsKey('originalPlatform') || currentData['originalPlatform'] == null) {
      updateData['originalPlatform'] = currentPlatform;
      debugPrint('🆕 [_syncFCMToken] Setting original platform: $currentPlatform');
    } else {
      debugPrint('ℹ️ [_syncFCMToken] Keeping original platform: ${currentData['originalPlatform']}');
    }
    
    debugPrint('💾 [_syncFCMToken] Updating Firestore document...');
    await _firestore.collection(collection).doc(user.uid).update(updateData);
    
    debugPrint('✅✅✅ [_syncFCMToken] SUCCESS! Token and platform synced to $collection/${user.uid}');
    debugPrint('📱 [_syncFCMToken] Platform updated to: $currentPlatform');
    
    // Verification: Read back the document to confirm update
    debugPrint('🔍 [_syncFCMToken] Verifying update...');
    final verifyDoc = await _firestore.collection(collection).doc(user.uid).get();
    final verifyData = verifyDoc.data();
    if (verifyData != null) {
      debugPrint('✅ [_syncFCMToken] Verification - Updated values:');
      debugPrint('   - mode: ${verifyData['mode']}');
      debugPrint('   - modeupdated: ${verifyData['modeupdated']}');
      debugPrint('   - lastUpdated: ${verifyData['lastUpdated']}');
    }
    
  } catch (e, stackTrace) {
    debugPrint('❌ [_syncFCMToken] ERROR: $e');
    debugPrint('📝 [_syncFCMToken] Stack trace: $stackTrace');
    // Don't rethrow - we don't want to block login
  }
} 

  void handleAuthChanged(User? user) async {
  debugPrint('🔄 Auth state changed. User: ${user?.email ?? user?.phoneNumber ?? 'null'}');

  if (user == null) {
    debugPrint('👤 No user - clearing notifications and redirecting to login');
    
    // ✅ Clear notification user context (saves notifications first)
    _notificationController?.clearUserId();
    
    if (Get.currentRoute != AppRoute.login) {
      Get.offAllNamed(AppRoute.login);
    }
    return;
  }

  // ✅ CRITICAL FIX: Set user ID IMMEDIATELY before any other operations
  debugPrint('👤 User found: ${user.uid}');
  
  // ✅ Set user ID (this will load stored notifications)
  _notificationController?.setUserId(user.uid);
  debugPrint('📱 Notifications loaded for user: ${user.uid}');

  // Don't process if we're in the middle of a sign-in operation
  if (isSignInGoogle.value || isSignInApple.value || isSignInAgent.value || 
      isSignInTechnician.value || isVerifyPhone.value) {
    debugPrint('⏳ Sign-in operation in progress, skipping auth state handling');
    return;
  }

  try {
    // Sync FCM token
    await _syncFCMToken(user);

    // Check if user is a technician first
    debugPrint('🔍 Checking technician collection...');
    final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();

    if (technicianDoc.exists && technicianDoc.data()?['role'] == 'technician') {
      debugPrint('✅ User is technician - auto-logging in');
      await _handleTechnicianUser(user);
      if (Get.currentRoute != AppRoute.technicianDashboard) {
        Get.offAllNamed(AppRoute.technicianDashboard);
      }
      return;
    }

    // Check if user is an agent
    debugPrint('🔍 Checking agents collection...');
    final agentDoc = await _firestore.collection('agents').doc(user.uid).get();

    if (agentDoc.exists && agentDoc.data()?['role'] == 'agent') {
      final status = agentDoc.data()?['status'];
      
      if (status == 'approved') {
        debugPrint('✅ User is approved agent - auto-logging in');
        await _handleAgentUser(user);
        if (Get.currentRoute != AppRoute.navbar) {
          Get.offAllNamed(AppRoute.navbar);
        }
        return;
      } else {
        debugPrint('⏳ Agent status: $status');
        if (Get.currentRoute != AppRoute.approvalPendingPage) {
          Get.offAllNamed(AppRoute.approvalPendingPage);
        }
        return;
      }
    }

    // Check regular users collection
    debugPrint('🔍 Checking users collection...');
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      final userData = userDoc.data()!;
      debugPrint('✅ User document found in users collection - auto-logging in');
      debugPrint('📊 User role: ${userData['role']}');
      await _handleRegularUser(user, userData);
    } else {
      debugPrint('❌ No user document found in any collection');
      // Clear notifications for non-existent user
      _notificationController?.clearUserId();
      await auth.signOut();
      Get.offAllNamed(AppRoute.login);
    }
  } catch (e) {
    debugPrint('❌ Error in handleAuthChanged: $e');
    _notificationController?.clearUserId();
    Get.snackbar(
      'Authentication Error',
      'Failed to load user data. Please try signing in again.',
      backgroundColor: Colors.orange[100],
      colorText: Colors.orange[800],
    );
    await auth.signOut();
    Get.offAllNamed(AppRoute.login);
  }
}


  /// Handle regular user auto-login
   Future<void> _handleRegularUser(User user, Map<String, dynamic> userData) async {
    try {
      final status = userData['status'] ?? 'active';
      userRole.value = userData['role'] ?? 'user';

      // Check if account is suspended
      if (status == 'suspended' || status == 'banned') {
        // ✅ NEW: Clear notifications for suspended users
        _notificationController?.clearUserId();
        
        await auth.signOut();
        Get.snackbar(
          'Account Suspended',
          'Your account has been suspended. Please contact support.',
          backgroundColor: Colors.orange[100],
          colorText: Colors.orange[800],
        );
        Get.offAllNamed(AppRoute.login);
        return;
      }

      final userModel = UserModel(
        uid: user.uid,
        email: user.email ?? userData['email'] ?? '',
        name: userData['displayName'] ?? user.displayName ?? '',
        role: userData['role'] ?? 'user',
        status: status,
        location: userData['location'] ?? '',
        phoneNumber: userData['phoneNumber'] ?? user.phoneNumber ?? '',
      );

      Get.find<UserController>().currentUser = userModel;
      debugPrint('✅ Regular user logged in: ${userModel.toJson()}');

      // Navigate based on role
      String targetRoute = AppRoute.navbar;
      if (userModel.role == 'technician') {
        targetRoute = AppRoute.technicianDashboard;
      }

      if (Get.currentRoute != targetRoute) {
        Get.offAllNamed(targetRoute);
      }
    } catch (e) {
      debugPrint('❌ Error handling regular user: $e');
      _notificationController?.clearUserId();
      rethrow;
    }
  }

    Future<void> _handleAgentUser(User user) async {
    try {
      final agentDoc = await _firestore.collection('agents').doc(user.uid).get();

      if (!agentDoc.exists || agentDoc.data()?['role'] != 'agent') {
        debugPrint('Agent document not found or role mismatch');
        _notificationController?.clearUserId();
        await auth.signOut();
        Get.offAllNamed(AppRoute.login);
        return;
      }

      final userData = agentDoc.data()!;
      userRole.value = 'agent';

      final userModel = AgentModel(
        dob: userData['dob'] ?? '',
        gender: userData['gender'] ?? '',
        location: userData['location'] ?? '',
        uid: user.uid,
        email: user.email ?? userData['email'] ?? '',
        name: userData['displayName'] ?? '',
        role: 'agent',
        status: userData['status'] ?? 'pending',
      );

      Get.find<AgentController>().currentUser = userModel;
      debugPrint('✅ Agent user handled successfully: ${userModel.toJson()}');
    } catch (e) {
      debugPrint('❌ Error handling agent user: $e');
      _notificationController?.clearUserId();
      await auth.signOut();
      Get.offAllNamed(AppRoute.login);
    }
  }

 Future<void> _handleTechnicianUser(User user) async {
    try {
      final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();

      if (!technicianDoc.exists) {
        debugPrint('Technician document not found');
        _notificationController?.clearUserId();
        await auth.signOut();
        Get.offAllNamed(AppRoute.login);
        return;
      }

      final userData = technicianDoc.data()!;
      userRole.value = 'technician';

      final userModel = TechnicianProfile(
        uid: user.uid,
        location: userData['location'] ?? '',
        fullName: userData['fullName'] ?? '',
        email: userData['email'] ?? user.email ?? '',
        mobile: userData['mobile'] ?? userData['phoneNumber'] ?? '',
        photoURL: userData['photoURL'] ?? '',
        role: 'technician',
      );

      Get.find<TechnicianController>().currentUser = userModel;
      debugPrint('✅ Technician user handled successfully: ${userModel.toJson()}');
    } catch (e) {
      debugPrint('❌ Error handling technician user: $e');
      _notificationController?.clearUserId();
      await auth.signOut();
      Get.offAllNamed(AppRoute.login);
    }
  }

  // Timer methods
  void startResendTimer() {
    resendEnabled.value = false;
    secondsRemaining.value = 60;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value > 0) {
        secondsRemaining.value--;
      } else {
        resendEnabled.value = true;
        timer.cancel();
      }
    });
  }

  void resetResendTimer() {
    _resendTimer?.cancel();
    startResendTimer();
  }

  // Phone authentication methods
  Future<void> signInWithPhone({
    required String phoneNumber,
    required Function(PhoneAuthCredential) onVerificationCompleted,
    required Function(FirebaseAuthException) onVerificationFailed,
    required Function(String, int?) onCodeSent,
    required Function(String) onCodeAutoRetrievalTimeout,
    bool resend = false,
  }) async {
    try {
      isSignInPhone(true);

      if (phoneNumber.isEmpty) {
        Get.snackbar('Error', 'Please enter a valid phone number');
        return;
      }

      await auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: (error) {
          isSignInPhone(false);
          Get.snackbar('Error', 'Verification failed: ${error.message}');
          onVerificationFailed(error);
        },
        codeSent: onCodeSent,
        codeAutoRetrievalTimeout: (verificationId) {
          isSignInPhone(false);
          onCodeAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 30),
        forceResendingToken: resend ? _resendToken : null,
      );
    } catch (e) {
      isSignInPhone(false);
      Get.snackbar('Error', 'Failed to send SMS: ${e.toString()}');
      rethrow;
    }
  }

  Future<UserCredential?> verifyPhoneNumber({
  required String verificationId,
  required String smsCode,
}) async {
  try {
    isVerifyPhone(true);
    debugPrint('Verifying phone number...');

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    final userCredential = await auth.signInWithCredential(credential);

    // ✅ CRITICAL FIX: Sync FCM token BEFORE creating/handling user
    if (userCredential.user != null) {
      debugPrint('🔄 Syncing FCM token and platform info...');
      await _syncFCMToken(userCredential.user!);
      debugPrint('✅ FCM token and platform synced');
    }

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _createNewPhoneUser(userCredential.user!);
    } else {
      await _handleExistingPhoneUser(userCredential.user!);
    }

    // ✅ Log login activity for phone authentication
    if (userCredential.user != null) {
      await _logLoginActivity(userCredential.user!.uid);
    }

    return userCredential;
  } catch (e) {
    debugPrint('Phone verification error: $e');
    Get.snackbar(
      'Error',
      e is FirebaseAuthException
          ? e.message ?? 'Verification failed'
          : 'Phone verification failed',
    );
    return null;
  } finally {
    isVerifyPhone(false);
  }
}

  Future<void> resendVerificationCode(String phoneNumber) async {
    try {
      await signInWithPhone(
        phoneNumber: phoneNumber,
        onVerificationCompleted: (credential) async {
          await verifyPhoneNumber(
            verificationId: credential.verificationId!,
            smsCode: credential.smsCode!,
          );
        },
        onVerificationFailed: (e) {
          Get.snackbar('Error', e.message ?? 'Verification failed');
        },
        onCodeSent: (verificationId, resendToken) {
          this.verificationId = verificationId;
          _resendToken = resendToken;
          resetResendTimer();
        },
        onCodeAutoRetrievalTimeout: (verificationId) {
          debugPrint('Code auto retrieval timed out');
        },
        resend: _resendToken != null,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to resend code: ${e.toString()}');
    }
  }

  // User management methods
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

  Future<void> _createNewPhoneUser(User user) async {
    try {
      final userModel = UserModel(
          uid: user.uid,
          name: fullNameController.text.trim(),
          email: '',
          role: 'user',
          status: 'pending',
          phoneNumber: user.phoneNumber);
      await _firestore.collection('users').doc(user.uid).set({
  'uid': user.uid,
  'email': null,
  'displayName': fullNameController.text.trim(),
  'photoURL': null,
  'phoneNumber': user.phoneNumber,
  'role': 'user',
  'mode': _getPlatformInfo(), // ✅ Add this
  'createdAt': FieldValue.serverTimestamp(),
  'modeupdated': _getPlatformInfo(), // ✅ Add this
  'lastLoginAt': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

      userRole.value = 'user';

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

  Future<void> updateUserName({
    required String userId,
    required String newName,
  }) async {
    try {
      debugPrint('Updating user name for $userId to $newName');

      await _firestore.collection('users').doc(userId).update({
        'displayName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await auth.currentUser?.updateDisplayName(newName);
      await auth.currentUser?.reload();

      final userController = Get.find<UserController>();
      if (userController.currentUser != null) {
        userController.currentUser = userController.currentUser!.copyWith(
          name: newName,
        );
      }

      debugPrint('User name updated successfully');
    } catch (e) {
      debugPrint('Error updating user name: $e');
      throw Exception('Failed to update user name: ${e.toString()}');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
  try {
    debugPrint('🔐 Google Sign-In started...');
    isSignInGoogle(true);

    await _googleSignIn.signOut();
    debugPrint('Previous Google sessions cleared');

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('❌ Google sign-in cancelled by user');
      return null;
    }

    debugPrint('✅ Google user selected: ${googleUser.email}');

    final String? googleEmail = googleUser.email;
    if (googleEmail == null || googleEmail.isEmpty) {
      debugPrint('❌ Google account has no email address');
      Get.snackbar('Error', 'Google account must have a valid email address');
      await _googleSignIn.signOut();
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    debugPrint('✅ Google authentication tokens received');

    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      debugPrint('❌ Missing Google authentication tokens');
      throw Exception('Failed to get Google authentication tokens');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    debugPrint('✅ Firebase credential created');

    final UserCredential userCredential = await auth.signInWithCredential(credential);
    final User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Firebase sign-in failed - no user returned');
    }

    debugPrint('✅ Firebase authentication successful');
    debugPrint('Firebase User UID: ${firebaseUser.uid}');

    // ✅ CRITICAL FIX: Sync FCM token BEFORE handling user
    debugPrint('🔄 Syncing FCM token and platform info...');
    await _syncFCMToken(firebaseUser);
    debugPrint('✅ FCM token and platform synced');

    // Handle user based on whether they're new or existing
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      debugPrint('🆕 Handling new user...');
      await _handleNewGoogleUser(firebaseUser, googleUser);
    } else {
      debugPrint('👤 Handling existing user...');
      await _handleExistingGoogleUser(firebaseUser);
    }

    debugPrint('✅ Google sign-in completed successfully');
    return userCredential;
  } catch (e) {
    debugPrint('❌ Google sign-in error: $e');

    if (e is FirebaseAuthException) {
      _handleFirebaseAuthException(e);
    } else if (e is PlatformException) {
      _handlePlatformException(e);
    } else {
      Get.snackbar(
        'Sign-in Failed',
        'An unexpected error occurred: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }

    return null;
  } finally {
    isSignInGoogle(false);
  }
}

  // Handle new Google user
Future<void> _handleNewGoogleUser(
    User firebaseUser, GoogleSignInAccount googleUser) async {
  debugPrint('Handling new Google user: ${firebaseUser.uid}');

  try {
    // ✅ CRITICAL: Set user ID FIRST
    _notificationController?.setUserId(firebaseUser.uid);
    debugPrint('📱 Notifications initialized for new user: ${firebaseUser.uid}');
    
    final String email = googleUser.email;
    final String displayName = googleUser.displayName ??
        firebaseUser.displayName ??
        email.split('@')[0];

   final userData = {
  'uid': firebaseUser.uid,
  'email': email,
  'displayName': displayName,
  'photoURL': googleUser.photoUrl ?? firebaseUser.photoURL ?? '',
  'phoneNumber': firebaseUser.phoneNumber ?? '',
  'role': 'user',
  'status': 'active',
  'provider': 'google',
  'mode': _getPlatformInfo(), // ✅ Add this
  'location': '',
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'registrationCompleted': true,
  'modeupdated': _getPlatformInfo(), // ✅ Add this
  'lastLoginAt': FieldValue.serverTimestamp(),
};

    debugPrint('Creating Firestore document with data: $userData');

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userData, SetOptions(merge: true));

    debugPrint('✅ Firestore document created successfully');

    userRole.value = 'user';

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: email,
      name: displayName,
      role: 'user',
      status: 'active',
      location: '',
      phoneNumber: firebaseUser.phoneNumber ?? '',
    );

    Get.find<UserController>().currentUser = userModel;
    debugPrint('✅ User model created and stored: ${userModel.toJson()}');

    // ✅ Log login activity for new Google user
    await _logLoginActivity(firebaseUser.uid);

    Get.snackbar(
      'Welcome!',
      'Account created successfully for $email',
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      duration: const Duration(seconds: 3),
    );

    navigateToHome();
  } catch (e) {
    debugPrint('❌ Error creating new Google user: $e');
    _notificationController?.clearUserId();
    
    Get.snackbar(
      'Account Creation Failed',
      'Failed to create account. Please try again.',
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      duration: const Duration(seconds: 5),
    );

    try {
      await auth.signOut();
      await _googleSignIn.signOut();
    } catch (signOutError) {
      debugPrint('Error during cleanup: $signOutError');
    }

    Get.offAllNamed('/login');
  }
  
}


  // Handle existing Google user
  Future<void> _handleExistingGoogleUser(User user) async {
    try {
      // Check user's data in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      debugPrint('Checking existing user document for UID: ${user.uid}');

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final status = userData['status'] ?? 'active';

        userRole.value = userData['role'] ?? '';

        debugPrint('User role fetched: ${userRole.value}');

        // Check if account is active
        if (status == 'suspended' || status == 'banned') {
          await auth.signOut();
          await _googleSignIn.signOut();
          Get.snackbar(
            'Account Suspended',
            'Your account has been suspended. Please contact support.',
            backgroundColor: Colors.orange[100],
            colorText: Colors.orange[800],
          );
          return;
        }

        // Create user model
        final userModel = UserModel(
          location: userData['location'] ?? '',
          phoneNumber: userData['phoneNumber'] ?? '',
          uid: user.uid,
          email: user.email ?? userData['email'] ?? '',
          name: userData['displayName'] ?? user.displayName ?? '',
          role: userData['role'] ?? '',
          status: status,
        );

        debugPrint('''
UID: ${userModel.uid}
Email: ${userModel.email}
Phone: ${userModel.phoneNumber}
Location: ${userModel.location}
Name: ${userModel.name}
Role: ${userModel.role}
Status: ${userModel.status}
Image URL: ${userModel.imageUrl}
''');

        // Store user in controller
        Get.find<UserController>().currentUser = userModel;
        debugPrint('Existing user logged in: ${userModel.toJson()}');

        // ✅ Log login activity for existing Google user
        await _logLoginActivity(user.uid);

        // Navigate based on role
        if (userModel.role == 'tenant') {
          debugPrint('Navigating to Tenant Dashboard...');
          Get.offAllNamed(AppRoute.navbar);
        } else if (userModel.role == 'agent') {
          debugPrint('Navigating to Agent Dashboard...');
          Get.offAllNamed(AppRoute.navbar);
        } else if (userModel.role == 'technician') {
          debugPrint('Navigating to Technician Dashboard...');
          Get.offAllNamed(AppRoute.technicianDashboard);
        } else {
          debugPrint('Navigating to User Home...');
          navigateToHome();
        }
      } else {
        debugPrint('User document not found for existing user');
        // This shouldn't happen, but handle gracefully
        await _handleLegacyGoogleUser(user);
      }
    } catch (e) {
      debugPrint('Error handling existing Google user: $e');
      Get.snackbar('Error', 'Failed to load user data. Please try again.');
      await auth.signOut();
      await _googleSignIn.signOut();
    }
  }

  // Handle legacy users (existing Firebase users without proper user documents)
  Future<void> _handleLegacyGoogleUser(User user, {String role = 'user'}) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'role': role,
        'status': 'active',
        'profilePicture': user.photoURL,
        'provider': 'google',
        'location': '',
        'phoneNumber': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isLegacyUser': true,
        'registrationCompleted': true,
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
      userRole.value = role;

      final userModel = UserModel(
        location: '',
        phoneNumber: '',
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        role: role,
        status: 'active',
      );

      Get.find<UserController>().currentUser = userModel;

      Get.snackbar(
        'Welcome Back',
        'Your account has been updated successfully.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      // Navigate based on role
      if (role == 'tenant') {
        Get.offAllNamed(AppRoute.navbar);
      } else if (role == 'agent') {
        Get.offAllNamed(AppRoute.navbar);
      } else {
        navigateToHome();
      }
    } catch (e) {
      debugPrint('Error handling legacy Google user: $e');
      Get.snackbar('Error', 'Account setup failed. Please try again.');
      await auth.signOut();
      await _googleSignIn.signOut();
    }
  }

  // Handle platform-specific exceptions
  void _handlePlatformException(PlatformException e) {
    String message;

    switch (e.code) {
      case 'sign_in_failed':
        message = 'Google sign-in failed. Please try again.';
        break;
      case 'network_error':
        message = 'Network error. Please check your internet connection.';
        break;
      case 'sign_in_canceled':
        return; // Don't show error for user cancellation
      default:
        message = 'Sign-in failed. Please try again.';
    }

    Get.snackbar(
      'Sign-in Error',
      message,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
    );
  }

  // Handle Firebase Auth exceptions
  void _handleFirebaseAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'account-exists-with-different-credential':
        message =
            'An account already exists with this email using a different sign-in method.';
        break;
      case 'operation-not-allowed':
        message = 'Google sign-in is not enabled. Please contact support.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled. Please contact support.';
        break;
      case 'invalid-credential':
        message = 'Invalid credentials. Please try again.';
        break;
      case 'too-many-requests':
        message = 'Too many failed attempts. Please try again later.';
        break;
      default:
        message = 'Sign-in failed. Please try again.';
    }

    Get.snackbar(
      'Sign-in Error',
      message,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
    );
  }

  // Agent Registration with Email/Password
  Future<void> registerAgent() async {
    try {
      isRegisterAgent(true);
      // Validate form fields
      if (emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          fullNameController.text.isEmpty ||
          mobileNoController.text.isEmpty) {
        Get.snackbar('Error', 'Please fill all fields');
        return;
      }

      if (passwordController.text.length < 6) {
        Get.snackbar('Error', 'Password must be at least 6 characters');
        return;
      }

      // Create user in Firebase Auth
      final credential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Create agent profile in Firestore
      if (credential.user == null) {
        Get.snackbar('Error', 'User creation failed');
        return;
      } else {
        await setAgentRole(
          fullNameController.text,
          mobileNoController.text,
          selectedGender.value,
          profilePictureUrl.value.isNotEmpty ? profilePictureUrl.value : null,
          selectedDate.value.isNotEmpty ? selectedDate.value : null,
          selectedWhatsAppStatus.value,
          selectedWhatsAppStatus.value
              ? mobileNoController.text
              : whatsAppNumberController.text.isNotEmpty
                  ? whatsAppNumberController.text
                  : null,
          locationController.text.isNotEmpty ? locationController.text : null,
        );
      }
      Get.snackbar('Success', 'Agent registration submitted for approval');
      Get.offAllNamed(AppRoute.approvalPendingPage);
      clearControllers();
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Registration failed';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email already registered';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      }
      Get.snackbar('Error', errorMessage);
    } catch (e) {
      Get.snackbar('Error', 'Registration failed: ${e.toString()}');
      debugPrint('Agent registration error: $e');
    } finally {
      isRegisterAgent(false);
    }
  }

  // Email/Password Sign-In for Agents
 Future<UserCredential?> signInAsAgent() async {
  try {
    isSignInAgent(true);
    debugPrint('Attempting agent sign in...');
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    debugPrint('Email: $email');

    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    debugPrint('Firebase authentication successful, verifying agent role...');
    debugPrint('User UID: ${credential.user?.uid}');

    // ✅ CRITICAL: Set user ID immediately
    if (credential.user != null) {
      _notificationController?.setUserId(credential.user!.uid);
      debugPrint('📱 Notifications loaded for agent: ${credential.user!.uid}');
      
      // ✅ CRITICAL FIX: Sync FCM token and platform info
      debugPrint('🔄 Syncing FCM token and platform info...');
      await _syncFCMToken(credential.user!);
      debugPrint('✅ FCM token and platform synced');
    }

    // Verify this is actually an agent
    final userDoc = await _firestore.collection('agents').doc(credential.user?.uid).get();

    if (userDoc.exists &&
        userDoc.data()?['role'] == 'agent' &&
        userDoc.data()?['status'] == 'approved') {
      debugPrint('Agent verification successful');
      userRole.value = 'agent';
      
      final userData = userDoc.data();
      final userModel = AgentModel(
        dob: userData?['dob'] ?? '',
        gender: userData?['gender'] ?? '',
        location: userData?['location'] ?? '',
        uid: credential.user!.uid,
        email: credential.user!.email!,
        name: userData?['displayName'] ?? '',
        role: userData?['role'] ?? 'agent',
        status: userData?['status'] ?? 'pending',
      );

      Get.find<AgentController>().currentUser = userModel;
      debugPrint('User details stored: ${userModel.toJson()}');

      // ✅ Log login activity for agent
      await _logLoginActivity(credential.user!.uid);

      navigateToHome();
      debugPrint('Navigation to agent home completed');

      return credential;
    } else {
      debugPrint('Account is not registered as an agent');
      _notificationController?.clearUserId();
      await auth.signOut();
      Get.snackbar('Error',
          '"Sorry! Your account isn\'t registered as an agent yet or still needs approval. Please contact support if you think this is a mistake."');
      return null;
    }
  } on FirebaseAuthException catch (e) {
    debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
    _notificationController?.clearUserId();
    Get.snackbar('Error', 'Agent login failed: ${e.message}');
    return null;
  } catch (e) {
    debugPrint('Unexpected Error: $e');
    _notificationController?.clearUserId();
    Get.snackbar('Error', 'An unexpected error occurred');
    return null;
  } finally {
    isSignInAgent(false);
    debugPrint('Sign in process completed');
  }
}


 Future<UserCredential?> signInAsTechnician() async {
  try {
    isSignInTechnician(true);
    debugPrint('Attempting technician sign in...');
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    debugPrint('Firebase authentication successful, verifying Technician role...');
    
    // ✅ CRITICAL: Set user ID immediately
    if (credential.user != null) {
      _notificationController?.setUserId(credential.user!.uid);
      debugPrint('📱 Notifications loaded for technician: ${credential.user!.uid}');
      
      // ✅ CRITICAL FIX: Sync FCM token and platform info
      debugPrint('🔄 Syncing FCM token and platform info...');
      await _syncFCMToken(credential.user!);
      debugPrint('✅ FCM token and platform synced');
    }
    
    final userDoc = await _firestore
        .collection('technicians')
        .doc(credential.user?.uid)
        .get();

    if (userDoc.exists && userDoc.data()?['role'] == 'technician') {
      debugPrint('Technician verification successful');
      userRole.value = 'technician';

      final userData = userDoc.data() as Map<String, dynamic>?;

      final userModel = TechnicianProfile(
        uid: userData?['uid'] ?? '',
        location: userData?['location'] ?? '',
        fullName: userData?['fullName'] ?? '',
        email: userData?['email'] ?? credential.user?.email ?? '',
        mobile: userData?['mobile'] ?? userData?['phoneNumber'] ?? '',
        photoURL: userData?['photoURL'] ?? '',
        role: userData?['role'] ?? 'technician',
      );

      Get.find<TechnicianController>().currentUser = userModel;
      debugPrint('Technician details stored: ${userModel.toJson()}');

      // ✅ Log login activity for technician
      await _logLoginActivity(credential.user!.uid);

      Get.offAllNamed(AppRoute.technicianDashboard);

      return credential;
    } else {
      debugPrint('Account is not registered as a technician');
      _notificationController?.clearUserId();
      await auth.signOut();
      Get.snackbar('Error', 'This account is not registered as a technician');
      return null;
    }
  } on FirebaseAuthException catch (e) {
    debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
    _notificationController?.clearUserId();
    Get.snackbar('Error', 'Technician login failed: ${e.message}');
    return null;
  } catch (e) {
    debugPrint('Unexpected Error: $e');
    _notificationController?.clearUserId();
    Get.snackbar('Error', 'An unexpected error occurred');
    return null;
  } finally {
    isSignInTechnician(false);
    debugPrint('Sign in process completed');
  }
}

  Future<void> setUserRole(String role, {String? tenantId}) async {
    final user = auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'phoneNumber': user.phoneNumber,
      'role': '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    userRole.value = role ?? '';
    userTenantId.value = tenantId ?? '';
  }

  Future<void> setAgentRole(
    String fullName,
    String mobileNo,
    String gender,
    String? profilePicUrl,
    String? dob,
    bool? isWhatsAppAvalable,
    String? whatsAppNumber,
    String? location,
  ) async {
    final user = auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'No user logged in');
      return;
    }

    try {
      final batch = _firestore.batch();

      final agentRef = _firestore.collection('agents').doc(user.uid);
      batch.set(
  agentRef,
  {
    'uid': user.uid,
    'email': user.email,
    'displayName': fullName,
    'mobile': mobileNo,
    'profilePic': "",
    'gender': gender,
    'dob': dob,
    'location': location,
    'whatsAppNumber': whatsAppNumber,
    'role': 'agent',
    'status': 'pending',
    'mode': _getPlatformInfo(), // ✅ Add this
    'createdAt': FieldValue.serverTimestamp(),
    'modeupdated': _getPlatformInfo(), // ✅ Add this
    'lastLoginAt': FieldValue.serverTimestamp(),
  },
  SetOptions(merge: true)
);

      await batch.commit();

      userRole.value = 'agent';
      Get.offAllNamed('/agent-pending');
    } catch (e) {
      Get.snackbar('Error', 'Failed to set agent role: ${e.toString()}');
      debugPrint('Error setting agent role: $e');
    }
  }


/// One-time method to update existing users with platform info
Future<void> updateExistingUsersWithPlatform() async {
  try {
    final currentUser = auth.currentUser;
    if (currentUser == null) return;

    final platformInfo = _getDeviceInfo();
    
    // Check all possible collections
    final collections = ['users', 'agents', 'technicians'];
    
    for (final collection in collections) {
      final doc = await _firestore.collection(collection).doc(currentUser.uid).get();
      if (doc.exists) {
        await _firestore.collection(collection).doc(currentUser.uid).update(platformInfo);
        debugPrint('✅ Updated $collection/${currentUser.uid} with platform info');
        break;
      }
    }
  } catch (e) {
    debugPrint('❌ Error updating platform info: $e');
  }
}
  Future<UserModel?> loginWithPhone(String phone) async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("mobile", isEqualTo: phone)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return UserModel.fromJson(data);
    } else {
      return null;
    }
  }

 Future<UserCredential?> signInWithApple() async {
  try {
    debugPrint('🔐 Apple Sign-In started...');
    isSignInApple(true);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    debugPrint('✅ Apple credential received');
    debugPrint('Apple user ID: ${appleCredential.userIdentifier}');

    if (appleCredential.identityToken == null) {
      debugPrint('❌ Missing Apple identity token');
      throw Exception('Failed to get Apple authentication token');
    }

    final OAuthCredential credential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    debugPrint('✅ Firebase credential created');

    final UserCredential userCredential = await auth.signInWithCredential(credential);
    final User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Firebase sign-in failed - no user returned');
    }

    debugPrint('✅ Firebase authentication successful');
    debugPrint('Firebase User UID: ${firebaseUser.uid}');

    // ✅ CRITICAL FIX: Sync FCM token BEFORE handling user
    debugPrint('🔄 Syncing FCM token and platform info...');
    await _syncFCMToken(firebaseUser);
    debugPrint('✅ FCM token and platform synced');

    // Handle user based on whether they're new or existing
    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      debugPrint('🆕 Handling new Apple user...');
      await _handleNewAppleUser(firebaseUser, appleCredential);
    } else {
      debugPrint('👤 Handling existing Apple user...');
      await _handleExistingAppleUser(firebaseUser);
    }

    debugPrint('✅ Apple sign-in completed successfully');
    return userCredential;
  } catch (e) {
    debugPrint('❌ Apple sign-in error: $e');

    if (e is FirebaseAuthException) {
      _handleFirebaseAuthException(e);
    } else if (e is SignInWithAppleAuthorizationException) {
      _handleAppleAuthException(e);
    } else {
      Get.snackbar(
        'Sign-in Failed',
        'An unexpected error occurred: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
      );
    }

    return null;
  } finally {
    isSignInApple(false);
  }
}

  // Handle new Apple user
  Future<void> _handleNewAppleUser(
    User firebaseUser, AuthorizationCredentialAppleID appleCredential) async {
  debugPrint('Handling new Apple user: ${firebaseUser.uid}');

  try {
    // ✅ CRITICAL: Set user ID FIRST
    _notificationController?.setUserId(firebaseUser.uid);
    debugPrint('📱 Notifications initialized for new Apple user: ${firebaseUser.uid}');
    
    String email = appleCredential.email ?? firebaseUser.email ?? '';

    if (email.isEmpty) {
      email = '${firebaseUser.uid}@privaterelay.appleid.com';
      debugPrint('⚠ No email provided, using private relay: $email');
    }

    String displayName = '';
    if (appleCredential.givenName != null ||
        appleCredential.familyName != null) {
      displayName =
          '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
              .trim();
    }

    if (displayName.isEmpty) {
      displayName = firebaseUser.displayName ?? email.split('@')[0];
    }

   final userData = {
  'uid': firebaseUser.uid,
  'email': email,
  'displayName': displayName,
  'photoURL': firebaseUser.photoURL ?? '',
  'phoneNumber': firebaseUser.phoneNumber ?? '',
  'role': 'user',
  'status': 'active',
  'provider': 'apple',
  'mode': _getPlatformInfo(), // ✅ Add this
  'appleUserId': appleCredential.userIdentifier,
  'location': '',
  'createdAt': FieldValue.serverTimestamp(),
  'updatedAt': FieldValue.serverTimestamp(),
  'registrationCompleted': true,
  'modeupdated': _getPlatformInfo(), // ✅ Add this
  'lastLoginAt': FieldValue.serverTimestamp(),
};

    await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .set(userData, SetOptions(merge: true));

    debugPrint('✅ Firestore document created successfully');

    userRole.value = 'user';

    final userModel = UserModel(
      uid: firebaseUser.uid,
      email: email,
      name: displayName,
      role: 'user',
      status: 'active',
      location: '',
      phoneNumber: firebaseUser.phoneNumber ?? '',
    );

    Get.find<UserController>().currentUser = userModel;
    debugPrint('✅ User model created and stored: ${userModel.toJson()}');

    // ✅ Log login activity for new Apple user
    await _logLoginActivity(firebaseUser.uid);

    Get.snackbar(
      'Welcome!',
      'Account created successfully${email.contains('privaterelay') ? '' : ' for $email'}',
      backgroundColor: Colors.green[100],
      colorText: Colors.green[800],
      duration: const Duration(seconds: 3),
    );

    navigateToHome();
  } catch (e) {
    debugPrint('❌ Error creating new Apple user: $e');
    _notificationController?.clearUserId();

    Get.snackbar(
      'Account Creation Failed',
      'Failed to create account. Please try again.',
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
      duration: const Duration(seconds: 5),
    );

    try {
      await auth.signOut();
    } catch (signOutError) {
      debugPrint('Error during cleanup: $signOutError');
    }

    Get.offAllNamed('/login');
  }
}

  // Handle existing Apple user
  Future<void> _handleExistingAppleUser(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      debugPrint('Checking existing user document for UID: ${user.uid}');

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final status = userData['status'] ?? 'active';

        userRole.value = userData['role'] ?? '';

        debugPrint('User role fetched: ${userRole.value}');

        if (status == 'suspended' || status == 'banned') {
          await auth.signOut();
          Get.snackbar(
            'Account Suspended',
            'Your account has been suspended. Please contact support.',
            backgroundColor: Colors.orange[100],
            colorText: Colors.orange[800],
          );
          return;
        }

        final userModel = UserModel(
          location: userData['location'] ?? '',
          phoneNumber: userData['phoneNumber'] ?? '',
          uid: user.uid,
          email: user.email ?? userData['email'] ?? '',
          name: userData['displayName'] ?? user.displayName ?? '',
          role: userData['role'] ?? '',
          status: status,
        );

        debugPrint('''
UID: ${userModel.uid}
Email: ${userModel.email}
Phone: ${userModel.phoneNumber}
Location: ${userModel.location}
Name: ${userModel.name}
Role: ${userModel.role}
Status: ${userModel.status}
Image URL: ${userModel.imageUrl}
''');

        Get.find<UserController>().currentUser = userModel;
        debugPrint('Existing user logged in: ${userModel.toJson()}');

        // ✅ Log login activity for existing Apple user
        await _logLoginActivity(user.uid);

        // Navigate based on role
        if (userModel.role == 'tenant') {
          debugPrint('Navigating to Tenant Dashboard...');
          Get.offAllNamed(AppRoute.navbar);
        } else if (userModel.role == 'agent') {
          debugPrint('Navigating to Agent Dashboard...');
          Get.offAllNamed(AppRoute.navbar);
        } else if (userModel.role == 'technician') {
          debugPrint('Navigating to Technician Dashboard...');
          Get.offAllNamed(AppRoute.technicianDashboard);
        } else {
          debugPrint('Navigating to User Home...');
          navigateToHome();
        }
      } else {
        debugPrint('User document not found for existing user');
        await _handleLegacyAppleUser(user);
      }
    } catch (e) {
      debugPrint('Error handling existing Apple user: $e');
      Get.snackbar('Error', 'Failed to load user data. Please try again.');
      await auth.signOut();
    }
  }

  // Handle legacy Apple users
  Future<void> _handleLegacyAppleUser(User user, {String role = 'user'}) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'role': role,
        'status': 'active',
        'profilePicture': user.photoURL,
        'provider': 'apple',
        'location': '',
        'phoneNumber': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isLegacyUser': true,
        'registrationCompleted': true,
      };

      await _firestore.collection('users').doc(user.uid).set(userData);
      userRole.value = role;

      final userModel = UserModel(
        location: '',
        phoneNumber: '',
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        role: role,
        status: 'active',
      );

      Get.find<UserController>().currentUser = userModel;

      Get.snackbar(
        'Welcome Back',
        'Your account has been updated successfully.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      if (role == 'tenant') {
        Get.offAllNamed(AppRoute.navbar);
      } else if (role == 'agent') {
        Get.offAllNamed(AppRoute.navbar);
      } else {
        navigateToHome();
      }
    } catch (e) {
      debugPrint('Error handling legacy Apple user: $e');
      Get.snackbar('Error', 'Account setup failed. Please try again.');
      await auth.signOut();
    }
  }

  // Handle Apple-specific authorization exceptions
  void _handleAppleAuthException(SignInWithAppleAuthorizationException e) {
    String message;

    switch (e.code) {
      case AuthorizationErrorCode.canceled:
        debugPrint('User canceled Apple Sign In');
        return;
      case AuthorizationErrorCode.failed:
        message = 'Apple sign-in failed. Please try again.';
        break;
      case AuthorizationErrorCode.invalidResponse:
        message = 'Invalid response from Apple. Please try again.';
        break;
      case AuthorizationErrorCode.notHandled:
        message = 'Apple sign-in could not be completed. Please try again.';
        break;
      case AuthorizationErrorCode.unknown:
        message = 'An unknown error occurred. Please try again.';
        break;
      default:
        message = 'Sign-in failed. Please try again.';
    }

    Get.snackbar(
      'Sign-in Error',
      message,
      backgroundColor: Colors.red[100],
      colorText: Colors.red[800],
    );
  }

  void navigateGuestToHome() async {
    await _googleSignIn.signOut();
    await auth.signOut();
    userRole.value = "guest";
    Get.toNamed(AppRoute.navbar);
  }

  void navigateToHome() {
    Get.offAllNamed(AppRoute.navbar);
  }

  void navigateToLogin() {
    Get.offAllNamed(AppRoute.login);
  }

 Future<void> signOut() async {
  try {
    isSignOutAll(true);
    
    debugPrint('🚪 Starting sign out process...');
    
    // ✅ Clear notifications BEFORE signing out (saves them first)
    _notificationController?.clearUserId();
    
    // Clear auto-login flag
    hasCheckedAutoLogin(false);
    
    // Sign out from Google
    await _googleSignIn.signOut();
    
    // Sign out from Firebase
    await auth.signOut();
    
    // Clear user role
    userRole.value = '';
    
    debugPrint('✅ User signed out successfully');
    
    // Navigate to login
    Get.offAllNamed(AppRoute.login);
  } catch (e) {
    debugPrint('❌ Error during sign out: $e');
    Get.snackbar('Error', 'Failed to sign out: $e');
  } finally {
    isSignOutAll(false);
  }
}
  
  @override
  void onClose() {
    _resendTimer?.cancel();
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    mobileNoController.dispose();
    locationController.dispose();
    whatsAppNumberController.dispose();
    super.onClose();
  }

  void clearControllers() {
    emailController.clear();
    passwordController.clear();
    fullNameController.clear();
    mobileNoController.clear();
    locationController.clear();
    whatsAppNumberController.clear();
  }
}