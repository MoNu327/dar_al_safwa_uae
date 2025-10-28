import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/data/datasources/api_client.dart';
import 'package:majan/data/model/tenant_summary_model.dart';
import 'package:majan/data/model/tenatpropertymodel.dart';
import 'package:majan/data/model/ticket_list_response_model.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:majan/domain/controller/notification_controller.dart';

class TenantsTicketsController extends GetxController {
  final ApiService apiService = ApiService();
  final ApiClient apiClient = ApiClient();
  
  // Complaint related observables
  final Rx<Complaint?> complaintDetails = Rx<Complaint?>(null);
  final RxBool isDetailsLoading = false.obs;
  final RxString detailsErrorMessage = ''.obs;
  RxList<Complaint> complaints = <Complaint>[].obs;
  RxBool isComplaintLoading = false.obs;
  RxString complaintErrorMessage = ''.obs;
  final RxBool hasComplaints = false.obs;
  final isStatsLoading = false.obs;
  final statsErrorMessage = ''.obs;
  final technicianStats = Rxn<TenantSummary>(); 
  
  // Property related observables
  RxList<TenantPropertyModel> properties = <TenantPropertyModel>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;
  
  // Technician assignment related observables
  final RxMap<String, dynamic> availableTechnicians = <String, dynamic>{}.obs;
  final RxBool isFetchingTechnicians = false.obs;
  final RxString technicianErrorMessage = ''.obs;
  final RxString selectedTechnicianId = ''.obs;
  final RxBool isAssigning = false.obs;

  // Notification related
  final RxString notificationTicketId = ''.obs;
  final RxBool shouldOpenTicketFromNotification = false.obs;
  final RxBool isNotificationHandled = false.obs;
  
  // Stream subscriptions
  StreamSubscription? _notificationSubscription;

  @override
  void onInit() {
    super.onInit();
    _setupNotificationListener();
    _checkInitialNotification();
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    super.onClose();
  }

  // Check if error is a server error (500 or 503)
  bool isServerError(int? statusCode) {
    return statusCode != null && (statusCode == 503);
  }

  /// Setup notification listener for ticket updates
  void _setupNotificationListener() {
    _notificationSubscription = Get.find<NotificationController>()
        .notificationStream
        .listen((notification) {
      _handleIncomingNotification(notification);
    });
  }

  /// Check for initial notification when app opens
  void _checkInitialNotification() {
    final args = Get.arguments;
    if (args != null && args is Map<String, dynamic>) {
      _handleNotificationData(args);
    }
  }

  /// Handle incoming notifications
  void _handleIncomingNotification(Map<String, dynamic> notification) {
    debugPrint('🎯 TenantsTicketsController: Received notification: $notification');
    
    final type = notification['type'] as String?;
    final isTicketNotification = type == 'ticket_reply' || 
                                type == 'complaint_reply' || 
                                type == 'ticket_update' ||
                                type == 'complaint' ||
                                type == 'tenant_ticket';

    if (isTicketNotification) {
      _handleNotificationData(notification);
    }
  }

