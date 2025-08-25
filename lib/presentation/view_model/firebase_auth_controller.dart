// import 'dart:async';
// import 'dart:core';
// import 'dart:ffi';

// import 'package:majan/core/routes/app_route.dart';
// import 'package:majan/data/model/agent_model.dart';
// import 'package:majan/data/model/technician_model.dart';
// import 'package:majan/domain/controller/agent_controller.dart';
// import 'package:majan/domain/controller/technician_controller.dart';
// import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
// import 'package:majan/presentation/view_model/login_controller.dart';
// import 'package:email_validator/email_validator.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:get/get.dart';

// import '../../data/model/user_model.dart';
// import '../../domain/controller/user_controller.dart';

// class AuthService extends GetxController {
//   final FirebaseAuth auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final GoogleSignIn _googleSignIn = GoogleSignIn();

//   final Rxn<User> firebaseUser = Rxn<User>();
//   final RxString userRole = RxString('');
//   final RxString userTenantId = RxString('');
//   final RxString selectedGender = RxString('');
//   final RxString selectedDate = RxString('');
//   final RxBool selectedWhatsAppStatus = RxBool(false);
//   final RxString profilePictureUrl = RxString('');
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController fullNameController = TextEditingController();
//   final TextEditingController mobileNoController = TextEditingController();
//   final TextEditingController locationController = TextEditingController();
//   final TextEditingController whatsAppNumberController =
//       TextEditingController();

//   var isSignInAgent = false.obs;
//   var isSignInTenant = false.obs;
//   var isSignInTechnician = false.obs;
//   var isSignInGoogle = false.obs;
//   var isSignInPhone = false.obs;
//   var isVerifyPhone = false.obs;
//   var isRegisterAgent = false.obs;
//   var isSignOutAll = false.obs;

//   final resendEnabled = false.obs;
//   final secondsRemaining = 60.obs;
//   Timer? _resendTimer;
//   int? _resendToken;
//   String verificationId = '';

//    @override
//   void onReady() {
//     firebaseUser.bindStream(auth.authStateChanges());
//     ever(firebaseUser, handleAuthChanged);
//   }

// //  void handleAuthChanged(User? user) async {
// //   if (user == null) {
// //     Get.offAllNamed('/login');
// //   } else {
// //     // Instead of duplicating role logic, reuse existing Google user handler
// //     await _handleExistingGoogleUser(user);
// //   }
// // }
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
    
//     // Otherwise handle as regular user
//     await _handleExistingGoogleUser(user);
//   }
// }


//   // Timer methods
//   void startResendTimer() {
//     resendEnabled.value = false;
//     secondsRemaining.value = 60;
//     _resendTimer?.cancel();
//     _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
//       if (secondsRemaining.value > 0) {
//         secondsRemaining.value--;
//       } else {
//         resendEnabled.value = true;
//         timer.cancel();
//       }
//     });
//   }

//   void resetResendTimer() {
//     _resendTimer?.cancel();
//     startResendTimer();
//   }

//   @override
//   void onClose() {
//     _resendTimer?.cancel();
//     super.onClose();
//   }

//   // Phone authentication methods
//   Future<void> signInWithPhone({
//     required String phoneNumber,
//     required Function(PhoneAuthCredential) onVerificationCompleted,
//     required Function(FirebaseAuthException) onVerificationFailed,
//     required Function(String, int?) onCodeSent,
//     required Function(String) onCodeAutoRetrievalTimeout,
//     bool resend = false,
//   }) async {
//     try {
//       isSignInPhone(true);

//       if (phoneNumber.isEmpty) {
//         Get.snackbar('Error', 'Please enter a valid phone number');
//         return;
//       }

//       await auth.verifyPhoneNumber(
//         phoneNumber: phoneNumber,
//         verificationCompleted: onVerificationCompleted,
//         verificationFailed: (error) {
//           isSignInPhone(false);
//           Get.snackbar('Error', 'Verification failed: ${error.message}');
//           onVerificationFailed(error);
//         },
//         codeSent: onCodeSent,
//         codeAutoRetrievalTimeout: (verificationId) {
//           isSignInPhone(false);
//           // Get.snackbar(
//           //   'Timeout',
//           //   'SMS not received? Tap "Resend" to try again.',
//           //   duration: const Duration(seconds: 5),
//           //   mainButton: TextButton(
//           //     onPressed: () => signInWithPhone(
//           //       phoneNumber: phoneNumber,
//           //       onVerificationCompleted: onVerificationCompleted,
//           //       onVerificationFailed: onVerificationFailed,
//           //       onCodeSent: onCodeSent,
//           //       onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
//           //       resend: true, // Force resend
//           //     ),
//           //     child: const Text('Resend'),
//           //   ),
//           // );
//           onCodeAutoRetrievalTimeout(verificationId);
//         },
//         timeout: const Duration(seconds: 30),
//         forceResendingToken: resend ? _resendToken : null,
//       );
//     } catch (e) {
//       isSignInPhone(false);
//       Get.snackbar('Error', 'Failed to send SMS: ${e.toString()}');
//       rethrow;
//     }
//   }

//   Future<UserCredential?> verifyPhoneNumber({
//     required String verificationId,
//     required String smsCode,
//   }) async {
//     try {
//       isVerifyPhone(true);
//       debugPrint('Verifying phone number...');

//       final credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: smsCode,
//       );

//       final userCredential = await auth.signInWithCredential(credential);

//       if (userCredential.additionalUserInfo?.isNewUser ?? false) {
//         await _createNewPhoneUser(userCredential.user!);
//       } else {
//         await _handleExistingPhoneUser(userCredential.user!);
//       }

//       return userCredential;
//     } catch (e) {
//       debugPrint('Phone verification error: $e');
//       Get.snackbar(
//         'Error',
//         e is FirebaseAuthException
//             ? e.message ?? 'Verification failed'
//             : 'Phone verification failed',
//       );
//       return null;
//     } finally {
//       isVerifyPhone(false);
//     }
//   }

//   Future<void> resendVerificationCode(String phoneNumber) async {
//     try {
//       await signInWithPhone(
//         phoneNumber: phoneNumber,
//         onVerificationCompleted: (credential) async {
//           await verifyPhoneNumber(
//             verificationId: credential.verificationId!,
//             smsCode: credential.smsCode!,
//           );
//         },
//         onVerificationFailed: (e) {
//           Get.snackbar('Error', e.message ?? 'Verification failed');
//         },
//         onCodeSent: (verificationId, resendToken) {
//           this.verificationId = verificationId;
//           _resendToken = resendToken;
//           resetResendTimer();
//         },
//         onCodeAutoRetrievalTimeout: (verificationId) {
//           debugPrint('Code auto retrieval timed out');
//         },
//         resend: _resendToken != null,
//       );
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to resend code: ${e.toString()}');
//     }
//   }

