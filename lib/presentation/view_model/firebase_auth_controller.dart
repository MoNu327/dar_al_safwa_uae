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
  
  // 🔧 Auto-login management
  final RxBool isAutoLoggingIn = RxBool(false);
  final RxBool hasCheckedAutoLogin = RxBool(false);
  
  // 🔧 Prevent duplicate auth handling
  Timer? _authStateDebouncer;
  bool _isInitializing = true;

  final resendEnabled = false.obs;
  final secondsRemaining = 60.obs;
  Timer? _resendTimer;
  int? _resendToken;
  String verificationId = '';
  
  // ⚡ Cache for user data to avoid repeated Firestore reads
  final Map<String, Map<String, dynamic>> _userDataCache = {};
  
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

  Map<String, dynamic> _getDeviceInfo() {
    return {
      'mode': _getPlatformInfo(),
      'modeupdated': _getPlatformInfo(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
  }

  // ⚡ Background login activity logging (non-blocking)
  void _logLoginActivityAsync(String uid) {
    Future.microtask(() async {
      try {
        debugPrint('📊 [Background] Logging login activity for: $uid');

        String collection = 'users';
        String mode = _getPlatformInfo();
        String modeUpdated = _getPlatformInfo();

        if (_userDataCache.containsKey(uid)) {
          final cached = _userDataCache[uid]!;
          collection = cached['_collection'] ?? 'users';
          mode = cached['mode'] ?? mode;
          modeUpdated = cached['modeupdated'] ?? modeUpdated;
        }

        final response = await ApiService().getuserlogactivity(uid, mode, modeUpdated);
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          debugPrint('✅ [Background] Login activity logged');
        }
      } catch (e) {
        debugPrint('⚠️ [Background] Login activity failed: $e');
      }
    });
  }

  @override
  void onReady() {
    super.onReady();
    debugPrint('🚀 [AuthService] onReady - Starting initialization');
    _initializeAuthService();
  }

  // 🔧 CRITICAL: Proper initialization sequence for persistent auto-login
 Future<void> _initializeAuthService() async {
  try {
    _isInitializing = true;

    // ✅ Don't call checkAutoLogin here — SplashController handles it
    // Just bind the auth state listener for future sign-ins/sign-outs
    firebaseUser.bindStream(auth.authStateChanges());
    ever(firebaseUser, _handleAuthChangedDebounced);

    _isInitializing = false;
    debugPrint('✅ [Init] Auth service fully initialized');

  } catch (e) {
    debugPrint('❌ [Init] Initialization failed: $e');
    _isInitializing = false;
    if (auth.currentUser == null) {
      Get.offAllNamed(AppRoute.login);
    }
  }
}

  // 🔧 Debounced handler to prevent rapid-fire auth state changes
  void _handleAuthChangedDebounced(User? user) {
    _authStateDebouncer?.cancel();
    _authStateDebouncer = Timer(const Duration(milliseconds: 300), () {
      handleAuthChanged(user);
    });
  }

  // 🔧 IMPROVED: Auto-login that persists until explicit logout
  // Future<void> checkAutoLogin() async {
  //   // Prevent multiple simultaneous auto-login attempts
  //   if (hasCheckedAutoLogin.value) {
  //     debugPrint('⏭️ [AutoLogin] Already checked, skipping');
  //     return;
  //   }
    
  //   try {
  //     isAutoLoggingIn(true);
  //     debugPrint('🔍 [AutoLogin] Starting auto-login check...');
      
  //     // Firebase Auth automatically persists user sessions
  //     final currentUser = auth.currentUser;
      
  //     if (currentUser != null) {
  //       debugPrint('✅ [AutoLogin] Found existing session for: ${currentUser.uid}');
  //       debugPrint('📧 [AutoLogin] Email: ${currentUser.email ?? "N/A"}');
  //       debugPrint('📱 [AutoLogin] Phone: ${currentUser.phoneNumber ?? "N/A"}');
        
  //       // Set user ID for notifications immediately
  //       _notificationController?.setUserId(currentUser.uid);
        
  //       // Run background tasks (non-blocking)
  //       _syncFCMTokenAsync(currentUser);
  //       _logLoginActivityAsync(currentUser.uid);
        
  //       // Navigate user to appropriate screen based on their role
  //       await _handleAutoLoginNavigation(currentUser);
        
  //       debugPrint('✅ [AutoLogin] Successfully logged in automatically');
  //     } else {
  //       debugPrint('ℹ️ [AutoLogin] No existing session found - user needs to login');
  //       _notificationController?.clearUserId();
        
  //       // Navigate to login only if not already there
  //       if (Get.currentRoute != AppRoute.login) {
  //         Get.offAllNamed(AppRoute.login);
  //       }
  //     }
      
  //     hasCheckedAutoLogin(true);
      
  //   } catch (e, stackTrace) {
  //     debugPrint('❌ [AutoLogin] ERROR: $e');
  //     debugPrint('📝 Stack trace: $stackTrace');
      
  //     // On error, navigate to login
  //     Get.offAllNamed(AppRoute.login);
      
  //   } finally {
  //     isAutoLoggingIn(false);
  //   }
  // }



//   Future<void> checkAutoLogin() async {
//   if (hasCheckedAutoLogin.value) return;

//   try {
//     isAutoLoggingIn(true);
//     debugPrint('🔍 [AutoLogin] Waiting for Firebase to restore session...');

//     // ✅ Wait for Firebase to emit the FIRST auth event
//     // In release mode, auth.currentUser is null until Firebase reads
//     // the persisted token from disk. authStateChanges() fires once
//     // that restore is complete.
//     final currentUser = await auth.authStateChanges().first
//         .timeout(
//           const Duration(seconds: 5),
//           onTimeout: () {
//             debugPrint('⚠️ [AutoLogin] Timed out waiting for auth state');
//             return null; // treat as logged out
//           },
//         );

//     debugPrint('👤 [AutoLogin] Resolved user: ${currentUser?.uid ?? "null"}');

//     if (currentUser != null) {
//       _notificationController?.setUserId(currentUser.uid);
//       _syncFCMTokenAsync(currentUser);
//       _logLoginActivityAsync(currentUser.uid);
//       await _handleAutoLoginNavigation(currentUser);
//     } else {
//       _notificationController?.clearUserId();
//       if (Get.currentRoute != AppRoute.login) {
//         Get.offAllNamed(AppRoute.login);
//       }
//     }
//   } catch (e) {
//     debugPrint('❌ [AutoLogin] ERROR: $e');
//     Get.offAllNamed(AppRoute.login);
//   } finally {
//     isAutoLoggingIn(false);
//     hasCheckedAutoLogin(true);
//     // Bind stream only AFTER the one-shot check is done
//     firebaseUser.bindStream(auth.authStateChanges());
//     ever(firebaseUser, _handleAuthChangedDebounced);
//   }
// }

Future<void> checkAutoLogin() async {
  if (hasCheckedAutoLogin.value) return;

  try {
    isAutoLoggingIn(true);
    debugPrint('🔍 [AutoLogin] Waiting for Firebase to restore session...');

    // Release builds: Firebase reads the persisted token from disk and
    // validates it with Google's servers. This takes 3–8s on Play Store
    // builds. The authStateChanges() stream emits null immediately while
    // still initializing, then emits the real user later.
    //
    // The old await-for loop broke on the FIRST null emission — making the
    // 10-second timeout completely useless. We use a Completer instead so
    // null emissions are simply ignored until the real user arrives or the
    // timeout fires.
    final completer = Completer<User?>();

    // Synchronous fast-path: works in debug / warm restarts where the token
    // is already in memory.
    if (auth.currentUser != null) {
      debugPrint('⚡ [AutoLogin] User already in memory: ${auth.currentUser!.uid}');
      completer.complete(auth.currentUser);
    }

    // Stream listener — only completes on a non-null user.
    final sub = auth.authStateChanges().listen(
      (user) {
        if (user != null && !completer.isCompleted) {
          debugPrint('✅ [AutoLogin] Got user from stream: ${user.uid}');
          completer.complete(user);
        }
        // null emission while Firebase is still restoring — keep waiting.
      },
      onError: (e) {
        if (!completer.isCompleted) completer.complete(null);
      },
    );

    // Hard timeout: resolve with whatever auth.currentUser is at that point
    // (may still be null if the user is genuinely not logged in).
    final timer = Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        debugPrint('⏰ [AutoLogin] Timeout — currentUser: ${auth.currentUser?.uid ?? "null"}');
        completer.complete(auth.currentUser);
      }
    });

    final currentUser = await completer.future;
    timer.cancel();
    await sub.cancel();

    debugPrint('👤 [AutoLogin] Resolved user: ${currentUser?.uid ?? "null"}');

    if (currentUser != null) {
      _notificationController?.setUserId(currentUser.uid);
      _syncFCMTokenAsync(currentUser);
      _logLoginActivityAsync(currentUser.uid);
      await _handleAutoLoginNavigation(currentUser);
    } else {
      _notificationController?.clearUserId();
      if (Get.currentRoute != AppRoute.login) {
        Get.offAllNamed(AppRoute.login);
      }
    }
  } catch (e) {
    debugPrint('❌ [AutoLogin] ERROR: $e');
    Get.offAllNamed(AppRoute.login);
  } finally {
    isAutoLoggingIn(false);
    hasCheckedAutoLogin(true);
    // Do NOT rebind stream or re-register ever() here — _initializeAuthService
    // already did both. Doing it again creates duplicate handleAuthChanged calls.
  }
}

  // 🔧 Handle navigation during auto-login
  Future<void> _handleAutoLoginNavigation(User user) async {
    try {
      // Check cache first for faster navigation
      if (_userDataCache.containsKey(user.uid)) {
        debugPrint('⚡ [AutoLogin] Using cached user data');
        await _navigateBasedOnUserData(user.uid, _userDataCache[user.uid]!);
        return;
      }

      // Fetch user data from Firestore (parallel queries for speed)
      debugPrint('⚡ [AutoLogin] Fetching user data from Firestore...');
      final results = await Future.wait([
        _firestore.collection('technicians').doc(user.uid).get(),
        _firestore.collection('agents').doc(user.uid).get(),
        _firestore.collection('users').doc(user.uid).get(),
      ]);

      final techDoc = results[0];
      final agentDoc = results[1];
      final userDoc = results[2];

      Map<String, dynamic>? userData;
      String collection = 'users';

      // Determine user type and get their data
      if (techDoc.exists && techDoc.data()?['role'] == 'technician') {
        userData = techDoc.data();
        collection = 'technicians';
        debugPrint('👷 [AutoLogin] User is a Technician');
      } else if (agentDoc.exists && agentDoc.data()?['role'] == 'agent') {
        userData = agentDoc.data();
        collection = 'agents';
        debugPrint('🏢 [AutoLogin] User is an Agent');
      } else if (userDoc.exists) {
        userData = userDoc.data()!;
        debugPrint('👤 [AutoLogin] User is a regular User');
      } else {
        debugPrint('❌ [AutoLogin] No user document found in Firestore');
        _notificationController?.clearUserId();
        await auth.signOut();
        Get.offAllNamed(AppRoute.login);
        return;
      }

      // Cache the data for future use
      userData!['_collection'] = collection;
      _userDataCache[user.uid] = userData;

      // Navigate based on user data
      await _navigateBasedOnUserData(user.uid, userData);
      
    } catch (e, stackTrace) {
      debugPrint('❌ [AutoLogin] Navigation error: $e');
      debugPrint('📝 Stack: $stackTrace');
      Get.offAllNamed(AppRoute.login);
    }
  }

  // 🔧 Centralized navigation logic based on user role and status
  Future<void> _navigateBasedOnUserData(String uid, Map<String, dynamic> userData) async {
    final collection = userData['_collection'] ?? 'users';
    final role = userData['role'] ?? 'user';
    final status = userData['status'] ?? 'active';

    debugPrint('🧭 [Navigation] Collection: $collection, Role: $role, Status: $status');

    if (collection == 'technicians') {
      final userModel = TechnicianProfile(
        uid: uid,
        location: userData['location'] ?? '',
        fullName: userData['fullName'] ?? '',
        email: userData['email'] ?? '',
        mobile: userData['mobile'] ?? userData['phoneNumber'] ?? '',
        photoURL: userData['photoURL'] ?? '',
        role: 'technician',
      );
      Get.find<TechnicianController>().currentUser = userModel;
      userRole.value = 'technician';
      debugPrint('✅ [Navigation] Navigating to Technician Dashboard');
      
      if (Get.currentRoute != AppRoute.technicianDashboard) {
        Get.offAllNamed(AppRoute.technicianDashboard);
      }
      
    } else if (collection == 'agents') {
      if (status == 'approved') {
        final userModel = AgentModel(
          dob: userData['dob'] ?? '',
          gender: userData['gender'] ?? '',
          location: userData['location'] ?? '',
          uid: uid,
          email: userData['email'] ?? '',
          name: userData['displayName'] ?? '',
          role: 'agent',
          status: status,
        );
        Get.find<AgentController>().currentUser = userModel;
        userRole.value = 'agent';
        debugPrint('✅ [Navigation] Navigating to Agent Home');
        
        if (Get.currentRoute != AppRoute.navbar) {
          Get.offAllNamed(AppRoute.navbar);
        }
      } else {
        debugPrint('⚠️ [Navigation] Agent pending approval');
        userRole.value = 'agent';
        if (Get.currentRoute != AppRoute.approvalPendingPage) {
          Get.offAllNamed(AppRoute.approvalPendingPage);
        }
      }
      
    } else {
      // Regular user
      if (status == 'suspended' || status == 'banned') {
        debugPrint('⚠️ [Navigation] User account is suspended/banned');
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
        uid: uid,
        email: userData['email'] ?? '',
        name: userData['displayName'] ?? '',
        role: role,
        status: status,
        location: userData['location'] ?? '',
        phoneNumber: userData['phoneNumber'] ?? '',
      );
      Get.find<UserController>().currentUser = userModel;
      userRole.value = role;
      debugPrint('✅ [Navigation] Navigating to User Home');
      
      String targetRoute = AppRoute.navbar;
      if (role == 'technician') {
        targetRoute = AppRoute.technicianDashboard;
      }

      if (Get.currentRoute != targetRoute) {
        Get.offAllNamed(targetRoute);
      }
    }
  }

  // ⚡ Non-blocking FCM token sync
  void _syncFCMTokenAsync(User user) {
    Future.microtask(() async {
      try {
        debugPrint('🔄 [Background] Syncing FCM token for: ${user.uid}');
        
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken == null) {
          debugPrint('⚠️ [Background] No FCM token available');
          return;
        }
        
        String collection = 'users';
        if (_userDataCache.containsKey(user.uid)) {
          collection = _userDataCache[user.uid]!['_collection'] ?? 'users';
        } else {
          final results = await Future.wait([
            _firestore.collection('agents').doc(user.uid).get(),
            _firestore.collection('technicians').doc(user.uid).get(),
          ]);
          
          if (results[0].exists && results[0].data()?['role'] == 'agent') {
            collection = 'agents';
          } else if (results[1].exists && results[1].data()?['role'] == 'technician') {
            collection = 'technicians';
          }
        }
        
        final currentPlatform = _getPlatformInfo();
        final userDoc = await _firestore.collection(collection).doc(user.uid).get();
        final currentData = userDoc.data();
        
        Map<String, dynamic> updateData = {
          'fcmToken': fcmToken,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'mode': currentPlatform,
          'modeupdated': currentPlatform,
        };
        
        if (currentData == null || !currentData.containsKey('originalPlatform') || currentData['originalPlatform'] == null) {
          updateData['originalPlatform'] = currentPlatform;
        }
        
        await _firestore.collection(collection).doc(user.uid).update(updateData);
        debugPrint('✅ [Background] FCM token synced successfully');
        
      } catch (e) {
        debugPrint('⚠️ [Background] FCM sync failed: $e');
      }
    });
  }

  // 🔧 CRITICAL: Handle auth state changes (for new logins/logouts)
  void handleAuthChanged(User? user) async {
      if (!hasCheckedAutoLogin.value) {
    debugPrint('⏭️ [handleAuthChanged] Auto-login not done yet, skipping');
    return;
  }
    // 🔧 CRITICAL: Skip if any operation is in progress
    if (_isInitializing ||
        isAutoLoggingIn.value || 
        isSignInGoogle.value || 
        isSignInApple.value || 
        isSignInAgent.value || 
        isSignInTechnician.value || 
        isVerifyPhone.value) {
      debugPrint('⏳ [handleAuthChanged] Operation in progress, skipping');
      return;
    }

    debugPrint('🔄 [handleAuthChanged] Auth state changed');
    debugPrint('👤 User: ${user?.email ?? user?.phoneNumber ?? 'null'}');

    if (user == null) {
      debugPrint('❌ [handleAuthChanged] No user - clearing session');
      _notificationController?.clearUserId();
      
      if (Get.currentRoute != AppRoute.login) {
        Get.offAllNamed(AppRoute.login);
      }
      return;
    }

    debugPrint('✅ [handleAuthChanged] User found: ${user.uid}');
    
    // Set user ID for notifications
    _notificationController?.setUserId(user.uid);

    try {
      // Background tasks
      _syncFCMTokenAsync(user);
      _logLoginActivityAsync(user.uid);

      // Check cache first
      if (_userDataCache.containsKey(user.uid)) {
        debugPrint('⚡ [handleAuthChanged] Using cached data');
        await _handleCachedUser(user);
        return;
      }

      // Fetch user data
      debugPrint('⚡ [handleAuthChanged] Fetching user data...');
      final results = await Future.wait([
        _firestore.collection('technicians').doc(user.uid).get(),
        _firestore.collection('agents').doc(user.uid).get(),
        _firestore.collection('users').doc(user.uid).get(),
      ]);

      final techDoc = results[0];
      final agentDoc = results[1];
      final userDoc = results[2];

      Map<String, dynamic>? userData;
      String collection = 'users';

      if (techDoc.exists && techDoc.data()?['role'] == 'technician') {
        userData = techDoc.data();
        collection = 'technicians';
        userData!['_collection'] = collection;
        _userDataCache[user.uid] = userData;
        await _handleTechnicianUser(user, userData);
        if (Get.currentRoute != AppRoute.technicianDashboard) {
          Get.offAllNamed(AppRoute.technicianDashboard);
        }
        return;
      }

      if (agentDoc.exists && agentDoc.data()?['role'] == 'agent') {
        userData = agentDoc.data();
        collection = 'agents';
        final status = userData?['status'];
        userData!['_collection'] = collection;
        _userDataCache[user.uid] = userData;
        
        if (status == 'approved') {
          await _handleAgentUser(user, userData);
          if (Get.currentRoute != AppRoute.navbar) {
            Get.offAllNamed(AppRoute.navbar);
          }
        } else {
          if (Get.currentRoute != AppRoute.approvalPendingPage) {
            Get.offAllNamed(AppRoute.approvalPendingPage);
          }
        }
        return;
      }

      if (userDoc.exists) {
        userData = userDoc.data()!;
        userData['_collection'] = collection;
        _userDataCache[user.uid] = userData;
        await _handleRegularUser(user, userData);
      } else if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
        // Phone-auth user whose Firestore doc was created by admin under a
        // different UID — search by phone number as a fallback before giving up.
        debugPrint('⚠️ No doc by UID — searching by phoneNumber: ${user.phoneNumber}');
        final byPhone = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: user.phoneNumber)
            .limit(1)
            .get();

        // Also try the legacy "mobile" field name used by some admin-created docs
        final byMobile = byPhone.docs.isEmpty
            ? await _firestore
                .collection('users')
                .where('mobile', isEqualTo: user.phoneNumber)
                .limit(1)
                .get()
            : null;

        final matchDoc =
            byPhone.docs.isNotEmpty ? byPhone.docs.first : byMobile?.docs.firstOrNull;

        if (matchDoc != null) {
          debugPrint('✅ Found user by phone number, migrating to new UID');
          userData = matchDoc.data();
          // Write the new UID into the existing doc so future logins resolve instantly
          await _firestore.collection('users').doc(user.uid).set(
            {...userData, 'uid': user.uid},
            SetOptions(merge: true),
          );
          userData['_collection'] = 'users';
          _userDataCache[user.uid] = userData;
          await _handleRegularUser(user, userData);
        } else {
          debugPrint('❌ No user document found in any collection or by phone');
          _notificationController?.clearUserId();
          await auth.signOut();
          Get.offAllNamed(AppRoute.login);
        }
      } else {
        debugPrint('❌ No user document found');
        _notificationController?.clearUserId();
        await auth.signOut();
        Get.offAllNamed(AppRoute.login);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error in handleAuthChanged: $e');
      debugPrint('📝 Stack: $stackTrace');
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

  // Handle cached user data
  Future<void> _handleCachedUser(User user) async {
    final userData = _userDataCache[user.uid]!;
    final collection = userData['_collection'] ?? 'users';

    if (collection == 'technicians') {
      await _handleTechnicianUser(user, userData);
      if (Get.currentRoute != AppRoute.technicianDashboard) {
        Get.offAllNamed(AppRoute.technicianDashboard);
      }
    } else if (collection == 'agents') {
      final status = userData['status'];
      if (status == 'approved') {
        await _handleAgentUser(user, userData);
        if (Get.currentRoute != AppRoute.navbar) {
          Get.offAllNamed(AppRoute.navbar);
        }
      } else {
        if (Get.currentRoute != AppRoute.approvalPendingPage) {
          Get.offAllNamed(AppRoute.approvalPendingPage);
        }
      }
    } else {
      await _handleRegularUser(user, userData);
    }
  }

  // Handle regular user
  Future<void> _handleRegularUser(User user, Map<String, dynamic> userData) async {
    try {
      final status = userData['status'] ?? 'active';
      userRole.value = userData['role'] ?? 'user';

      if (status == 'suspended' || status == 'banned') {
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
      debugPrint('✅ Regular user logged in');

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

  // Handle agent user
  Future<void> _handleAgentUser(User user, Map<String, dynamic> userData) async {
    try {
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
      debugPrint('✅ Agent user handled');
    } catch (e) {
      debugPrint('❌ Error handling agent user: $e');
      _notificationController?.clearUserId();
      await auth.signOut();
      Get.offAllNamed(AppRoute.login);
    }
  }

  // Handle technician user
  Future<void> _handleTechnicianUser(User user, Map<String, dynamic> userData) async {
    try {
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
      debugPrint('✅ Technician user handled');
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

      // Background operations
      if (userCredential.user != null) {
        _syncFCMTokenAsync(userCredential.user!);
        _logLoginActivityAsync(userCredential.user!.uid);
      }

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

  Future<void> _handleExistingPhoneUser(User user) async {
    try {
      // Check cache first
      if (_userDataCache.containsKey(user.uid)) {
        final userData = _userDataCache[user.uid]!;
        final userModel = UserModel(
          uid: userData['uid'],
          phoneNumber: user.phoneNumber,
          name: userData['displayName'] ?? '',
          role: userData['role'] ?? 'user',
          status: userData['status'] ?? 'pending',
        );
        await _updateUserInController(userModel);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        // Cache it
        userData['_collection'] = 'users';
        _userDataCache[user.uid] = userData;
        
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
      
      final userData = {
        'uid': user.uid,
        'email': null,
        'displayName': fullNameController.text.trim(),
        'photoURL': null,
        'phoneNumber': user.phoneNumber,
        'role': 'user',
        'mode': _getPlatformInfo(),
        'createdAt': FieldValue.serverTimestamp(),
        'modeupdated': _getPlatformInfo(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));

      // Cache it
      userData['_collection'] = 'users';
      _userDataCache[user.uid] = userData;

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
      debugPrint('User details stored');
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

      // Update cache
      if (_userDataCache.containsKey(userId)) {
        _userDataCache[userId]!['displayName'] = newName;
      }

      debugPrint('User name updated successfully');
    } catch (e) {
      debugPrint('Error updating user name: $e');
      throw Exception('Failed to update user name: ${e.toString()}');
    }
  }

  // ⚡ Google Sign-In with background operations
  Future<UserCredential?> signInWithGoogle() async {
    try {
      debugPrint('🔐 Google Sign-In started...');
      isSignInGoogle(true);

      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('❌ Google sign-in cancelled');
        return null;
      }

      debugPrint('✅ Google user: ${googleUser.email}');

      final String? googleEmail = googleUser.email;
      if (googleEmail == null || googleEmail.isEmpty) {
        Get.snackbar('Error', 'Google account must have a valid email address');
        await _googleSignIn.signOut();
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception('Failed to get Google authentication tokens');
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase sign-in failed - no user returned');
      }

      debugPrint('✅ Firebase auth successful');

      // Background operations
      _syncFCMTokenAsync(firebaseUser);
      _logLoginActivityAsync(firebaseUser.uid);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _handleNewGoogleUser(firebaseUser, googleUser);
      } else {
        await _handleExistingGoogleUser(firebaseUser);
      }

      debugPrint('✅ Google sign-in complete');
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

  Future<void> _handleNewGoogleUser(
      User firebaseUser, GoogleSignInAccount googleUser) async {
    debugPrint('Handling new Google user: ${firebaseUser.uid}');

    try {
      _notificationController?.setUserId(firebaseUser.uid);
      
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
        'mode': _getPlatformInfo(),
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'registrationCompleted': true,
        'modeupdated': _getPlatformInfo(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userData, SetOptions(merge: true));

      // Cache it
      userData['_collection'] = 'users';
      _userDataCache[firebaseUser.uid] = userData;

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

  // Check cache first
  Future<void> _handleExistingGoogleUser(User user) async {
    try {
      // Check cache first
      if (_userDataCache.containsKey(user.uid)) {
        final userData = _userDataCache[user.uid]!;
        await _processExistingUserData(user, userData);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        // Cache it
        userData['_collection'] = 'users';
        _userDataCache[user.uid] = userData;
        
        await _processExistingUserData(user, userData);
      } else {
        await _handleLegacyGoogleUser(user);
      }
    } catch (e) {
      debugPrint('Error handling existing Google user: $e');
      Get.snackbar('Error', 'Failed to load user data. Please try again.');
      await auth.signOut();
      await _googleSignIn.signOut();
    }
  }

  // Extract common logic
  Future<void> _processExistingUserData(User user, Map<String, dynamic> userData) async {
    final status = userData['status'] ?? 'active';
    userRole.value = userData['role'] ?? '';

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

    final userModel = UserModel(
      location: userData['location'] ?? '',
      phoneNumber: userData['phoneNumber'] ?? '',
      uid: user.uid,
      email: user.email ?? userData['email'] ?? '',
      name: userData['displayName'] ?? user.displayName ?? '',
      role: userData['role'] ?? '',
      status: status,
    );

    Get.find<UserController>().currentUser = userModel;

    // Navigate based on role
    if (userModel.role == 'tenant') {
      Get.offAllNamed(AppRoute.navbar);
    } else if (userModel.role == 'agent') {
      Get.offAllNamed(AppRoute.navbar);
    } else if (userModel.role == 'technician') {
      Get.offAllNamed(AppRoute.technicianDashboard);
    } else {
      navigateToHome();
    }
  }

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
      
      // Cache it
      userData['_collection'] = 'users';
      _userDataCache[user.uid] = userData;
      
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
      debugPrint('Error handling legacy Google user: $e');
      Get.snackbar('Error', 'Account setup failed. Please try again.');
      await auth.signOut();
      await _googleSignIn.signOut();
    }
  }

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
        return;
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

  // Agent Registration
  Future<void> registerAgent() async {
    try {
      isRegisterAgent(true);
      
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

      final credential = await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

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

  // Agent Sign-In with background operations
  Future<UserCredential?> signInAsAgent() async {
    try {
      isSignInAgent(true);
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _notificationController?.setUserId(credential.user!.uid);
        
        // Background operations
        _syncFCMTokenAsync(credential.user!);
        _logLoginActivityAsync(credential.user!.uid);
      }

      final userDoc = await _firestore.collection('agents').doc(credential.user?.uid).get();

      if (userDoc.exists &&
          userDoc.data()?['role'] == 'agent' &&
          userDoc.data()?['status'] == 'approved') {
        
        userRole.value = 'agent';
        
        final userData = userDoc.data();
        // Cache it
        userData!['_collection'] = 'agents';
        _userDataCache[credential.user!.uid] = userData;
        
        final userModel = AgentModel(
          dob: userData['dob'] ?? '',
          gender: userData['gender'] ?? '',
          location: userData['location'] ?? '',
          uid: credential.user!.uid,
          email: credential.user!.email!,
          name: userData['displayName'] ?? '',
          role: userData['role'] ?? 'agent',
          status: userData['status'] ?? 'pending',
        );

        Get.find<AgentController>().currentUser = userModel;

        navigateToHome();

        return credential;
      } else {
        _notificationController?.clearUserId();
        await auth.signOut();
        Get.snackbar('Error',
            '"Sorry! Your account isn\'t registered as an agent yet or still needs approval. Please contact support if you think this is a mistake."');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      _notificationController?.clearUserId();
      Get.snackbar('Error', 'Agent login failed: ${e.message}');
      return null;
    } catch (e) {
      _notificationController?.clearUserId();
      Get.snackbar('Error', 'An unexpected error occurred');
      return null;
    } finally {
      isSignInAgent(false);
    }
  }

  // Technician Sign-In with background operations
  Future<UserCredential?> signInAsTechnician() async {
    try {
      isSignInTechnician(true);
      final String email = emailController.text.trim();
      final String password = passwordController.text.trim();

      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _notificationController?.setUserId(credential.user!.uid);
        
        // Background operations
        _syncFCMTokenAsync(credential.user!);
        _logLoginActivityAsync(credential.user!.uid);
      }
      
      final userDoc = await _firestore
          .collection('technicians')
          .doc(credential.user?.uid)
          .get();

      if (userDoc.exists && userDoc.data()?['role'] == 'technician') {
        userRole.value = 'technician';

        final userData = userDoc.data() as Map<String, dynamic>?;
        // Cache it
        userData!['_collection'] = 'technicians';
        _userDataCache[credential.user!.uid] = userData;

        final userModel = TechnicianProfile(
          uid: userData['uid'] ?? '',
          location: userData['location'] ?? '',
          fullName: userData['fullName'] ?? '',
          email: userData['email'] ?? credential.user?.email ?? '',
          mobile: userData['mobile'] ?? userData['phoneNumber'] ?? '',
          photoURL: userData['photoURL'] ?? '',
          role: userData['role'] ?? 'technician',
        );

        Get.find<TechnicianController>().currentUser = userModel;

        Get.offAllNamed(AppRoute.technicianDashboard);

        return credential;
      } else {
        _notificationController?.clearUserId();
        await auth.signOut();
        Get.snackbar('Error', 'This account is not registered as a technician');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      _notificationController?.clearUserId();
      Get.snackbar('Error', 'Technician login failed: ${e.message}');
      return null;
    } catch (e) {
      _notificationController?.clearUserId();
      Get.snackbar('Error', 'An unexpected error occurred');
      return null;
    } finally {
      isSignInTechnician(false);
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
          'mode': _getPlatformInfo(),
          'createdAt': FieldValue.serverTimestamp(),
          'modeupdated': _getPlatformInfo(),
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

  // Apple Sign-In with background operations
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

      if (appleCredential.identityToken == null) {
        throw Exception('Failed to get Apple authentication token');
      }

      final OAuthCredential credential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase sign-in failed - no user returned');
      }

      // Background operations
      _syncFCMTokenAsync(firebaseUser);
      _logLoginActivityAsync(firebaseUser.uid);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        await _handleNewAppleUser(firebaseUser, appleCredential);
      } else {
        await _handleExistingAppleUser(firebaseUser);
      }

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

  Future<void> _handleNewAppleUser(
    User firebaseUser, AuthorizationCredentialAppleID appleCredential) async {
    try {
      _notificationController?.setUserId(firebaseUser.uid);
      
      String email = appleCredential.email ?? firebaseUser.email ?? '';

      if (email.isEmpty) {
        email = '${firebaseUser.uid}@privaterelay.appleid.com';
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
        'mode': _getPlatformInfo(),
        'appleUserId': appleCredential.userIdentifier,
        'location': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'registrationCompleted': true,
        'modeupdated': _getPlatformInfo(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(userData, SetOptions(merge: true));

      // Cache it
      userData['_collection'] = 'users';
      _userDataCache[firebaseUser.uid] = userData;

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

  Future<void> _handleExistingAppleUser(User user) async {
    try {
      // Check cache first
      if (_userDataCache.containsKey(user.uid)) {
        final userData = _userDataCache[user.uid]!;
        await _processExistingUserData(user, userData);
        return;
      }

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        // Cache it
        userData['_collection'] = 'users';
        _userDataCache[user.uid] = userData;
        
        await _processExistingUserData(user, userData);
      } else {
        await _handleLegacyAppleUser(user);
      }
    } catch (e) {
      debugPrint('Error handling existing Apple user: $e');
      Get.snackbar('Error', 'Failed to load user data. Please try again.');
      await auth.signOut();
    }
  }

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
      
      // Cache it
      userData['_collection'] = 'users';
      _userDataCache[user.uid] = userData;
      
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

  // 🔧 CRITICAL: Sign out - clears session and forces login
  Future<void> signOut() async {
    try {
      isSignOutAll(true);
      
      debugPrint('🚪 [SignOut] Starting sign out process...');
      
      // Clear notification user ID
      _notificationController?.clearUserId();
      
      // Reset auto-login flag so it will check again next time
      hasCheckedAutoLogin(false);
      
      // Clear cache
      _userDataCache.clear();
      
      // Sign out from all providers
      await _googleSignIn.signOut();
      await auth.signOut(); // 🔧 This clears Firebase Auth session
      
      // Clear user role
      userRole.value = '';
      
      debugPrint('✅ [SignOut] Sign out complete');
      
      // Navigate to login
      Get.offAllNamed(AppRoute.login);
      
    } catch (e) {
      debugPrint('❌ [SignOut] Error during sign out: $e');
      Get.snackbar('Error', 'Failed to sign out: $e');
    } finally {
      isSignOutAll(false);
    }
  }
  
  @override
  void onClose() {
    _resendTimer?.cancel();
    _authStateDebouncer?.cancel();
    _userDataCache.clear();
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