  /// Handle notification data and trigger appropriate actions
  void _handleNotificationData(Map<String, dynamic> data) {
    final ticketId = data['ticketId'] as String? ?? data['complaintId'] as String?;
    final type = data['type'] as String?;

    debugPrint('🎯 Handling notification data:');
    debugPrint('  - Type: $type');
    debugPrint('  - Ticket ID: $ticketId');
    debugPrint('  - Full data: $data');

    if (ticketId != null && ticketId.isNotEmpty) {
      notificationTicketId.value = ticketId;
      shouldOpenTicketFromNotification.value = true;
      isNotificationHandled.value = false;

      // Show a snackbar to inform user
      Get.snackbar(
        'Ticket Update',
        'You have a new update on your ticket',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Refresh complaints to get latest data
      fetchTenantComplaints().then((_) {
        _openTicketFromNotification(ticketId);
      });
    }
  }

  /// Open specific ticket from notification
  // In TenantsTicketsController - update the method to find complaints
void _openTicketFromNotification(String ticketId) {
  if (isNotificationHandled.value) return;

  debugPrint('🎯 Attempting to open ticket: $ticketId');
  debugPrint('🎯 Available complaints: ${complaints.length}');
  
  // Check if complaints list is empty but API returned data
  if (complaints.isEmpty) {
    debugPrint('⚠️ Complaints list is empty, fetching details directly...');
    _fetchAndOpenComplaintDirectly(ticketId);
    return;
  }

  // Try to find the complaint by different ID fields
  Complaint? foundComplaint;
  
  // Method 1: Try complaintId match
  foundComplaint = complaints.firstWhereOrNull(
    (c) => c.complaintId == ticketId
  );
  
  // Method 2: Try flatnoId match
  if (foundComplaint == null) {
    foundComplaint = complaints.firstWhereOrNull(
      (c) => c.flatnoId == ticketId
    );
  }
  
  // Method 3: Try numeric ID match (if ticketId is numeric)
  if (foundComplaint == null && _isNumeric(ticketId)) {
    foundComplaint = complaints.firstWhereOrNull(
      (c) => c.complaintId == ticketId || 
             (c.flatnoId != null && c.flatnoId == ticketId)
    );
  }

  if (foundComplaint != null) {
    debugPrint('🎯 Found complaint: ${foundComplaint.complaintId}');
    debugPrint('🎯 Complaint flatnoId: ${foundComplaint.flatnoId}');
    debugPrint('🎯 Complaint status: ${foundComplaint.status}');
    
    isNotificationHandled.value = true;
    
    // Navigate to ticket details
    Get.toNamed(
      AppRoute.tenantTicketDetails,
      arguments: {
        'complaint': foundComplaint,
        'fromNotification': true,
        'notificationTicketId': ticketId,
      },
    );
  } else {
    debugPrint('❌ Complaint not found in list, fetching details directly...');
    _fetchAndOpenComplaintDirectly(ticketId);
  }
}

// Helper method to fetch complaint directly
void _fetchAndOpenComplaintDirectly(String ticketId) {
  fetchComplaintDetails(ticketId).then((_) {
    if (complaintDetails.value != null) {
      isNotificationHandled.value = true;
      Get.toNamed(
        AppRoute.tenantTicketDetails,
        arguments: {
          'complaint': complaintDetails.value,
          'fromNotification': true,
          'fetchedDirectly': true,
        },
      );
    } else {
      debugPrint('❌ Could not fetch complaint details for: $ticketId');
      Get.snackbar(
        'Error',
        'Could not load ticket details. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    }
  }).catchError((error) {
    debugPrint('❌ Error fetching complaint: $error');
    Get.snackbar(
      'Error',
      'Failed to load ticket details',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
  });
}

// Helper method to check if string is numeric
bool _isNumeric(String? s) {
  if (s == null) return false;
  return double.tryParse(s) != null;
}

  /// Fetch tenant properties
  Future<void> fetchTenantProperties({String? uid}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      uid ??= FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        errorMessage.value = 'User not logged in';
        return;
      }

      final response = await apiService.getMyProperties(uid);
      debugPrint('API Response (Properties): ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          properties.value =
              data.map((e) => TenantPropertyModel.fromJson(e)).toList();
        } else {
          errorMessage.value = 'Invalid properties data format';
        }
        debugPrint('Total Properties Loaded: ${properties.length}');
      } else {
        errorMessage.value =
            response.data['message']?['en'] ?? 'Failed to load properties';
        debugPrint('API Error: ${errorMessage.value}');
      }
    } on DioException catch (e) {
      if (isServerError(e.response?.statusCode)) {
        Get.offAllNamed(AppRoute.error);
        return;
      }
      errorMessage.value = 'Error: $e';
      debugPrint('Exception in fetchTenantProperties: $e');
    } catch (e) {
      errorMessage.value = 'Error: $e';
      debugPrint('Exception in fetchTenantProperties: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch tenant complaints
 /// Fetch tenant complaints - UPDATED VERSION
Future<void> fetchTenantComplaints() async {
  isComplaintLoading.value = true;
  complaintErrorMessage.value = '';
  hasComplaints.value = false;

  try {
    final response = await apiService.getTenantComplaints();
    debugPrint("API Response Status: ${response.status}");
    debugPrint("API Data Length: ${response.data.length}");

    if (response.status) {
      if (response.data.isEmpty) {
        complaintErrorMessage.value = "No complaints found";
        hasComplaints.value = false;
        complaints.clear();
      } else {
        hasComplaints.value = true;
        complaints.value = response.data;
        
        debugPrint("✅ Loaded ${complaints.length} complaints");
        
        // Log complaint IDs for debugging
        for (final complaint in complaints) {
          debugPrint("📝 Complaint: ID=${complaint.complaintId}, FlatNo=${complaint.flatnoId}, Status=${complaint.status}");
        }
        
        // Check if we need to open a ticket from notification
        if (shouldOpenTicketFromNotification.value && 
            !isNotificationHandled.value &&
            notificationTicketId.value.isNotEmpty) {
          debugPrint("🎯 Notification ticket waiting: ${notificationTicketId.value}");
          _openTicketFromNotification(notificationTicketId.value);
        }
      }
    } else {
      complaintErrorMessage.value = response.message;
      hasComplaints.value = false;
      complaints.clear();
    }
  } on DioException catch (e) {
    if (isServerError(e.response?.statusCode)) {
      Get.offAllNamed(AppRoute.error);
      return;
    }
    complaintErrorMessage.value = "Failed to load complaints: ${e.message}";
    hasComplaints.value = false;
    complaints.clear();
    debugPrint("❌ Dio Error: $e");
  } catch (e, stackTrace) {
    complaintErrorMessage.value = "Failed to load complaints";
    hasComplaints.value = false;
    complaints.clear();
    debugPrint("❌ Error: $e\n$stackTrace");
  } finally {
    isComplaintLoading.value = false;
  }
}

  /// Fetch complaint details by ID
  Future<void> fetchComplaintDetails(String complaintId) async {
    isDetailsLoading.value = true;
    detailsErrorMessage.value = '';

    try {
      final response = await apiService.getFullComplaintDetails(complaintId);
      debugPrint("API Response (Complaint Details): ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        complaintDetails.value = Complaint.fromJson(response.data['data']);
        debugPrint('Complaint Details Loaded: ${complaintDetails.value}');
      } else {
        detailsErrorMessage.value =
            response.data['message']?['en'] ?? 'Failed to load complaint details';
        debugPrint('API Error: ${detailsErrorMessage.value}');
      }
    } on DioException catch (e) {
      if (isServerError(e.response?.statusCode)) {
        Get.offAllNamed(AppRoute.error);
        return;
      }
      detailsErrorMessage.value = 'Error: $e';
      debugPrint('Exception in fetchComplaintDetails: $e');
    } catch (e) {
      detailsErrorMessage.value = 'Error: $e';
      debugPrint('Exception in fetchComplaintDetails: $e');
    } finally {
      isDetailsLoading.value = false;
    }
  }

  /// Fetch available technicians for assignment
  Future<void> fetchAvailableTechnicians() async {
    isFetchingTechnicians.value = true;
    technicianErrorMessage.value = '';
    selectedTechnicianId.value = '';

    try {
      final response = await apiClient.request(
        "technicians/except",
        method: "get",
      );

      if (response.data['success'] == true) {
        availableTechnicians.value = response.data['data'] ?? {};
        debugPrint('Technicians loaded: ${availableTechnicians['technicians']?.length ?? 0}');
      } else {
        technicianErrorMessage.value = 
            response.data['message']?['en'] ?? 'Failed to load technicians';
      }
    } on DioException catch (e) {
      if (isServerError(e.response?.statusCode)) {
        Get.offAllNamed(AppRoute.error);
        return;
      }
      technicianErrorMessage.value = 'Error fetching technicians: $e';
      debugPrint('Exception in fetchAvailableTechnicians: $e');
    } catch (e) {
      technicianErrorMessage.value = 'Error fetching technicians: $e';
      debugPrint('Exception in fetchAvailableTechnicians: $e');
    } finally {
      isFetchingTechnicians.value = false;
    }
  }

  /// Assign technician to a complaint
  Future<void> assignTechnician(String complaintId) async {
    if (selectedTechnicianId.value.isEmpty) {
      Get.snackbar('Error', 'Please select a technician');
      return;
    }

    isAssigning.value = true;

    try {
      final response = await apiClient.request(
        "technicians/except",
        method: "post",
        data: {
          "complaint_id": complaintId,
          "technician_id": selectedTechnicianId.value,
          "user_uid": FirebaseAuth.instance.currentUser?.uid,
        },
      );

      if (response.data['success'] == true) {
        Get.snackbar('Success', response.data['message']?['en'] ?? 'Technician assigned successfully');
        // Refresh the complaint details after assignment
        await fetchComplaintDetails(complaintId);
        // Refresh complaints list
        await fetchTenantComplaints();
      } else {
        Get.snackbar('Error', response.data['message']?['en'] ?? 'Assignment failed');
      }
    } on DioException catch (e) {
      if (isServerError(e.response?.statusCode)) {
        Get.offAllNamed(AppRoute.error);
        return;
      }
      Get.snackbar('Error', 'Failed to assign technician: $e');
    } catch (e) {
      Get.snackbar('Error', 'Failed to assign technician: $e');
    } finally {
      isAssigning.value = false;
    }
  }

  /// Clear selected technician
  void clearTechnicianSelection() {
    selectedTechnicianId.value = '';
  }

  /// Get summary for tenant
  Future<void> getSummaryForTenant(String userId) async {
    debugPrint('[getSummaryForTenant] Starting with userId: $userId');
    
    isStatsLoading.value = true;
    statsErrorMessage.value = '';
    technicianStats.value = null;

    try {
      final response = await apiClient.request(
        "Tenant/PropertyStats",
        method: "post",
        data: {"user_id": userId},
      );

      debugPrint('[getSummaryForTenant] Status: ${response.statusCode}');
      debugPrint('[getSummaryForTenant] Response: ${response.data}');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        try {
          final responseData = response.data['data'] as Map<String, dynamic>? ?? {};
          final summary = TenantSummary.fromJson(responseData);
          
          if (summary.propertyStats.isNotEmpty) {
            technicianStats.value = summary;
            debugPrint('[getSummaryForTenant] Successfully loaded ${summary.propertyStats.length} properties from API');
          } else {
            debugPrint('[getSummaryForTenant] API returned empty stats, using fallback calculation');
            calculateStatsFromPropertiesAndComplaints();
          }
          
        } catch (e, stackTrace) {
          debugPrint('[getSummaryForTenant] Parse error: $e');
          debugPrint('[getSummaryForTenant] Stack trace: $stackTrace');
          debugPrint('[getSummaryForTenant] Using fallback calculation due to parse error');
          calculateStatsFromPropertiesAndComplaints();
        }
      } else {
        final errorMsg = response.data['message'] is Map 
            ? response.data['message']['en'] ?? 'Request failed'
            : response.data['message']?.toString() ?? 'Request failed';
        
        debugPrint('[getSummaryForTenant] API Error: $errorMsg, using fallback');
        calculateStatsFromPropertiesAndComplaints();
      }
    } on DioException catch (e) {
      if (isServerError(e.response?.statusCode)) {
        Get.offAllNamed(AppRoute.error);
        return;
      }
      debugPrint('[getSummaryForTenant] Exception: $e, using fallback');
      calculateStatsFromPropertiesAndComplaints();
    } catch (e, stackTrace) {
      debugPrint('[getSummaryForTenant] Exception: $e, using fallback');
      debugPrint('[getSummaryForTenant] Stack trace: $stackTrace');
      calculateStatsFromPropertiesAndComplaints();
    } finally {
      isStatsLoading.value = false;
      technicianStats.refresh();
    }
  }

  /// Calculate stats from both properties and complaints
  void calculateStatsFromPropertiesAndComplaints() {
    debugPrint('[calculateStatsFromPropertiesAndComplaints] Starting calculation');
    debugPrint('[calculateStatsFromPropertiesAndComplaints] Properties: ${properties.length}, Complaints: ${complaints.length}');
    
    if (properties.isEmpty) {
      debugPrint('[calculateStatsFromPropertiesAndComplaints] No properties available');
      technicianStats.value = TenantSummary(
        propertyStats: [], 
        location: '', 
        userId: '', 
        totalProperties: '',
      );
      return;
    }
    
    final Map<String, List<Complaint>> complaintsByProperty = {};
    
    for (final complaint in complaints) {
      final propertyKey = complaint.flatnoId?.isNotEmpty == true
          ? complaint.flatnoId!
          : (complaint.propertyName.isNotEmpty 
              ? complaint.propertyName 
              : 'unknown');
      
      complaintsByProperty.putIfAbsent(propertyKey, () => []).add(complaint);
    }

    final List<PropertyStats> calculatedStats = [];
    
    for (final property in properties) {
      final propertyId = property.propertyId ?? '';
      final propertyName = property.unitAddressId ?? property.unitNumber ?? 'Property';
      
      final propertyComplaints = complaintsByProperty[propertyId] ?? [];
      
      int totalComplaints = propertyComplaints.length;
      int pending = 0;
      int inProgress = 0;
      int resolved = 0;
      
      for (final complaint in propertyComplaints) {
        final status = complaint.status.toLowerCase();
        final statusText = complaint.statusText.en.toLowerCase();
        
        if (status.contains('resolved') || status.contains('completed') || 
            statusText.contains('resolved') || statusText.contains('completed')) {
          resolved++;
        } else if (status.contains('progress') || statusText.contains('progress')) {
          inProgress++;
        } else {
          pending++;
        }
      }
      
      debugPrint('''
      [calculateStatsFromPropertiesAndComplaints] ${propertyId}:
      - Total: $totalComplaints, Pending: $pending, In Progress: $inProgress, Resolved: $resolved
      ''');
      
      calculatedStats.add(PropertyStats(
        propertyId: propertyId.toString(),
        totalComplaints: totalComplaints.toString(),
        startedWorking: pending.toString(),
        inProgress: inProgress.toString(),
        resolved: resolved.toString(), 
        propertyName: propertyName.toString(),
      ));
    }
    
    technicianStats.value = TenantSummary(
      propertyStats: calculatedStats,
      location: '',
      userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      totalProperties: properties.length.toString(),
    );
    technicianStats.refresh();
    
    debugPrint('[calculateStatsFromPropertiesAndComplaints] Calculation completed with ${calculatedStats.length} properties');
  }

  /// Manual refresh all data
  Future<void> refreshAllData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      await Future.wait([
        fetchTenantProperties(uid: userId),
        fetchTenantComplaints(),
        getSummaryForTenant(userId),
      ]);
    }
  }

  /// Get complaint by ID
  Complaint? getComplaintById(String complaintId) {
    return complaints.firstWhereOrNull(
      (c) => c.complaintId == complaintId || c.flatnoId == complaintId
    );
  }

  /// Mark notification as handled
  void markNotificationHandled() {
    isNotificationHandled.value = true;
    shouldOpenTicketFromNotification.value = false;
    notificationTicketId.value = '';
  }

  /// Check if there are pending notifications
  bool hasPendingNotifications() {
    return shouldOpenTicketFromNotification.value && 
           !isNotificationHandled.value &&
           notificationTicketId.value.isNotEmpty;
  }
}