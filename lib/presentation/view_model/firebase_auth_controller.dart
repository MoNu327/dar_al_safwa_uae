import 'dart:async';
import 'dart:core';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/data/model/agent_model.dart';
import 'package:majan/data/model/technician_model.dart';
import 'package:majan/domain/controller/agent_controller.dart';
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
  final TextEditingController whatsAppNumberController =
      TextEditingController();

  var isSignInAgent = false.obs;
  var isSignInTenant = false.obs;
  var isSignInTechnician = false.obs;
  var isSignInGoogle = false.obs;
  final isSignInApple = false.obs;

  var isSignInPhone = false.obs;
  var isVerifyPhone = false.obs;
  var isRegisterAgent = false.obs;
  var isSignOutAll = false.obs;

  final resendEnabled = false.obs;
  final secondsRemaining = 60.obs;
  Timer? _resendTimer;
  int? _resendToken;
  String verificationId = '';

  @override
  void onReady() {
    firebaseUser.bindStream(auth.authStateChanges());
    ever(firebaseUser, handleAuthChanged);
  }

// void handleAuthChanged(User? user) async {
//   if (user == null) {
//     Get.offAllNamed('/login');
//   } else {
//     // Check if user is a technician first
//     final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
//     if (technicianDoc.exists && technicianDoc.data()?['role'] == 'technician') {
//       await _handleTechnicianUser(user);
//       Get.offAllNamed(AppRoute.technicianDashboard);
//       return;
//     }

//     // Check if user is an agent
//     final agentDoc = await _firestore.collection('agents').doc(user.uid).get();
//     if (agentDoc.exists && agentDoc.data()?['role'] == 'agent' && agentDoc.data()?['status'] == 'approved') {
//       await _handleAgentUser(user);
//       Get.offAllNamed(AppRoute.agentdashboard);
//       return;
//     }

//     // Otherwise handle as regular user
//     await _handleExistingGoogleUser(user);
//   }
// }
  void handleAuthChanged(User? user) async {
    debugPrint('🔄 Auth state changed. User: ${user?.email ?? 'null'}');

    if (user == null) {
      debugPrint('👤 No user - redirecting to login');
      Get.offAllNamed('/login');
      return;
    }

    debugPrint('👤 User found: ${user.uid}');
    debugPrint('📧 Email: ${user.email}');
    debugPrint('📱 Phone: ${user.phoneNumber}');
    debugPrint('🆔 Display Name: ${user.displayName}');

    // If this is right after Google sign-in and email is null,
    // let the sign-in process handle it instead of this auth state change
    if (user.email == null && user.providerData.isNotEmpty) {
      final provider = user.providerData.first.providerId;
      if (provider == 'google.com') {
        debugPrint(
            '🔄 Google sign-in in progress, letting sign-in method handle user creation');
        return;
      }
    }

    try {
      // Check if user is a technician first
      debugPrint('🔍 Checking technician collection...');
      final technicianDoc =
          await _firestore.collection('technicians').doc(user.uid).get();

      if (technicianDoc.exists &&
          technicianDoc.data()?['role'] == 'technician') {
        debugPrint('✅ User is technician');
        await _handleTechnicianUser(user);
        Get.offAllNamed(AppRoute.technicianDashboard);
        return;
      }

      // Check if user is an agent
      debugPrint('🔍 Checking agents collection...');
      final agentDoc =
          await _firestore.collection('agents').doc(user.uid).get();

      if (agentDoc.exists &&
          agentDoc.data()?['role'] == 'agent' &&
          agentDoc.data()?['status'] == 'approved') {
        debugPrint('✅ User is approved agent');
        await _handleAgentUser(user);
        Get.offAllNamed(AppRoute.navbar);
        return;
      }

      // Check regular users collection
      debugPrint('🔍 Checking users collection...');
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        debugPrint('✅ User document found in users collection');
        debugPrint('📊 User data: $userData');
        await _handleExistingGoogleUser(user);
      } else {
        debugPrint('❌ No user document found in users collection');
        debugPrint(
            '🔄 User may have been created through Google sign-in process');
        // Don't immediately redirect - the Google sign-in process should handle this
      }
    } catch (e) {
      debugPrint('❌ Error in handleAuthChanged: $e');
      Get.snackbar(
        'Authentication Error',
        'Failed to load user data. Please try signing in again.',
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[800],
      );
    }
  }

  Future<void> _handleAgentUser(User user) async {
    try {
      final agentDoc =
          await _firestore.collection('agents').doc(user.uid).get();

      if (!agentDoc.exists || agentDoc.data()?['role'] != 'agent') {
        debugPrint('Agent document not found or role mismatch');
        await auth.signOut();
        Get.offAllNamed('/login');
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
        // Add other fields as needed
      );

      Get.find<AgentController>().currentUser = userModel;
      debugPrint('Agent user handled successfully: ${userModel.toJson()}');
    } catch (e) {
      debugPrint('Error handling agent user: $e');
      await auth.signOut();
      Get.offAllNamed('/login');
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
          // this.verificationId = verificationId;
          // _resendToken = null; // Reset resend token on timeout
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
        // navigateToHome();
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
      // navigateToHome();
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

      // Clean previous sessions
      await _googleSignIn.signOut();
      debugPrint('Previous Google sessions cleared');

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ Google sign-in cancelled by user');
        return null;
      }

      debugPrint('✅ Google user selected: ${googleUser.email}');
      debugPrint('Google user ID: ${googleUser.id}');
      debugPrint('Google user displayName: ${googleUser.displayName}');

      // IMPORTANT: Get email from GoogleSignInAccount, not Firebase User
      final String? googleEmail = googleUser.email;
      if (googleEmail == null || googleEmail.isEmpty) {
        debugPrint('❌ Google account has no email address');
        Get.snackbar('Error', 'Google account must have a valid email address');
        await _googleSignIn.signOut();
        return null;
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      debugPrint('✅ Google authentication tokens received');

      // Validate tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Missing Google authentication tokens');
        throw Exception('Failed to get Google authentication tokens');
      }

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('✅ Firebase credential created');

      // Sign in to Firebase
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase sign-in failed - no user returned');
      }

      debugPrint('✅ Firebase authentication successful');
      debugPrint('Firebase User UID: ${firebaseUser.uid}');
      debugPrint('Firebase User Email: ${firebaseUser.email}');
      debugPrint(
          'Google User Email: $googleEmail'); // This should have the email
      debugPrint(
          'Is New User: ${userCredential.additionalUserInfo?.isNewUser ?? false}');

      // Handle user based on whether they're new or existing
      // Pass the Google email as a parameter since Firebase User email might be null
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        debugPrint('🆕 Handling new user...');
        await _handleNewGoogleUser(
            firebaseUser, googleUser); // Pass GoogleSignInAccount
      } else {
        debugPrint('👤 Handling existing user...');
        await _handleExistingGoogleUser(firebaseUser);
      }

      debugPrint('✅ Google sign-in completed successfully');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Google sign-in error: $e');

      // Handle specific error types
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

