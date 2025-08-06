// import 'dart:io';
// import 'package:dar_al_safwa/data/repositories/api_services.dart';
// import 'package:get/get.dart';
// import 'package:dar_al_safwa/data/model/tenant_ticket.dart';

// class TenantTicketController extends GetxController {
//   final ApiService _apiService = ApiService();

//   // Reactive variables
//   var isLoading = false.obs;
//   var categories = <String>[].obs;
//   var subcategories = <String>[].obs;
//   var tickets = <TenantTicket>[].obs;

//   var selectedCategory = ''.obs;
//   var selectedSubcategory = ''.obs;

//   /// Fetch categories
//   Future<void> fetchCategories() async {
//     try {
//       isLoading.value = true;
//       final response = await ApiService.getComplaintCategories();
//       categories.value = List<String>.from(response.data['categories'] ?? []);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load categories: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Fetch subcategories
//   Future<void> fetchSubcategories(String categoryId) async {
//     try {
//       isLoading.value = true;
//       final request = TenantTicketSubCategoriesRequest(categoryId: categoryId);
//       final response = await _apiService.getTenantTicketSubcategories(request);
//       subcategories.value = List<String>.from(response.data['subcategories'] ?? []);
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to load subcategories: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Create ticket
//   Future<void> createTicket({
//     required String property,
//     required String category,
//     String? subcategory,
//     required String issue,
//     List<File>? imageFiles,
//   }) async {
//     try {
//       isLoading.value = true;

//       final ticket = TenantTicket(
//         property: property,
//         category: category,
//         subcategory: subcategory,
//         issue: issue,
//         images: imageFiles?.map((e) => e.path).toList() ?? [],
//       );

//       final response = await _apiService.createTenantTicket(ticket);
//       Get.snackbar('Success', response.data['message'] ?? 'Ticket created successfully');
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to create ticket: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   /// Fetch user's tickets (optional)
//   Future<void> fetchUserTickets(String uid) async {
//     try {
//       isLoading.value = true;
//       final response = await _apiService.getTenantTickets(uid);
//       final List data = response.data['tickets'] ?? [];
//       tickets.value = data.map((e) => TenantTicket.fromJson(e)).toList();
//     } catch (e) {
//       Get.snackbar('Error', 'Failed to fetch tickets: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }
// }
import 'dart:convert';
import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/full_complaint_model.dart';
import 'package:dar_al_safwa/data/model/tenant_summary_model.dart';
import 'package:dar_al_safwa/data/model/tenatpropertymodel.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

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
   final isStatsLoading = false.obs; // Using GetX observable
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
    } catch (e) {
      errorMessage.value = 'Error: $e';
      debugPrint('Exception in fetchTenantProperties: $e');
    } finally {
      isLoading.value = false;
    }
  }



  

  /// Fetch tenant complaints
  Future<void> fetchTenantComplaints() async {
    isComplaintLoading.value = true;
    complaintErrorMessage.value = '';
    hasComplaints.value = false;

    try {
      final response = await apiService.getTenantComplaints();
      debugPrint("API Response: ${response.toJson()}");
      debugPrint("API  : ${response.data}");

      if (response.status) {
        if (response.data.isEmpty) {
          complaintErrorMessage.value = response.message;
        } else {
          hasComplaints.value = true;
          complaints.value = response.data;
        }
      } else {
        complaintErrorMessage.value = response.message;
      }
    } catch (e, stackTrace) {
      complaintErrorMessage.value = "Failed to load complaints";
      debugPrint("Error: $e\n$stackTrace");
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
      } else {
        Get.snackbar('Error', response.data['message']?['en'] ?? 'Assignment failed');
      }
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
    debugPrint('[getSummaryForTenant] Raw response: ${jsonEncode(response.data)}');
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      debugPrint('[getSummaryForTenant] Full response structure:');
      debugPrint(jsonEncode(response.data));
      
      try {
        // Let's examine the actual structure first
        final responseData = response.data;
        debugPrint('[getSummaryForTenant] Response data keys: ${responseData.keys}');
        
        if (responseData.containsKey('data')) {
          debugPrint('[getSummaryForTenant] Data content: ${jsonEncode(responseData['data'])}');
        }
        
        // Try parsing with more detailed error handling
        final summary = TenantSummary.fromJson(response.data);
        
        // Always set the summary, even if empty
        technicianStats.value = summary;
        
        // Enhanced debugging for property stats
        if (summary.propertyStats.isEmpty) {
          debugPrint('[getSummaryForTenant] Warning: Received empty property stats');
          debugPrint('[getSummaryForTenant] Checking if data exists in response...');
          
          // Check if there's data but parsing failed
          if (responseData.containsKey('data') && responseData['data'] != null) {
            final data = responseData['data'];
            if (data is Map && data.containsKey('property_stats')) {
              debugPrint('[getSummaryForTenant] Found property_stats in data: ${data['property_stats']}');
            } else if (data is List && data.isNotEmpty) {
              debugPrint('[getSummaryForTenant] Found list data: $data');
            }
          }
        } else {
          debugPrint('[getSummaryForTenant] Successfully parsed ${summary.propertyStats.length} properties');
          
          // Detailed property debug output with null safety
          for (final stat in summary.propertyStats) {
            debugPrint('''
            Property Details:
            - ID: ${stat.propertyId}
            - Name: ${stat.propertyName}
            - Total Complaints: ${stat.totalComplaints} (parsed as: ${int.tryParse(stat.totalComplaints)})
            - Started: ${stat.startedWorking} (parsed as: ${int.tryParse(stat.startedWorking)})
            - In Progress: ${stat.inProgress} (parsed as: ${int.tryParse(stat.inProgress)})
            - Resolved: ${stat.resolved} (parsed as: ${int.tryParse(stat.resolved)})
            --------------------------
            ''');
          }
        }
        
        // Also check if the complaints list has data for comparison
        debugPrint('[getSummaryForTenant] Current complaints count: ${complaints.length}');
        debugPrint('[getSummaryForTenant] Complaints data: ${complaints.map((c) => c.complaintNumber).join(', ')}');
        
      } catch (e, stackTrace) {
        debugPrint('[getSummaryForTenant] Parse error: $e');
        debugPrint('[getSummaryForTenant] Stack trace: $stackTrace');
        
        // Try to extract raw data for manual inspection
        if (response.data.containsKey('data')) {
          debugPrint('[getSummaryForTenant] Raw data for manual inspection:');
          debugPrint(jsonEncode(response.data['data']));
        }
        
        statsErrorMessage.value = 'Data format error: ${e.toString()}';
        technicianStats.value = null;
      }
    } else {
      final errorMsg = response.data['message'] is Map 
          ? response.data['message']['en'] ?? 'Request failed'
          : response.data['message']?.toString() ?? 'Request failed';
      statsErrorMessage.value = errorMsg;
      debugPrint('[getSummaryForTenant] API Error: $errorMsg');
      debugPrint('[getSummaryForTenant] Full error response: ${jsonEncode(response.data)}');
    }
  } on DioException catch (e) {
    final errorMsg = e.response?.data?['message']?.toString() ?? e.message ?? 'Network error';
    statsErrorMessage.value = errorMsg;
    debugPrint('[getSummaryForTenant] DioError: $errorMsg');
    debugPrint('[getSummaryForTenant] Error response: ${e.response?.data}');
    debugPrint(e.stackTrace?.toString() ?? 'No stack trace');
  } catch (e, stackTrace) {
    statsErrorMessage.value = 'Unexpected error: ${e.toString()}';
    debugPrint('[getSummaryForTenant] Unexpected error: $e');
    debugPrint('[getSummaryForTenant] Stack trace: $stackTrace');
  } finally {
    isStatsLoading.value = false;
    // Force UI update
    technicianStats.refresh();
    debugPrint('[getSummaryForTenant] Completed loading. Final value: ${technicianStats.value != null ? "not null with ${technicianStats.value?.propertyStats.length} properties" : "null"}');
    
    // Add a fallback calculation using existing complaints data
    if (technicianStats.value?.propertyStats.isEmpty ?? true) {
      debugPrint('[getSummaryForTenant] No stats from API, calculating from existing complaints...');
      _calculateStatsFromComplaints();
    }
  }
}