//   // User management methods
//   Future<void> _handleExistingPhoneUser(User user) async {
//     try {
//       final userDoc = await _firestore.collection('users').doc(user.uid).get();

//       if (userDoc.exists) {
//         final userData = userDoc.data()!;
//         final userModel = UserModel(
//           uid: userData['uid'],
//           phoneNumber: user.phoneNumber,
//           name: userData['displayName'] ?? '',
//           role: userData['role'] ?? 'user',
//           status: userData['status'] ?? 'pending',
//         );

//         await _updateUserInController(userModel);
//         navigateToHome();
//       } else {
//         await _createNewPhoneUser(user);
//       }
//     } catch (e) {
//       debugPrint('Error handling existing phone user: $e');
//       rethrow;
//     }
//   }

//   Future<void> _createNewPhoneUser(User user) async {
//     try {
//       final userModel = UserModel(
//           uid: user.uid,
//           name: fullNameController.text.trim(),
//           email: '',
//           role: 'user',
//           status: 'pending',
//           phoneNumber: user.phoneNumber);
//       await _firestore.collection('users').doc(user.uid).set({
//         'uid': user.uid,
//         'email': null,
//         'displayName': fullNameController.text.trim(),
//         'photoURL': null,
//         'phoneNumber': user.phoneNumber,
//         'role': 'user',
//         'createdAt': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));

//       userRole.value = 'user';

//       await _updateUserInController(userModel);
//       navigateToHome();
//     } catch (e) {
//       debugPrint('Error creating new phone user: $e');
//       rethrow;
//     }
//   }

//   Future<void> _updateUserInController(UserModel userModel) async {
//     try {
//       final userController = Get.find<UserController>();
//       userController.currentUser = userModel;
//       debugPrint('User details stored: ${userModel.toJson()}');
//     } catch (e) {
//       debugPrint('Error updating user controller: $e');
//       rethrow;
//     }
//   }

//   Future<void> updateUserName({
//     required String userId,
//     required String newName,
//   }) async {
//     try {
//       debugPrint('Updating user name for $userId to $newName');

//       await _firestore.collection('users').doc(userId).update({
//         'displayName': newName,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });

//       await auth.currentUser?.updateDisplayName(newName);
//       await auth.currentUser?.reload();

//       final userController = Get.find<UserController>();
//       if (userController.currentUser != null) {
//         userController.currentUser = userController.currentUser!.copyWith(
//           name: newName,
//         );
//       }

//       debugPrint('User name updated successfully');
//     } catch (e) {
//       debugPrint('Error updating user name: $e');
//       throw Exception('Failed to update user name: ${e.toString()}');
//     }
//   }

//   // // Google Sign-In for Users/Tenants
//   // Future<UserCredential?> signInWithGoogle() async {
//   //   try {
//   //     isSignInGoogle(true);
//   //     debugPrint('Starting Google sign-in...');

//   //     // Trigger Google Sign-In flow
//   //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
//   //     if (googleUser == null) return null;

//   //     final GoogleSignInAuthentication googleAuth =
//   //         await googleUser.authentication;

//   //     // Create credentials
//   //     final OAuthCredential credential = GoogleAuthProvider.credential(
//   //       accessToken: googleAuth.accessToken,
//   //       idToken: googleAuth.idToken,
//   //     );

//   //     // Sign in to Firebase
//   //     final UserCredential userCredential =
//   //         await auth.signInWithCredential(credential);

//   //     // Check if this is a new user
//   //     if (userCredential.additionalUserInfo?.isNewUser ?? false) {
//   //       // New user - set default role as 'user'
//   //       await setUserRole(
//   //         'user',
//   //       );

//   //       final userDoc = await _firestore
//   //           .collection('users')
//   //           .doc(userCredential.user!.uid)
//   //           .get();

//   //       if (userDoc.exists) {
//   //         final role = userDoc.data()?['role'] ?? 'user';
//   //         userRole.value = role;

//   //         // Store user details for app-wide access
//   //         final userData = userDoc.data();
//   //         // Redirect based on role

//   //         final userModel = UserModel(
//   //           location: userData?['location'] ?? '',
//   //           phoneNumber: userData?['phoneNumber'] ?? '',
//   //           uid: userData?['uid'],
//   //           email: userData?['email'],
//   //           name: userData?['displayName'] ?? '',
//   //           role: userData?['role'] ?? 'user',
//   //           status: userData?['status'] ?? 'pending',
//   //           // Add other fields as needed
//   //         );

//   //         Get.find<UserController>().currentUser = userModel;
//   //         debugPrint('User details stored: ${userModel.toJson()}');

//   //         navigateToHome();
//   //       } else {}
//   //       // Redirect to complete profile or role selection
//   //       // Get.offAllNamed(AppRoute.completeProfile);
//   //     } else {
//   //       // Existing user - handle according to their role
//   //       await _handleExistingGoogleUser(userCredential.user!);
//   //     }

//   //     return userCredential;
//   //   } catch (e) {
//   //     Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
//   //     debugPrint('Google sign-in error: $e');
//   //     if (e is FirebaseAuthException) {
//   //       if (e.code == 'account-exists-with-different-credential') {
//   //         Get.snackbar(
//   //             'Error', 'Account already exists with different credential');
//   //       } else if (e.code == 'operation-not-allowed') {
//   //         Get.snackbar('Error', 'Operation not allowed');
//   //       } else {
//   //         Get.snackbar('Error', 'Google sign-in failed: ${e.message}');
//   //       }
//   //     } else {
//   //       Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
//   //     }
//   //     return null;
//   //   } finally {
//   //     isSignInGoogle(false);
//   //   }
//   // }

//   // Future<void> _handleExistingGoogleUser(User user) async {
//   //   // Check user's role in Firestore
//   //   final userDoc = await _firestore.collection('users').doc(user.uid).get();

//   //   if (userDoc.exists) {
//   //     final role = userDoc.data()?['role'] ?? 'user';
//   //     userRole.value = role;

//   //     // Store user details for app-wide access
//   //     final userData = userDoc.data();
//   //     // Redirect based on role

//   //     final userModel = UserModel(
//   //       location: userData?['location'] ?? '',
//   //       phoneNumber: userData?['phoneNumber'] ?? '',
//   //       uid: userData?['uid'] ?? user.uid,
//   //       email: userData?['email'] ?? user.email,
//   //       name: userData?['displayName'] ?? '',
//   //       role: userData?['role'] ?? 'user',
//   //       status: userData?['status'] ?? 'pending',
//   //       // Add other fields as needed
//   //     );

//   //     Get.find<UserController>().currentUser = userModel;
//   //     debugPrint('User details stored: ${userModel.toJson()}');