// Handle new Google user - ask for confirmation
  Future<void> _handleNewGoogleUser(
      User firebaseUser, GoogleSignInAccount googleUser) async {
    debugPrint('Handling new Google user: ${firebaseUser.uid}');
    debugPrint('Firebase User email: ${firebaseUser.email}');
    debugPrint('Google User email: ${googleUser.email}');
    debugPrint(
        'User displayName: ${googleUser.displayName ?? firebaseUser.displayName}');

    try {
      // Use Google account email as the primary source
      final String email = googleUser.email;
      final String displayName = googleUser.displayName ??
          firebaseUser.displayName ??
          email.split('@')[0];

      // Create user document in Firestore with Google account data
      final userData = {
        'uid': firebaseUser.uid,
        'email': email, // Use Google email
        'displayName': displayName,
        'photoURL': googleUser.photoUrl ?? firebaseUser.photoURL ?? '',
        'phoneNumber': firebaseUser.phoneNumber ?? '',
        'role': 'user',
        'status': 'active',
        'provider': 'google',
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'registrationCompleted': true,
      };

      debugPrint('Creating Firestore document with data: $userData');

      // Create the document
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userData, SetOptions(merge: true));

      debugPrint('✅ Firestore document created successfully');

      // Verify the document was actually created
      final verificationDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!verificationDoc.exists) {
        throw Exception('Failed to create user document in Firestore');
      }

      final createdData = verificationDoc.data()!;
      debugPrint(
          '✅ Document verification successful. Email in DB: ${createdData['email']}');

      // Update local state
      userRole.value = 'user';

      // Create local user model with Google account data
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email, // Use Google email
        name: displayName,
        role: 'user',
        status: 'active',
        location: '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
      );

      // Store user in controller
      Get.find<UserController>().currentUser = userModel;
      debugPrint('✅ User model created and stored: ${userModel.toJson()}');

      // Show success message
      Get.snackbar(
        'Welcome!',
        'Account created successfully for $email',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 3),
      );

      // Navigate to home
      navigateToHome();
    } catch (e) {
      debugPrint('❌ Error creating new Google user: $e');

      String errorMessage;
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Database access denied. Please contact support.';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to create account. Please try again.';
      }

      Get.snackbar(
        'Account Creation Failed',
        errorMessage,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 5),
      );

      // Clean up authentication state
      try {
        await auth.signOut();
        await _googleSignIn.signOut();
      } catch (signOutError) {
        debugPrint('Error during cleanup: $signOutError');
      }

      // Navigate back to login
      Get.offAllNamed('/login');
    }
  }