// Add this helper method to calculate stats from existing complaints
void _calculateStatsFromComplaints() {
  if (complaints.isEmpty) {
    debugPrint('[calculateStatsFromComplaints] No complaints available for calculation');
    return;
  }
  
  debugPrint('[calculateStatsFromComplaints] Calculating from ${complaints.length} complaints');
  
  // Group complaints by property
  final Map<String, List<Complaint>> complaintsByProperty = {};
  
  for (final complaint in complaints) {
    final propertyKey = complaint.propertyName.isNotEmpty 
        ? complaint.propertyName 
        : 'Unknown Property';
    
    complaintsByProperty.putIfAbsent(propertyKey, () => []).add(complaint);
  }
  
  debugPrint('[calculateStatsFromComplaints] Properties found: ${complaintsByProperty.keys.join(', ')}');
  
  // Create property stats from complaints
  final List<PropertyStats> calculatedStats = [];
  
  complaintsByProperty.forEach((propertyName, propertyComplaints) {
    int totalComplaints = propertyComplaints.length;
    int pending = propertyComplaints.where((c) => 
        c.status.toLowerCase() == 'pending' || 
        c.statusText.en.toLowerCase() == 'pending').length;
    int inProgress = propertyComplaints.where((c) => 
        c.status.toLowerCase().contains('progress') || 
        c.statusText.en.toLowerCase().contains('progress')).length;
    int resolved = propertyComplaints.where((c) => 
        c.status.toLowerCase() == 'resolved' || 
        c.status.toLowerCase() == 'completed' ||
        c.statusText.en.toLowerCase() == 'resolved' ||
        c.statusText.en.toLowerCase() == 'completed').length;
    
    debugPrint('''
    [calculateStatsFromComplaints] $propertyName:
    - Total: $totalComplaints
    - Pending: $pending  
    - In Progress: $inProgress
    - Resolved: $resolved
    ''');
    
    // You'll need to create PropertyStat objects here
    // This is a placeholder - adjust according to your PropertyStat model
    // calculatedStats.add(PropertyStat(
    //   propertyId: propertyComplaints.first.flatnoId ?? '',
    //   propertyName: propertyName,
    //   totalComplaints: totalComplaints.toString(),
    //   startedWorking: pending.toString(),
    //   inProgress: inProgress.toString(),
    //   resolved: resolved.toString(),
    // ));
  });
  
  // Update the stats (you may need to adjust this based on your TenantSummary model)
  // technicianStats.value = TenantSummary(propertyStats: calculatedStats);
  // technicianStats.refresh();
  
  debugPrint('[calculateStatsFromComplaints] Fallback calculation completed');
}
}