//   //     navigateToHome();
//   //   } else {
//   //     // Legacy user - create record with default role
//   //     await setUserRole(
//   //       'user',
//   //     );
//   //     navigateToHome();
//   //   }
//   // }

// // Google Sign-In for Users Only
// Future<UserCredential?> signInWithGoogle() async {
//   try {
//     debugPrint('🔐 Google Sign-In started...');
//     isSignInGoogle(true);
//     debugPrint('isSignInGoogle: ${isSignInGoogle.value}');

//     // Check if Google Play Services is available
//     bool alreadySignedIn = await _googleSignIn.isSignedIn();
//     debugPrint('GoogleSignIn already signed in: $alreadySignedIn');

//     if (!alreadySignedIn) {
//       debugPrint('Forcing Google sign-out to ensure a clean state.');
//       await _googleSignIn.signOut();
//     }

//     // Trigger Google Sign-In flow
//     debugPrint('Triggering Google sign-in popup...');
//     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

//     if (googleUser == null) {
//       debugPrint('❌ Google sign-in cancelled by user.');
//       return null; // User cancelled sign-in
//     }

//     debugPrint('Google user selected: ${googleUser.displayName}, Email: ${googleUser.email}');

//     final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//     debugPrint('Google AccessToken: ${googleAuth.accessToken}');
//     debugPrint('Google IdToken: ${googleAuth.idToken}');

//     // Validate tokens
//     if (googleAuth.accessToken == null || googleAuth.idToken == null) {
//       debugPrint('❌ Failed to retrieve valid Google authentication tokens.');
//       throw Exception('Failed to get Google authentication tokens');
//     }

//     // Create credentials
//     debugPrint('Creating Firebase credential using Google tokens...');
//     final OAuthCredential credential = GoogleAuthProvider.credential(
//       accessToken: googleAuth.accessToken,
//       idToken: googleAuth.idToken,
//     );

//     // Sign in to Firebase
//     debugPrint('Signing in with Firebase...');
//     final UserCredential userCredential = await auth.signInWithCredential(credential);

//     if (userCredential.user == null) {
//       debugPrint('❌ Firebase returned null user.');
//       throw Exception('Failed to authenticate with Firebase');
//     }

//     debugPrint('✅ Firebase sign-in successful: UID=${userCredential.user?.uid}, Email=${userCredential.user?.email}, User =${userCredential.user?.displayName}');

//     // Check if this is a new user
//     if (userCredential.additionalUserInfo?.isNewUser ?? false) {
//       debugPrint('🆕 New Google user detected. UID: ${userCredential.user?.uid}');
//       // Don’t automatically create account – show confirmation dialog
//       await _handleNewGoogleUser(userCredential.user!);
//     } else {
//       debugPrint('👤 Existing Google user detected: UID=${userCredential.user?.uid}');
//       // Existing user – proceed with login
//       await _handleExistingGoogleUser(userCredential.user!);
//     }

//     // ✅ Trigger post-login redirect logic
//     debugPrint('Triggering post-login redirect via LoginController...');
//     final loginController = Get.find<LoginController>();
//  if (loginController.postLoginRedirectArgs == null || loginController.postLoginRedirectArgs!.isEmpty) {
//     // loginController.handlePostLogin();
// } else {
//    Get.offAllNamed(AppRoute.navbar);

// }

//     debugPrint('🔐 Google Sign-In flow completed successfully.');
//     return userCredential;
//   } on PlatformException catch (e) {
//     debugPrint('⚠ Platform exception during Google sign-in: ${e.code} - ${e.message}');
//     _handlePlatformException(e);
//     return null;
//   } on FirebaseAuthException catch (e) {
//     debugPrint('⚠ FirebaseAuth exception: ${e.code} - ${e.message}');
//     _handleFirebaseAuthException(e);
//     return null;
//   } catch (e) {
//     debugPrint('❌ Unexpected error during Google sign-in: $e');
//     // Get.snackbar(
//     //   'Error',
//     //   'Sign-in failed. Please try again.',
//     //   backgroundColor: Colors.red[100],
//     //   colorText: Colors.red[800],
//     // );
//     return null;
//   } finally {
//     isSignInGoogle(false);
//     debugPrint('isSignInGoogle reset to: ${isSignInGoogle.value}');
//   }
// }

// // Handle new Google user - ask for confirmation
//   Future<void> _handleNewGoogleUser(User user) async {
//     try {
//       // Check if user document already exists (edge case)
//       final userDoc = await _firestore.collection('users').doc(user.uid).get();

//       if (userDoc.exists) {
//         // Document exists, treat as existing user
//         await _handleExistingGoogleUser(user);
//         return;
//       }

//       // Show confirmation dialog for new user registration
//       bool? shouldCreateAccount =
//           await _showRegistrationConfirmationDialog(user);

//       if (shouldCreateAccount == true) {
//         // User confirmed - create account
//         await _createUserAccount(user);
//       } else {
//         // User declined - sign out
//         await auth.signOut();
//         await _googleSignIn.signOut();
//         Get.snackbar(
//           'Registration Cancelled',
//           'You can sign in again anytime to create an account.',
//           backgroundColor: Colors.blue[100],
//           colorText: Colors.blue[800],
//         );
//       }
//     } catch (e) {
//       debugPrint('Error handling new Google user: $e');
//       await auth.signOut();
//       await _googleSignIn.signOut();
//       Get.snackbar('Error', 'Registration process failed. Please try again.');
//     }
//   }

// // Show confirmation dialog for new user registration
//   Future<bool?> _showRegistrationConfirmationDialog(User user) async {
//     return await Get.dialog<bool>(
//       AlertDialog(
//         title: const Text('Create Account'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             CircleAvatar(
//               radius: 30,
//               backgroundImage:
//                   user.photoURL != null ? NetworkImage(user.photoURL!) : null,
//               child: user.photoURL == null
//                   ? const Icon(Icons.person, size: 30)
//                   : null,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'Welcome, ${user.displayName ?? user.email ?? 'User'}!',
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               user.email ?? 'No email provided',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey[600],
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 16),
//             const Text(
//               'Would you like to create a user account with this Google account?',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(result: false),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () => Get.back(result: true),
//             child: const Text('Create Account'),
//           ),
//         ],
//       ),
//       barrierDismissible: false,
//     );
//   }

// // Create user account after confirmation
//   Future<void> _createUserAccount(User user) async {
//     try {
//       // Create user document
//       final userData = {
//         'uid': user.uid,
//         'email': user.email ?? '',
//         'displayName': user.displayName ?? '',
//         'role': 'user', // Fixed as user
//         'status': 'active', // Users are active by default
//         'profilePicture': user.photoURL,
//         'provider': 'google',
//         'location': '',
//         'phoneNumber': '',
//         'createdAt': FieldValue.serverTimestamp(),
//         'registrationCompleted': true,
//       };

