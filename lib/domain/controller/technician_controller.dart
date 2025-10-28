import 'package:majan/data/datasources/api_client.dart';
import 'package:majan/data/model/technician_model.dart';
import 'package:dio/src/response.dart';
import 'package:get/get.dart' hide Response;
import 'package:flutter/foundation.dart'; // for debugPrint

class TechnicianController extends GetxController {
  TechnicianProfile? _currentUser;
  TechnicianProfile? get currentUser => _currentUser;

  final ApiClient apiClient = ApiClient();
  final isLoading = false.obs;

  /// Setter
  set currentUser(TechnicianProfile? user) {
    _currentUser = user;
    update();
  }

  /// Fetch technician profile using UID
  Future<void> fetchTechnicianProfile(String uid) async {
    debugPrint("🔍 [TechnicianController] Fetching profile for UID: $uid");

    try {
      isLoading.value = true;

      final response = await getTechnicianDetails(uid);

      debugPrint("✅ [TechnicianController] Response: ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        final profile = TechnicianProfile.fromJson(response.data['data']);
        currentUser = profile;
        debugPrint("👤 [TechnicianController] Profile Loaded: ${profile.toJson()}");
      } else {
        currentUser = null;
        final errorMessage = response.data['message']['en'] ?? "Failed to fetch details";
        debugPrint("❌ [TechnicianController] Error: $errorMessage");
        Get.snackbar("Error", errorMessage);
      }
    } catch (e, stackTrace) {
      currentUser = null;
      debugPrint("🔥 [TechnicianController] Exception: $e");
      debugPrint("🧵 StackTrace: $stackTrace");
      Get.snackbar("Error", "Something went wrong: $e");
    } finally {
      isLoading.value = false;
      debugPrint("⏹ [TechnicianController] Fetch process completed");
    }
  }

  /// API Service: Get Technician Details
  Future<Response> getTechnicianDetails(String uid) async {
    try {
      debugPrint("➡️ [API] Requesting technician/details with UID: $uid");
      final response = await apiClient.request(
        "technician/details",
        method: "post",
        data: {"uid": uid}, // Send uid dynamically
      );
      debugPrint("⬅️ [API] Response received: ${response.data}");
      return response;
    } catch (e, stackTrace) {
      debugPrint("🔥 [API] Exception: $e");
      debugPrint("🧵 StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Clear Technician Profile
  void clearUser() {
    debugPrint("🗑 [TechnicianController] Clearing current technician profile");
    currentUser = null;
  }
}


