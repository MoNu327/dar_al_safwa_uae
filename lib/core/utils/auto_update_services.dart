import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:get/get.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  /// Check for Android updates using Google Play In-App Update API
  Future<void> checkAndroidUpdate({bool forceUpdate = false}) async {
    if (!Platform.isAndroid) {
      debugPrint('⚠️ Not Android platform, skipping update check');
      return;
    }

    try {
      debugPrint('🔍 Checking for Android updates...');
      debugPrint('📱 Current app state: ${forceUpdate ? "Force Update" : "Normal Check"}');
      
      final updateInfo = await InAppUpdate.checkForUpdate();
      
      debugPrint('📊 Update Info:');
      debugPrint('   - Update Availability: ${updateInfo.updateAvailability}');
      debugPrint('   - Immediate Update Allowed: ${updateInfo.immediateUpdateAllowed}');
      debugPrint('   - Flexible Update Allowed: ${updateInfo.flexibleUpdateAllowed}');
      debugPrint('   - Available Version Code: ${updateInfo.availableVersionCode ?? "N/A"}');
      debugPrint('   - Install Status: ${updateInfo.installStatus}');
      debugPrint('   - Update Priority: ${updateInfo.updatePriority}');
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        debugPrint('✅ Update available!');
        
        // Check update priority (0-5, where 5 is highest)
        // Priority 4-5: Immediate update
        // Priority 0-3: Flexible update
        if (forceUpdate || updateInfo.updatePriority >= 4) {
          if (updateInfo.immediateUpdateAllowed) {
            await _performImmediateUpdate();
          } else {
            debugPrint('⚠️ Immediate update not allowed by Play Store');
            if (updateInfo.flexibleUpdateAllowed) {
              await _performFlexibleUpdate();
            }
          }
        } else if (updateInfo.flexibleUpdateAllowed) {
          await _performFlexibleUpdate();
        } else {
          debugPrint('⚠️ No update method allowed');
        }
      } else if (updateInfo.updateAvailability == UpdateAvailability.updateNotAvailable) {
        debugPrint('✅ App is up to date');
      } else if (updateInfo.updateAvailability == UpdateAvailability.unknown) {
        debugPrint('⚠️ Update availability unknown - possible causes:');
        debugPrint('   - App not installed from Play Store');
        debugPrint('   - Not published to production/testing track');
        debugPrint('   - Version code not incremented');
      } else {
        debugPrint('⚠️ Update availability: ${updateInfo.updateAvailability}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Update check error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Immediate update (force update)
  Future<void> _performImmediateUpdate() async {
    try {
      debugPrint('🚀 Starting immediate update...');
      
      final result = await InAppUpdate.performImmediateUpdate();
      
      debugPrint('📊 Immediate update result: $result');
      
      if (result == AppUpdateResult.success) {
        debugPrint('✅ Update completed successfully');
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        debugPrint('⚠️ User denied the update');
      } else if (result == AppUpdateResult.inAppUpdateFailed) {
        debugPrint('❌ In-app update failed');
      } else {
        debugPrint('⚠️ Update result: $result');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Immediate update error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Flexible update (background download)
  Future<void> _performFlexibleUpdate() async {
    try {
      debugPrint('📥 Starting flexible update...');
      
      final result = await InAppUpdate.startFlexibleUpdate();
      
      debugPrint('📊 Flexible update result: $result');
      
      if (result == AppUpdateResult.success) {
        debugPrint('✅ Flexible update started - downloading in background');
        
        // Listen for download completion
        InAppUpdate.completeFlexibleUpdate().then((_) {
          debugPrint('✅ Update downloaded successfully, showing restart dialog');
          _showRestartDialog();
        }).catchError((error) {
          debugPrint('❌ Complete flexible update error: $error');
        });
      } else if (result == AppUpdateResult.userDeniedUpdate) {
        debugPrint('⚠️ User denied the flexible update');
      } else if (result == AppUpdateResult.inAppUpdateFailed) {
        debugPrint('❌ Flexible update failed');
      } else {
        debugPrint('⚠️ Flexible update result: $result');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Flexible update error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Show restart dialog after flexible update
  void _showRestartDialog() {
    if (Get.isDialogOpen ?? false) return; // Prevent duplicate dialogs
    
    Get.dialog(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.system_update, color: Colors.green),
            SizedBox(width: 10),
            Text('Update Ready'),
          ],
        ),
        content: const Text(
          'A new version has been downloaded. Please restart the app to apply the update.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              InAppUpdate.completeFlexibleUpdate();
            },
            child: const Text('Restart Now'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  /// Universal update check (works for both Android & iOS)
  Future<void> checkForUpdates({bool forceUpdate = false}) async {
    debugPrint('🔧 ========================================');
    debugPrint('🔧 APP UPDATE CHECK STARTED');
    debugPrint('🔧 ========================================');
    
    if (Platform.isAndroid) {
      await checkAndroidUpdate(forceUpdate: forceUpdate);
    } else if (Platform.isIOS) {
      // iOS updates are handled by UpgradeAlert widget in main.dart
      debugPrint('✅ iOS updates handled by UpgradeAlert widget');
    }
    
    debugPrint('🔧 ========================================');
    debugPrint('🔧 APP UPDATE CHECK COMPLETED');
    debugPrint('🔧 ========================================');
  }
}