//       await _firestore.collection('users').doc(user.uid).set(userData);

//       // Update local state
//       userRole.value = 'user';

//       // Create user model
//       final userModel = UserModel(
//         location: '',
//         phoneNumber: '',
//         uid: user.uid,
//         email: user.email ?? '',
//         name: user.displayName ?? '',
//         role: 'user',
//         status: 'active',
//         // profilePicture: user.photoURL,
//       );

//       // Store user in controller
//       Get.find<UserController>().currentUser = userModel;
//       debugPrint('New user account created: ${userModel.toJson()}');

//       // Show success message
//       Get.snackbar(
//         'Account Created',
//         'Welcome! Your account has been created successfully.',
//         backgroundColor: Colors.green[100],
//         colorText: Colors.green[800],
//       );

//       navigateToHome();

//       // Navigate to home or complete profile if needed
//       // if (user.displayName?.isEmpty ?? true) {
//       //   Get.offAllNamed(AppRoute.completeProfile);
//       // } else {
//       //   navigateToHome();
//       // }
//     } catch (e) {
//       debugPrint('Error creating user account: $e');
//       Get.snackbar('Error', 'Failed to create account. Please try again.');
//       await auth.signOut();
//       await _googleSignIn.signOut();
//     }
//   }

// // Handle existing Google user
//   Future<void> _handleExistingGoogleUser(User user) async {
//     try {
//       // Check user's data in Firestore
//       final userDoc = await _firestore.collection('users').doc(user.uid).get();
//       debugPrint('Checking existing user document for UID: ${user.uid}');

//       if (userDoc.exists) {
//         final userData = userDoc.data()!;
//         final status = userData['status'] ?? 'active';
       
//         userRole.value = userData['role'] ?? '';

//         debugPrint('User role fetched: ${userRole.value}');

//         // Check if account is active
//         if (status == 'suspended' || status == 'banned') {
//           await auth.signOut();
//           await _googleSignIn.signOut();
//           Get.snackbar(
//             'Account Suspended',
//             'Your account has been suspended. Please contact support.',
//             backgroundColor: Colors.orange[100],
//             colorText: Colors.orange[800],
//           );
//           return;
//         }

//         // Create user model
//         final userModel = UserModel(
//           location: userData['location'] ?? '',
//           phoneNumber: userData['phoneNumber'] ?? '',
//           uid: user.uid,
//           email: user.email ?? userData['email'] ?? '',
//           name: userData['displayName'] ?? user.displayName ?? '',
//          role: userData['role'] ?? '',
//           status: status,

//           // profilePicture: userData['profilePicture'] ?? user.photoURL,
//         );

//         debugPrint('''
// UID: ${userModel.uid}
// Email: ${userModel.email}
// Phone: ${userModel.phoneNumber}
// Location: ${userModel.location}
// Name: ${userModel.name}
// Role: ${userModel.role}
// Status: ${userModel.status}
// Image URL: ${userModel.imageUrl}
// ''');



//         // Store user in controller
//         Get.find<UserController>().currentUser = userModel;
//         debugPrint('Existing user logged in: ${userModel.toJson()}');
//         // Store user in controller
// Get.find<UserController>().currentUser = userModel;
// debugPrint('Existing user logged in: ${userModel.toJson()}');

// // Navigate based on role
// if (userModel.role == 'tenant') {
//   debugPrint('Navigating to Tenant Dashboard...');
//   Get.offAllNamed(AppRoute.navbar);
// } else if (userModel.role == 'agent') {
//   debugPrint('Navigating to Agent Dashboard...');
//   Get.offAllNamed(AppRoute.navbar);
// } else if (userModel.role == 'technician') {
//   debugPrint('Navigating to Technician Dashboard...');
//   Get.offAllNamed(AppRoute.technicianDashboard);
// } else {
//   debugPrint('Navigating to User Home...');
//   navigateToHome();
// }

//       } else {
//         debugPrint('User document not found for existing user');
//         // This shouldn't happen, but handle gracefully
//         await _handleLegacyGoogleUser(user);
//       }
//     } catch (e) {
//       debugPrint('Error handling existing Google user: $e');
//       Get.snackbar('Error', 'Failed to load user data. Please try again.');
//       await auth.signOut();
//       await _googleSignIn.signOut();
//     }
//   }

// // Handle legacy users (existing Firebase users without proper user documents)
//   Future<void> _handleLegacyGoogleUser(User user, {String role = 'user'}) async {
//   try {
//     final userData = {
//       'uid': user.uid,
//       'email': user.email ?? '',
//       'displayName': user.displayName ?? '',
//       'role': role,  // dynamically set role
//       'status': 'active',
//       'profilePicture': user.photoURL,
//       'provider': 'google',
//       'location': '',
//       'phoneNumber': '',
//       'createdAt': FieldValue.serverTimestamp(),
//       'isLegacyUser': true,
//       'registrationCompleted': true,
//     };

//     await _firestore.collection('users').doc(user.uid).set(userData);
//     userRole.value = role;

//     final userModel = UserModel(
//       location: '',
//       phoneNumber: '',
//       uid: user.uid,
//       email: user.email ?? '',
//       name: user.displayName ?? '',
//       role: role,
//       status: 'active',
//     );

//     Get.find<UserController>().currentUser = userModel;

//     Get.snackbar(
//       'Welcome Back',
//       'Your account has been updated successfully.',
//       backgroundColor: Colors.green[100],
//       colorText: Colors.green[800],
//     );

//     // Navigate based on role
//     if (role == 'tenant') {
//       Get.offAllNamed(AppRoute.navbar);
//     } else if (role == 'agent') {
//       Get.offAllNamed(AppRoute.navbar);
//     } else {
//       navigateToHome();
//     }
//   } catch (e) {
//     debugPrint('Error handling legacy Google user: $e');
//     Get.snackbar('Error', 'Account setup failed. Please try again.');
//     await auth.signOut();
//     await _googleSignIn.signOut();
//   }
// }


// // Handle platform-specific exceptions
//   void _handlePlatformException(PlatformException e) {
//     String message;

//     switch (e.code) {
//       case 'sign_in_failed':
//         message = 'Google sign-in failed. Please try again.';
//         break;
//       case 'network_error':
//         message = 'Network error. Please check your internet connection.';
//         break;
//       case 'sign_in_canceled':
//         return; // Don't show error for user cancellation
//       default:
//         message = 'Sign-in failed. Please try again.';
//     }

//     Get.snackbar(
//       'Sign-in Error',
//       message,
//       backgroundColor: Colors.red[100],
//       colorText: Colors.red[800],
//     );
//   }

// // Handle Firebase Auth exceptions
//   void _handleFirebaseAuthException(FirebaseAuthException e) {
//     String message;