// Show confirmation dialog for new user registration
  Future<bool?> _showRegistrationConfirmationDialog(User user) async {
    return await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Create Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage:
                  user.photoURL != null ? NetworkImage(user.photoURL!) : null,
              child: user.photoURL == null
                  ? const Icon(Icons.person, size: 30)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user.displayName ?? user.email ?? 'User'}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              user.email ?? 'No email provided',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Would you like to create a user account with this Google account?',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Create Account'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

// Create user account after confirmation
  Future<void> _createUserAccount(User user) async {
    try {
      // Create user document
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'role': 'user', // Fixed as user
        'status': 'active', // Users are active by default
        'profilePicture': user.photoURL,
        'provider': 'google',
        'location': '',
        'phoneNumber': '',
        'createdAt': FieldValue.serverTimestamp(),
        'registrationCompleted': true,
      };

      await _firestore.collection('users').doc(user.uid).set(userData);

      // Update local state
      userRole.value = 'user';

      // Create user model
      final userModel = UserModel(
        location: '',
        phoneNumber: '',
        uid: user.uid,
        email: user.email ?? '',
        name: user.displayName ?? '',
        role: 'user',
        status: 'active',
        // profilePicture: user.photoURL,
      );

      // Store user in controller
      Get.find<UserController>().currentUser = userModel;
      debugPrint('New user account created: ${userModel.toJson()}');

      // Show success message
      Get.snackbar(
        'Account Created',
        'Welcome! Your account has been created successfully.',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
      );

      navigateToHome();
    } catch (e) {
      debugPrint('Error creating user account: $e');
      Get.snackbar('Error', 'Failed to create account. Please try again.');
      await auth.signOut();
      await _googleSignIn.signOut();
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

          // profilePicture: userData['profilePicture'] ?? user.photoURL,
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
        // Store user in controller
        Get.find<UserController>().currentUser = userModel;
        debugPrint('Existing user logged in: ${userModel.toJson()}');

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
  Future<void> _handleLegacyGoogleUser(User user,
      {String role = 'user'}) async {
    try {
      final userData = {
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': user.displayName ?? '',
        'role': role, // dynamically set role
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

      if (userDoc.exists &&
          userDoc.data()?['role'] == 'agent' &&
          userDoc.data()?['status'] == 'approved') {
        debugPrint('Agent verification successful');
        userRole.value = 'agent';
        // Store user details for app-wide access
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
        Get.snackbar('Error',
            '"Sorry! Your account isn’t registered as an agent yet or still needs approval. Please contact support if you think this is a mistake."');
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

  Future<UserCredential?> signInAsTechnician() async {
    try {
      isSignInTechnician(true); // ✅ Correct loading state for technician
      debugPrint('Attempting technician sign in...');
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint(
          'Firebase authentication successful, verifying Technician role...');
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

        // Store user details in TechnicianController
        Get.find<TechnicianController>().currentUser = userModel;
        debugPrint('Technician details stored: ${userModel.toJson()}');

        // ✅ Navigate to Technician Dashboard
        Get.offAllNamed(AppRoute.technicianDashboard);

        return credential;
      } else {
        debugPrint('Account is not registered as a technician');
        await auth.signOut();
        Get.snackbar('Error', 'This account is not registered as a technician');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      Get.snackbar('Error', 'Technician login failed: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unexpected Error: $e');
      Get.snackbar('Error', 'An unexpected error occurred');
      return null;
    } finally {
      isSignInTechnician(false);
      debugPrint('Sign in process completed');
    }
  }

  Future<void> _handleTechnicianUser(User user) async {
    try {
      final technicianDoc =
          await _firestore.collection('technicians').doc(user.uid).get();
      // if (!technicianDoc.exists || technicianDoc.data()?['role'] != 'technician') {
      //   debugPrint('Technician document not found or role mismatch');
      //   await auth.signOut();
      //   Get.offAllNamed(AppRoute.login);
      //   return;
      // }

      final userData = technicianDoc.data()!;
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
    } catch (e) {
      debugPrint('Error handling technician user: $e');
      await auth.signOut();
      Get.offAllNamed(AppRoute.login);
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

  // Updated AuthService with proper agent role setting
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
      // Create/update document in both collections for easy querying
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
      return null; // user not found
    }
  }

  Future<UserCredential?> signInWithApple() async {
    try {
      debugPrint('🔐 Apple Sign-In started...');
      isSignInApple(true); // Add this observable to your controller

      // Trigger Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('✅ Apple credential received');
      debugPrint('Apple user ID: ${appleCredential.userIdentifier}');
      debugPrint(
          'Apple user email: ${appleCredential.email ?? 'Not provided'}');
      debugPrint(
          'Apple user givenName: ${appleCredential.givenName ?? 'Not provided'}');
      debugPrint(
          'Apple user familyName: ${appleCredential.familyName ?? 'Not provided'}');

      // Validate tokens
      if (appleCredential.identityToken == null) {
        debugPrint('❌ Missing Apple identity token');
        throw Exception('Failed to get Apple authentication token');
      }

      // Create Firebase credential
      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      debugPrint('✅ Firebase credential created');

      // Sign in to Firebase
      final UserCredential userCredential =
          await auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase sign-in failed - no user returned');
      }

      debugPrint('✅ Firebase authentication successful');
      debugPrint('Firebase User UID: ${firebaseUser.uid}');
      debugPrint('Firebase User Email: ${firebaseUser.email}');
      debugPrint(
          'Is New User: ${userCredential.additionalUserInfo?.isNewUser ?? false}');

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

      // Handle specific error types
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
    debugPrint('Firebase User email: ${firebaseUser.email}');
    debugPrint('Apple User email: ${appleCredential.email}');

    try {
      // Get email - Apple might not provide it if user chose to hide it
      // In that case, Firebase creates a private relay email
      String email = appleCredential.email ?? firebaseUser.email ?? '';

      if (email.isEmpty) {
        // Use Apple's private relay email format
        email = '${firebaseUser.uid}@privaterelay.appleid.com';
        debugPrint('⚠ No email provided, using private relay: $email');
      }

      // Build display name from Apple credential
      String displayName = '';
      if (appleCredential.givenName != null ||
          appleCredential.familyName != null) {
        displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
      }

      // Fallback to email-based name if no name provided
      if (displayName.isEmpty) {
        displayName = firebaseUser.displayName ?? email.split('@')[0];
      }

      debugPrint('Display name: $displayName');

      // Create user document in Firestore with Apple account data
      final userData = {
        'uid': firebaseUser.uid,
        'email': email,
        'displayName': displayName,
        'photoURL': firebaseUser.photoURL ?? '',
        'phoneNumber': firebaseUser.phoneNumber ?? '',
        'role': 'user',
        'status': 'active',
        'provider': 'apple',
        'appleUserId': appleCredential.userIdentifier,
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'registrationCompleted': true,
      };

      debugPrint('Creating Firestore document with data: $userData');

      // Create the document
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userData, SetOptions(merge: true));

      debugPrint('✅ Firestore document created successfully');

      // Verify the document was actually created
      final verificationDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!verificationDoc.exists) {
        throw Exception('Failed to create user document in Firestore');
      }

      final createdData = verificationDoc.data()!;
      debugPrint(
          '✅ Document verification successful. Email in DB: ${createdData['email']}');

      // Update local state
      userRole.value = 'user';

      // Create local user model with Apple account data
      final userModel = UserModel(
        uid: firebaseUser.uid,
        email: email,
        name: displayName,
        role: 'user',
        status: 'active',
        location: '',
        phoneNumber: firebaseUser.phoneNumber ?? '',
      );

      // Store user in controller
      Get.find<UserController>().currentUser = userModel;
      debugPrint('✅ User model created and stored: ${userModel.toJson()}');

      // Show success message
      Get.snackbar(
        'Welcome!',
        'Account created successfully${email.contains('privaterelay') ? '' : ' for $email'}',
        backgroundColor: Colors.green[100],
        colorText: Colors.green[800],
        duration: const Duration(seconds: 3),
      );

      // Navigate to home
      navigateToHome();
    } catch (e) {
      debugPrint('❌ Error creating new Apple user: $e');

      String errorMessage;
      if (e.toString().contains('permission-denied')) {
        errorMessage = 'Database access denied. Please contact support.';
      } else if (e.toString().contains('network')) {
        errorMessage =
            'Network error. Please check your connection and try again.';
      } else {
        errorMessage = 'Failed to create account. Please try again.';
      }

      Get.snackbar(
        'Account Creation Failed',
        errorMessage,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 5),
      );

      // Clean up authentication state
      try {
        await auth.signOut();
      } catch (signOutError) {
        debugPrint('Error during cleanup: $signOutError');
      }

      // Navigate back to login
      Get.offAllNamed('/login');
    }
  }

// Handle existing Apple user
  Future<void> _handleExistingAppleUser(User user) async {
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
        await _handleLegacyAppleUser(user);
      }
    } catch (e) {
      debugPrint('Error handling existing Apple user: $e');
      Get.snackbar('Error', 'Failed to load user data. Please try again.');
      await auth.signOut();
    }
  }

// Handle legacy Apple users (existing Firebase users without proper user documents)
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

      // Navigate based on role
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
        // User canceled, don't show error
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