// lib/services/auth_service.dart
import 'dart:async';

import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/model/agent_model.dart';
import 'package:dar_al_safwa/domain/controller/agent_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../data/model/user_model.dart';
import '../../domain/controller/user_controller.dart';

class AuthService extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final Rxn<User> firebaseUser = Rxn<User>();
  final RxString userRole = RxString('');
  final RxString userTenantId = RxString('');
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController mobileNoController = TextEditingController();

  var isSignInAgent = false.obs;
  var isSignInTenant = false.obs;
  var isSignInGoogle = false.obs;
  var isSignInPhone = false.obs;
  var isVerifyPhone = false.obs;
  var isRegisterAgent = false.obs;
  var isSignOutAll = false.obs;

  final resendEnabled = false.obs;
  final secondsRemaining = 60.obs;
  Timer? _resendTimer;
  int? _resendToken;
  String verificationId = '';

  // @override
  // void onReady() {
  //   firebaseUser.bindStream(_auth.authStateChanges());
  //   ever(firebaseUser, _handleAuthChanged);
  // }

  void handleAuthChanged(User? user) async {
    if (user == null) {
      Get.offAllNamed('/login');
    } else {
      // Fetch user role from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        userRole.value = userDoc.data()?['role'] ?? '';
        userTenantId.value = userDoc.data()?['tenantId'] ?? '';

        // Redirect based on role
        if (userRole.value == 'agent') {
          debugPrint('Agent logged in: ${user.displayName}');
          // Get.offAllNamed('/agent-dashboard');
        } else if (userRole.value == 'tenant') {
          debugPrint('tenant logged in: ${user.displayName}');
          Get.offAllNamed('/tenant-dashboard');
        }
      } else {
        // New user - need to set role (only for Google users)
        if (user.providerData.any((info) => info.providerId == 'google.com')) {
          Get.offAllNamed('/role-selection');
        }
      }
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

  @override
  void onClose() {
    _resendTimer?.cancel();
    super.onClose();
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
          // Get.snackbar(
          //   'Timeout',
          //   'SMS not received? Tap "Resend" to try again.',
          //   duration: const Duration(seconds: 5),
          //   mainButton: TextButton(
          //     onPressed: () => signInWithPhone(
          //       phoneNumber: phoneNumber,
          //       onVerificationCompleted: onVerificationCompleted,
          //       onVerificationFailed: onVerificationFailed,
          //       onCodeSent: onCodeSent,
          //       onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
          //       resend: true, // Force resend
          //     ),
          //     child: const Text('Resend'),
          //   ),
          // );
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

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _createNewPhoneUser(userCredential.user!);
      } else {
        await _handleExistingPhoneUser(userCredential.user!);
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
        navigateToHome();
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
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      userRole.value = 'user';

      await _updateUserInController(userModel);
      navigateToHome();
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

  // Google Sign-In for Users/Tenants
  Future<UserCredential?> signInWithGoogle() async {
    try {
      isSignInGoogle(true);
      debugPrint('Starting Google sign-in...');

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credentials
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      // Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        // New user - set default role as 'user'
        await setUserRole(
          'user',
        );

        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc.data()?['role'] ?? 'user';
          userRole.value = role;

          // Store user details for app-wide access
          final userData = userDoc.data();
          // Redirect based on role

          final userModel = UserModel(
            uid: userData?['uid'],
            email: userData?['email'],
            name: userData?['displayName'] ?? '',
            role: userData?['role'] ?? 'user',
            status: userData?['status'] ?? 'pending',
            // Add other fields as needed
          );

          Get.find<UserController>().currentUser = userModel;
          debugPrint('User details stored: ${userModel.toJson()}');

          navigateToHome();
        } else {}
        // Redirect to complete profile or role selection
        // Get.offAllNamed(AppRoute.completeProfile);
      } else {
        // Existing user - handle according to their role
        await _handleExistingGoogleUser(userCredential.user!);
      }

      return userCredential;
    } catch (e) {
      Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
      debugPrint('Google sign-in error: $e');
      if (e is FirebaseAuthException) {
        if (e.code == 'account-exists-with-different-credential') {
          Get.snackbar(
              'Error', 'Account already exists with different credential');
        } else if (e.code == 'operation-not-allowed') {
          Get.snackbar('Error', 'Operation not allowed');
        } else {
          Get.snackbar('Error', 'Google sign-in failed: ${e.message}');
        }
      } else {
        Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
      }
      return null;
    } finally {
      isSignInGoogle(false);
    }
  }

  Future<void> _handleExistingGoogleUser(User user) async {
    // Check user's role in Firestore
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (userDoc.exists) {
      final role = userDoc.data()?['role'] ?? 'user';
      userRole.value = role;

      // Store user details for app-wide access
      final userData = userDoc.data();
      // Redirect based on role

      final userModel = UserModel(
        uid: userData?['uid'] ?? user.uid,
        email: userData?['email'] ?? user.email,
        name: userData?['displayName'] ?? '',
        role: userData?['role'] ?? 'user',
        status: userData?['status'] ?? 'pending',
        // Add other fields as needed
      );

      Get.find<UserController>().currentUser = userModel;
      debugPrint('User details stored: ${userModel.toJson()}');

      navigateToHome();
    } else {
      // Legacy user - create record with default role
      await setUserRole(
        'user',
      );
      navigateToHome();
    }
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

      // Send email verification
      // await credential.user?.sendEmailVerification();

      // Create agent profile in Firestore
      if (credential.user == null) {
        Get.snackbar('Error', 'User creation failed');
        return;
      } else {
        await setAgentRole(
          fullNameController.text,
          mobileNoController.text,
        );
      }
      Get.snackbar('Success', 'Agent registration submitted for approval');
      Get.offAllNamed(AppRoute.approvalPendingPage);
      clearControllers(); // Clear input fields after registration
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
      debugPrint(
          'Password: ${'*' * password.length}'); // Don't print actual password

      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('Firebase authentication successful, verifying agent role...');
      debugPrint('User UID: ${credential.user?.uid}');

      // Verify this is actually an agent
      final userDoc =
          await _firestore.collection('agents').doc(credential.user?.uid).get();

      if (userDoc.exists && userDoc.data()?['role'] == 'agent') {
        debugPrint('Agent verification successful');
        userRole.value = 'agent';
        // Store user details for app-wide access
        final userData = userDoc.data();
        final userModel = AgentModel(
          uid: credential.user!.uid,
          email: credential.user!.email!,
          name: userData?['displayName'] ?? '',
          role: userData?['role'] ?? 'agent',
          status: userData?['status'] ?? 'pending',
          // Add other fields as needed
        );

        // Assuming you have a user service or controller to store this
        Get.find<AgentController>().currentUser = userModel;
        debugPrint('User details stored: ${userModel.toJson()}');

        // Navigate to home
        navigateToHome();
        debugPrint('Navigation to agent home completed');

        return credential;
      } else {
        debugPrint('Account is not registered as an agent');
        await auth.signOut();
        Get.snackbar('Error', 'This account is not registered as an agent');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      Get.snackbar('Error', 'Agent login failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      Get.snackbar('Error', 'An unexpected error occurred');
      return null;
    } finally {
      isSignInAgent(false);
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
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    userRole.value = role;
    userTenantId.value = tenantId ?? '';
  }

  // Updated AuthService with proper agent role setting
  Future<void> setAgentRole(
    String fullName,
    String mobileNo,
  ) async {
    final user = auth.currentUser;
    if (user == null) {
      Get.snackbar('Error', 'No user logged in');
      return;
    }

    // First check if this is an allowed agent email (optional security check)
    // if (!_isValidAgentEmail(user.email)) {
    //   Get.snackbar('Error', 'This email is not authorized for agent access');
    //   await _auth.signOut();
    //   return;
    // }

    try {
      // Create/update document in both collections for easy querying
      final batch = _firestore.batch();

      // // Main users collection
      // final userRef = _firestore.collection('agents').doc(user.uid);
      // batch.set(
      //     userRef,
      //     {
      //       'uid': user.uid,
      //       'email': user.email,
      //       'displayName': user.displayName ?? 'Agent',
      //       'photoURL': user.photoURL,
      //       'role': 'agent',
      //       'isApproved': false, // Admin needs to approve
      //       'createdAt': FieldValue.serverTimestamp(),
      //       'lastLogin': FieldValue.serverTimestamp(),
      //     },
      //     SetOptions(merge: true));

      // Agents-specific collection
      final agentRef = _firestore.collection('agents').doc(user.uid);
      batch.set(
          agentRef,
          {
            'uid': user.uid,
            'email': user.email,
            'displayName': fullName,
            'mobile': mobileNo,
            'role': 'agent',
            'status': 'pending', // pending/approved/rejected
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      await batch.commit();

      userRole.value = 'agent';
      Get.offAllNamed('/agent-pending'); // Redirect to pending approval screen
    } catch (e) {
      Get.snackbar('Error', 'Failed to set agent role: ${e.toString()}');
      debugPrint('Error setting agent role: $e');
    }
  }

  // bool _isValidAgentEmail(String? email) {
  //   // Add your domain validation logic here
  //   const allowedDomains = ['@yourcompany.com', '@agent.yourcompany.com'];
  //   return email != null && allowedDomains.any(email.endsWith);
  // }
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
    isSignOutAll(true);
    await _googleSignIn.signOut();
    await auth.signOut();
    navigateToLogin();
    isSignOutAll(false);
  }

  @override
  void dispose() {
    // Dispose all controllers when the widget is disposed
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    mobileNoController.dispose();
    super.dispose();
  }

  void clearControllers() {
    // Clear all text fields
    emailController.clear();
    passwordController.clear();
    fullNameController.clear();
    mobileNoController.clear();
  }
}