//     switch (e.code) {
//       case 'account-exists-with-different-credential':
//         message =
//             'An account already exists with this email using a different sign-in method.';
//         break;
//       case 'operation-not-allowed':
//         message = 'Google sign-in is not enabled. Please contact support.';
//         break;
//       case 'user-disabled':
//         message = 'This account has been disabled. Please contact support.';
//         break;
//       case 'invalid-credential':
//         message = 'Invalid credentials. Please try again.';
//         break;
//       case 'too-many-requests':
//         message = 'Too many failed attempts. Please try again later.';
//         break;
//       default:
//         message = 'Sign-in failed. Please try again.';
//     }

//     Get.snackbar(
//       'Sign-in Error',
//       message,
//       backgroundColor: Colors.red[100],
//       colorText: Colors.red[800],
//     );
//   }

// // Agent Registration with Email/Password
//   Future<void> registerAgent() async {
//     try {
//       isRegisterAgent(true);
//       // Validate form fields
//       if (emailController.text.isEmpty ||
//           passwordController.text.isEmpty ||
//           fullNameController.text.isEmpty ||
//           mobileNoController.text.isEmpty) {
//         Get.snackbar('Error', 'Please fill all fields');
//         return;
//       }

//       if (passwordController.text.length < 6) {
//         Get.snackbar('Error', 'Password must be at least 6 characters');
//         return;
//       }

//       // Create user in Firebase Auth
//       final credential = await auth.createUserWithEmailAndPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );

//       // Send email verification
//       // await credential.user?.sendEmailVerification();

//       // Create agent profile in Firestore
//       if (credential.user == null) {
//         Get.snackbar('Error', 'User creation failed');
//         return;
//       } else {
//         await setAgentRole(
//           fullNameController.text,
//           mobileNoController.text,
//           selectedGender.value,
//           profilePictureUrl.value.isNotEmpty ? profilePictureUrl.value : null,
//           selectedDate.value.isNotEmpty ? selectedDate.value : null,
//           selectedWhatsAppStatus.value,
//           selectedWhatsAppStatus.value
//               ? mobileNoController.text
//               : whatsAppNumberController.text.isNotEmpty
//                   ? whatsAppNumberController.text
//                   : null,
//           locationController.text.isNotEmpty ? locationController.text : null,
//         );
//       }
//       Get.snackbar('Success', 'Agent registration submitted for approval');
//       Get.offAllNamed(AppRoute.approvalPendingPage);
//       clearControllers(); // Clear input fields after registration
//     } on FirebaseAuthException catch (e) {
//       String errorMessage = 'Registration failed';
//       if (e.code == 'email-already-in-use') {
//         errorMessage = 'Email already registered';
//       } else if (e.code == 'invalid-email') {
//         errorMessage = 'Invalid email address';
//       } else if (e.code == 'weak-password') {
//         errorMessage = 'Password is too weak';
//       }
//       Get.snackbar('Error', errorMessage);
//     } catch (e) {
//       Get.snackbar('Error', 'Registration failed: ${e.toString()}');
//       debugPrint('Agent registration error: $e');
//     } finally {
//       isRegisterAgent(false);
//     }
//   }

//   // Email/Password Sign-In for Agents
//   Future<UserCredential?> signInAsAgent() async {
//     try {
//       isSignInAgent(true);
//       debugPrint('Attempting agent sign in...');
//       final String email = emailController.text.trim();
//       final String password = passwordController.text.trim();

//       debugPrint('Email: $email');
//       debugPrint(
//           'Password: ${'*' * password.length}'); // Don't print actual password

//       final credential = await auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       debugPrint('Firebase authentication successful, verifying agent role...');
//       debugPrint('User UID: ${credential.user?.uid}');

//       // Verify this is actually an agent
//       final userDoc =
//           await _firestore.collection('agents').doc(credential.user?.uid).get();

//       if (userDoc.exists &&
//           userDoc.data()?['role'] == 'agent' &&
//           userDoc.data()?['status'] == 'approved') {
//         debugPrint('Agent verification successful');
//         userRole.value = 'agent';
//         // Store user details for app-wide access
//         final userData = userDoc.data();
//         final userModel = AgentModel(
//           dob: userData?['dob'] ?? '',
//           gender: userData?['gender'] ?? '',
//           location: userData?['location'] ?? '',
//           uid: credential.user!.uid,
//           email: credential.user!.email!,
//           name: userData?['displayName'] ?? '',
//           role: userData?['role'] ?? 'agent',
//           status: userData?['status'] ?? 'pending',
//           // Add other fields as needed
//         );

//         // Assuming you have a user service or controller to store this
//         Get.find<AgentController>().currentUser = userModel;
//         debugPrint('User details stored: ${userModel.toJson()}');

//         // Navigate to home
//         navigateToHome();
//         debugPrint('Navigation to agent home completed');

//         return credential;
//       } else {
//         debugPrint('Account is not registered as an agent');
//         await auth.signOut();
//         Get.snackbar('Error',
//             '"Sorry! Your account isn’t registered as an agent yet or still needs approval. Please contact support if you think this is a mistake."');
//         return null;
//       }
//     } on FirebaseAuthException catch (e) {
//       debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
//       Get.snackbar('Error', 'Agent login failed: ${e.message}');
//       return null;
//     } catch (e) {
//       debugPrint('Unexpected Error: $e');
//       Get.snackbar('Error', 'An unexpected error occurred');
//       return null;
//     } finally {
//       isSignInAgent(false);
//       debugPrint('Sign in process completed');
//     }
//   }

//   Future<UserCredential?> signInAsTechnician() async {
//   try {
//     isSignInTechnician(true); // ✅ Correct loading state for technician
//     debugPrint('Attempting technician sign in...');
//     final String email = emailController.text.trim();
//     final String password = passwordController.text.trim();

//     final credential = await auth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );

//     debugPrint('Firebase authentication successful, verifying Technician role...');
//     final userDoc = await _firestore.collection('technicians').doc(credential.user?.uid).get();

//    if (userDoc.exists && userDoc.data()?['role'] == 'technician') {
//   debugPrint('Technician verification successful');
//   userRole.value = 'technician';

//   final userData = userDoc.data() as Map<String, dynamic>?;

//   final userModel = TechnicianProfile(
//     uid: userData?['uid'] ?? '',
//     location: userData?['location'] ?? '',
//     fullName: userData?['fullName'] ?? '',
//     email: userData?['email'] ?? credential.user?.email ?? '',
//     mobile: userData?['mobile'] ?? userData?['phoneNumber'] ?? '',
//     photoURL: userData?['photoURL'] ?? '',
//     role: userData?['role'] ?? 'technician',
//   );

//   // Store user details in TechnicianController
//   Get.find<TechnicianController>().currentUser = userModel;
//   debugPrint('Technician details stored: ${userModel.toJson()}');



//       // ✅ Navigate to Technician Dashboard
//       Get.offAllNamed(AppRoute.technicianDashboard);

//       return credential;
//     } else {
//       debugPrint('Account is not registered as a technician');
//       await auth.signOut();
//       Get.snackbar('Error', 'This account is not registered as a technician');
//       return null;
//     }
//   } on FirebaseAuthException catch (e) {
//     debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
//     Get.snackbar('Error', 'Technician login failed: ${e.message}');
//     return null;
//   } catch (e) {
//     debugPrint('Unexpected Error: $e');
//     Get.snackbar('Error', 'An unexpected error occurred');
//     return null;
//   } finally {
//     isSignInTechnician(false);
//     debugPrint('Sign in process completed');
//   }
// }
// Future<void> _handleTechnicianUser(User user) async {
//   try {
//     final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
//     // if (!technicianDoc.exists) {
//     //   await auth.signOut();
//     //   Get.offAllNamed(AppRoute.login);
//     //   return;
//     // }

//     final userData = technicianDoc.data()!;
//     final userModel = TechnicianProfile(
//       uid: user.uid,
//       location: userData['location'] ?? '',
//       fullName: userData['fullName'] ?? '',
//       email: userData['email'] ?? user.email ?? '',
//       mobile: userData['mobile'] ?? userData['phoneNumber'] ?? '',
//       photoURL: userData['photoURL'] ?? '',
//       role: 'technician',
//     );

//     Get.find<TechnicianController>().currentUser = userModel;
//   } catch (e) {
//     debugPrint('Error handling technician user: $e');
//     await auth.signOut();
//     Get.offAllNamed(AppRoute.login);
//   }
// }

//   // Future<UserCredential?> signInAsTechnician() async {
//   // try {
//   //   isSignInTechnician(true);
//   //   debugPrint('Attempting technician sign in...');
//   //   final String email = emailController.text.trim().toLowerCase();
//   //   final String password = passwordController.text.trim();

//     // First, verify the email exists in Firebase Auth
//     // debugPrint('Checking if email exists in Firebase Auth...');
//     // try {
//     //   final methods = await auth.fetchSignInMethodsForEmail(email);
//     //   if (methods.isEmpty) {
//     //     Get.snackbar('Error', 'No account found with this email');
//     //     return null;
//     //   }
//     //   debugPrint('Email exists in Firebase Auth');
//     // } catch (e) {
//     //   debugPrint('Error checking user existence: $e');
//     //   Get.snackbar('Error', 'Error verifying account');
//     //   return null;
//     // }

//     // Proceed with sign in
// //     debugPrint('Attempting Firebase authentication...');
// //     final credential = await auth.signInWithEmailAndPassword(
// //       email: email,
// //       password: password,
// //     );

// //     if (credential.user == null) {
// //       throw FirebaseAuthException(
// //         code: 'auth-failed',
// //         message: 'Authentication failed unexpectedly',
// //       );
// //     }

// //     debugPrint('Firebase authentication successful, verifying Technician role...');
// //     final userDoc = await _firestore.collection('technicians').doc(credential.user?.uid).get();

// //     if (userDoc.exists && userDoc.data()?['role'] == 'technician') {
// //       debugPrint('Technician verification successful');
// //       userRole.value = 'technician';

// //       final userData = userDoc.data() as Map<String, dynamic>?;

// //       final userModel = TechnicianProfile(
// //         uid: userData?['uid'] ?? '',
// //         location: userData?['location'] ?? '',
// //         fullName: userData?['fullName'] ?? '',
// //         email: userData?['email'] ?? credential.user?.email ?? '',
// //         mobile: userData?['mobile'] ?? userData?['phoneNumber'] ?? '',
// //         photoURL: userData?['photoURL'] ?? '',
// //         role: userData?['role'] ?? 'technician',
// //       );

// //       // Store user details in TechnicianController
// //       Get.find<TechnicianController>().currentUser = userModel;
// //       debugPrint('Technician details stored: ${userModel.toJson()}');

// //       // Navigate to Technician Dashboard
// //       Get.offAllNamed(AppRoute.technicianDashboard);
// //       return credential;
// //     } else {
// //       debugPrint('Account is not registered as a technician');
// //       await auth.signOut();
// //       Get.snackbar('Error', 'This account is not registered as a technician');
// //       return null;
// //     }
// //   } on FirebaseAuthException catch (e) {
// //     debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
    
// //     String errorMessage = 'Technician login failed';
// //     if (e.code == 'wrong-password') {
// //       errorMessage = 'Incorrect password';
// //     } else if (e.code == 'user-not-found') {
// //       errorMessage = 'Account not found';
// //     } else if (e.code == 'user-disabled') {
// //       errorMessage = 'Account disabled';
// //     }
    
// //     Get.snackbar('Error', errorMessage);
// //     return null;
// //   } catch (e) {
// //     debugPrint('Unexpected Error: $e');
// //     Get.snackbar('Error', 'An unexpected error occurred');
// //     return null;
// //   } finally {
// //     isSignInTechnician(false);
// //     debugPrint('Sign in process completed');
// //   }
// // }
// // void _handleAuthError(FirebaseAuthException e) {
// //   debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
  
// //   final message = switch (e.code) {
// //     'invalid-credential' => 'Invalid email or password',
// //     'user-disabled' => 'This account has been disabled',
// //     'user-not-found' => 'No account found with this email',
// //     'wrong-password' => 'Incorrect password',
// //     _ => 'Technician login failed: ${e.message}',
// //   };
  
// //   Get.snackbar('Error', message);
// // }

//   Future<void> setUserRole(String role, {String? tenantId}) async {
//     final user = auth.currentUser;
//     if (user == null) return;

//     await _firestore.collection('users').doc(user.uid).set({
//       'uid': user.uid,
//       'email': user.email,
//       'displayName': user.displayName,
//       'photoURL': user.photoURL,
//       'phoneNumber': user.phoneNumber,
//       'role': '',
//       'createdAt': FieldValue.serverTimestamp(),
//     }, SetOptions(merge: true));

//     userRole.value = role ?? '';
//     userTenantId.value = tenantId ?? '';
//   }

//   // Updated AuthService with proper agent role setting
//   Future<void> setAgentRole(
//     String fullName,
//     String mobileNo,
//     String gender,
//     String? profilePicUrl,
//     String? dob,
//     bool? isWhatsAppAvalable,
//     String? whatsAppNumber,
//     String? location,
//   ) async {
//     final user = auth.currentUser;
//     if (user == null) {
//       Get.snackbar('Error', 'No user logged in');
//       return;
//     }

//     // First check if this is an allowed agent email (optional security check)
//     // if (!_isValidAgentEmail(user.email)) {
//     //   Get.snackbar('Error', 'This email is not authorized for agent access');
//     //   await _auth.signOut();
//     //   return;
//     // }

//     try {
//       // Create/update document in both collections for easy querying
//       final batch = _firestore.batch();

//       // // Main users collection
//       // final userRef = _firestore.collection('agents').doc(user.uid);
//       // batch.set(
//       //     userRef,
//       //     {
//       //       'uid': user.uid,
//       //       'email': user.email,
//       //       'displayName': user.displayName ?? 'Agent',
//       //       'photoURL': user.photoURL,
//       //       'role': 'agent',
//       //       'isApproved': false, // Admin needs to approve
//       //       'createdAt': FieldValue.serverTimestamp(),
//       //       'lastLogin': FieldValue.serverTimestamp(),
//       //     },
//       //     SetOptions(merge: true));

//       // Agents-specific collection
//       final agentRef = _firestore.collection('agents').doc(user.uid);
//       batch.set(
//           agentRef,
//           {
//             'uid': user.uid,
//             'email': user.email,
//             'displayName': fullName,
//             'mobile': mobileNo,
//             'profilePic': "",
//             'gender': gender,
//             'dob': dob,
//             'location': location,
//             'whatsAppNumber': whatsAppNumber,
//             'role': 'agent',
//             'status': 'pending', // pending/approved/rejected
//             'createdAt': FieldValue.serverTimestamp(),
//           },
//           SetOptions(merge: true));

//       await batch.commit();

//       userRole.value = 'agent';
//       Get.offAllNamed('/agent-pending'); // Redirect to pending approval screen
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to set agent role: ${e.toString()}');
//       debugPrint('Error setting agent role: $e');
//     }
//   }

//   // bool _isValidAgentEmail(String? email) {
//   //   // Add your domain validation logic here
//   //   const allowedDomains = ['@yourcompany.com', '@agent.yourcompany.com'];
//   //   return email != null && allowedDomains.any(email.endsWith);
//   // }
//   void navigateGuestToHome() async {
//     await _googleSignIn.signOut();
//     await auth.signOut();
//     userRole.value = "guest";
//     Get.toNamed(AppRoute.navbar);
//   }

//   void navigateToHome() {
//     Get.offAllNamed(AppRoute.navbar);
//   }

//   void navigateToLogin() {
//     Get.offAllNamed(AppRoute.login);
//   }

//   Future<void> signOut() async {
//     isSignOutAll(true);
//     await _googleSignIn.signOut();
//     await auth.signOut();
//     navigateToLogin();
//     isSignOutAll(false);
//   }

//   @override
//   void dispose() {
//     // Dispose all controllers when the widget is disposed
//     emailController.dispose();
//     passwordController.dispose();
//     fullNameController.dispose();
//     mobileNoController.dispose();
//     super.dispose();
//   }

//   void clearControllers() {
//     // Clear all text fields
//     emailController.clear();
//     passwordController.clear();
//     fullNameController.clear();
//     mobileNoController.clear();
//   }
// }


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

import '../../data/model/user_model.dart';
import '../../domain/controller/user_controller.dart';

class AuthService extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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

//  void handleAuthChanged(User? user) async {
//   if (user == null) {
//     Get.offAllNamed('/login');
//   } else {
//     // Instead of duplicating role logic, reuse existing Google user handler
//     await _handleExistingGoogleUser(user);
//   }
// }
void handleAuthChanged(User? user) async {
  if (user == null) {
    Get.offAllNamed('/login');
  } else {
    // Check if user is a technician first
    final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
    if (technicianDoc.exists && technicianDoc.data()?['role'] == 'technician') {
      await _handleTechnicianUser(user);
      Get.offAllNamed(AppRoute.technicianDashboard);
      return;
    }
    
    // Otherwise handle as regular user
    await _handleExistingGoogleUser(user);
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

  // // Google Sign-In for Users/Tenants
  // Future<UserCredential?> signInWithGoogle() async {
  //   try {
  //     isSignInGoogle(true);
  //     debugPrint('Starting Google sign-in...');

  //     // Trigger Google Sign-In flow
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) return null;

  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;

  //     // Create credentials
  //     final OAuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );

  //     // Sign in to Firebase
  //     final UserCredential userCredential =
  //         await auth.signInWithCredential(credential);

  //     // Check if this is a new user
  //     if (userCredential.additionalUserInfo?.isNewUser ?? false) {
  //       // New user - set default role as 'user'
  //       await setUserRole(
  //         'user',
  //       );

  //       final userDoc = await _firestore
  //           .collection('users')
  //           .doc(userCredential.user!.uid)
  //           .get();

  //       if (userDoc.exists) {
  //         final role = userDoc.data()?['role'] ?? 'user';
  //         userRole.value = role;

  //         // Store user details for app-wide access
  //         final userData = userDoc.data();
  //         // Redirect based on role

  //         final userModel = UserModel(
  //           location: userData?['location'] ?? '',
  //           phoneNumber: userData?['phoneNumber'] ?? '',
  //           uid: userData?['uid'],
  //           email: userData?['email'],
  //           name: userData?['displayName'] ?? '',
  //           role: userData?['role'] ?? 'user',
  //           status: userData?['status'] ?? 'pending',
  //           // Add other fields as needed
  //         );

  //         Get.find<UserController>().currentUser = userModel;
  //         debugPrint('User details stored: ${userModel.toJson()}');

  //         navigateToHome();
  //       } else {}
  //       // Redirect to complete profile or role selection
  //       // Get.offAllNamed(AppRoute.completeProfile);
  //     } else {
  //       // Existing user - handle according to their role
  //       await _handleExistingGoogleUser(userCredential.user!);
  //     }

  //     return userCredential;
  //   } catch (e) {
  //     Get.snackbar('Error', 'Google sign-in failed: ${e.toString()}');
  //     debugPrint('Google sign-in error: $e');
  //     if (e is FirebaseAuthException) {
  //       if (e.code == 'account-exists-with-different-credential') {
  //         Get.snackbar(
  //             'Error', 'Account already exists with different credential');
  //       } else if (e.code == 'operation-not-allowed') {
  //         Get.snackbar('Error', 'Operation not allowed');
  //       } else {
  //         Get.snackbar('Error', 'Google sign-in failed: ${e.message}');
  //       }
  //     } else {
  //       Get.snackbar('Error', 'An unexpected error occurred: ${e.toString()}');
  //     }
  //     return null;
  //   } finally {
  //     isSignInGoogle(false);
  //   }
  // }

  // Future<void> _handleExistingGoogleUser(User user) async {
  //   // Check user's role in Firestore
  //   final userDoc = await _firestore.collection('users').doc(user.uid).get();

  //   if (userDoc.exists) {
  //     final role = userDoc.data()?['role'] ?? 'user';
  //     userRole.value = role;

  //     // Store user details for app-wide access
  //     final userData = userDoc.data();
  //     // Redirect based on role

  //     final userModel = UserModel(
  //       location: userData?['location'] ?? '',
  //       phoneNumber: userData?['phoneNumber'] ?? '',
  //       uid: userData?['uid'] ?? user.uid,
  //       email: userData?['email'] ?? user.email,
  //       name: userData?['displayName'] ?? '',
  //       role: userData?['role'] ?? 'user',
  //       status: userData?['status'] ?? 'pending',
  //       // Add other fields as needed
  //     );

  //     Get.find<UserController>().currentUser = userModel;
  //     debugPrint('User details stored: ${userModel.toJson()}');

  //     navigateToHome();
  //   } else {
  //     // Legacy user - create record with default role
  //     await setUserRole(
  //       'user',
  //     );
  //     navigateToHome();
  //   }
  // }

// Google Sign-In for Users Only
Future<UserCredential?> signInWithGoogle() async {
  try {
    debugPrint('🔐 Google Sign-In started...');
    isSignInGoogle(true);

    // Clean previous sessions
    await _googleSignIn.signOut();

    // Trigger Google Sign-In
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      debugPrint('❌ Google sign-in cancelled by user.');
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // Create Firebase credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final UserCredential userCredential = await auth.signInWithCredential(credential);

    if (userCredential.additionalUserInfo?.isNewUser ?? false) {
      await _handleNewGoogleUser(userCredential.user!);
    } else {
      await _handleExistingGoogleUser(userCredential.user!);
    }

    return userCredential;
  } catch (e) {
    debugPrint('❌ Google sign-in error: $e');
    Get.snackbar('Error', 'Google sign-in failed');
    return null;
  } finally {
    isSignInGoogle(false);
  }
}

// Handle new Google user - ask for confirmation
Future<void> _handleNewGoogleUser(User user) async {
  try {
    // Create user document in Firestore ONLY
    final userData = {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'photoURL': user.photoURL,
      'role': 'user',
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(user.uid).set(userData);

    // Create local user model
    final userModel = UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
      role: 'user',
      status: 'active',
      // other fields...
    );

    Get.find<UserController>().currentUser = userModel;
    navigateToHome();

  } catch (e) {
    debugPrint('Error creating new user: $e');
    await auth.signOut();
    await _googleSignIn.signOut();
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

      // Navigate to home or complete profile if needed
      // if (user.displayName?.isEmpty ?? true) {
      //   Get.offAllNamed(AppRoute.completeProfile);
      // } else {
      //   navigateToHome();
      // }
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
  Future<void> _handleLegacyGoogleUser(User user, {String role = 'user'}) async {
  try {
    final userData = {
      'uid': user.uid,
      'email': user.email ?? '',
      'displayName': user.displayName ?? '',
      'role': role,  // dynamically set role
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

    debugPrint('Firebase authentication successful, verifying Technician role...');
    final userDoc = await _firestore.collection('technicians').doc(credential.user?.uid).get();

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
    final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
    // if (!technicianDoc.exists) {
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

  // Future<UserCredential?> signInAsTechnician() async {
  // try {
  //   isSignInTechnician(true);
  //   debugPrint('Attempting technician sign in...');
  //   final String email = emailController.text.trim().toLowerCase();
  //   final String password = passwordController.text.trim();

    // First, verify the email exists in Firebase Auth
    // debugPrint('Checking if email exists in Firebase Auth...');
    // try {
    //   final methods = await auth.fetchSignInMethodsForEmail(email);
    //   if (methods.isEmpty) {
    //     Get.snackbar('Error', 'No account found with this email');
    //     return null;
    //   }
    //   debugPrint('Email exists in Firebase Auth');
    // } catch (e) {
    //   debugPrint('Error checking user existence: $e');
    //   Get.snackbar('Error', 'Error verifying account');
    //   return null;
    // }

    // Proceed with sign in
//     debugPrint('Attempting Firebase authentication...');
//     final credential = await auth.signInWithEmailAndPassword(
//       email: email,
//       password: password,
//     );

//     if (credential.user == null) {
//       throw FirebaseAuthException(
//         code: 'auth-failed',
//         message: 'Authentication failed unexpectedly',
//       );
//     }

//     debugPrint('Firebase authentication successful, verifying Technician role...');
//     final userDoc = await _firestore.collection('technicians').doc(credential.user?.uid).get();

//     if (userDoc.exists && userDoc.data()?['role'] == 'technician') {
//       debugPrint('Technician verification successful');
//       userRole.value = 'technician';

//       final userData = userDoc.data() as Map<String, dynamic>?;

//       final userModel = TechnicianProfile(
//         uid: userData?['uid'] ?? '',
//         location: userData?['location'] ?? '',
//         fullName: userData?['fullName'] ?? '',
//         email: userData?['email'] ?? credential.user?.email ?? '',
//         mobile: userData?['mobile'] ?? userData?['phoneNumber'] ?? '',
//         photoURL: userData?['photoURL'] ?? '',
//         role: userData?['role'] ?? 'technician',
//       );

//       // Store user details in TechnicianController
//       Get.find<TechnicianController>().currentUser = userModel;
//       debugPrint('Technician details stored: ${userModel.toJson()}');

//       // Navigate to Technician Dashboard
//       Get.offAllNamed(AppRoute.technicianDashboard);
//       return credential;
//     } else {
//       debugPrint('Account is not registered as a technician');
//       await auth.signOut();
//       Get.snackbar('Error', 'This account is not registered as a technician');
//       return null;
//     }
//   } on FirebaseAuthException catch (e) {
//     debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
    
//     String errorMessage = 'Technician login failed';
//     if (e.code == 'wrong-password') {
//       errorMessage = 'Incorrect password';
//     } else if (e.code == 'user-not-found') {
//       errorMessage = 'Account not found';
//     } else if (e.code == 'user-disabled') {
//       errorMessage = 'Account disabled';
//     }
    
//     Get.snackbar('Error', errorMessage);
//     return null;
//   } catch (e) {
//     debugPrint('Unexpected Error: $e');
//     Get.snackbar('Error', 'An unexpected error occurred');
//     return null;
//   } finally {
//     isSignInTechnician(false);
//     debugPrint('Sign in process completed');
//   }
// }
// void _handleAuthError(FirebaseAuthException e) {
//   debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
  
//   final message = switch (e.code) {
//     'invalid-credential' => 'Invalid email or password',
//     'user-disabled' => 'This account has been disabled',
//     'user-not-found' => 'No account found with this email',
//     'wrong-password' => 'Incorrect password',
//     _ => 'Technician login failed: ${e.message}',
//   };
  
//   Get.snackbar('Error', message);
// }

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
