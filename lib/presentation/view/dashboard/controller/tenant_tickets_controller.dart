// import 'dart:io';
// import 'package:majan/data/repositories/api_services.dart';
// import 'package:get/get.dart';
// import 'package:majan/data/model/tenant_ticket.dart';

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
import 'package:majan/data/datasources/api_client.dart';
import 'package:majan/data/model/full_complaint_model.dart';
import 'package:majan/data/model/tenant_summary_model.dart';
import 'package:majan/data/model/tenatpropertymodel.dart';
import 'package:majan/data/model/ticket_list_response_model.dart';
import 'package:majan/data/repositories/api_services.dart';
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
    debugPrint('[getSummaryForTenant] Response: ${response.data}');
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      try {
        // Extract the data from the 'data' key in the response
        final responseData = response.data['data'] as Map<String, dynamic>? ?? {};
        
        // Create TenantSummary from the response data
        final summary = TenantSummary.fromJson(responseData);
        
        // Check if API returned meaningful data
        if (summary.propertyStats.isNotEmpty) {
          technicianStats.value = summary;
          debugPrint('[getSummaryForTenant] Successfully loaded ${summary.propertyStats.length} properties from API');
        } else {
          debugPrint('[getSummaryForTenant] API returned empty stats, using fallback calculation');
          calculateStatsFromComplaints();
        }
        
      } catch (e, stackTrace) {
        debugPrint('[getSummaryForTenant] Parse error: $e');
        debugPrint('[getSummaryForTenant] Stack trace: $stackTrace');
        debugPrint('[getSummaryForTenant] Using fallback calculation due to parse error');
        calculateStatsFromComplaints();
      }
    } else {
      final errorMsg = response.data['message'] is Map 
          ? response.data['message']['en'] ?? 'Request failed'
          : response.data['message']?.toString() ?? 'Request failed';
      
      debugPrint('[getSummaryForTenant] API Error: $errorMsg, using fallback');
      calculateStatsFromComplaints();
    }
  } catch (e, stackTrace) {
    debugPrint('[getSummaryForTenant] Exception: $e, using fallback');
    debugPrint('[getSummaryForTenant] Stack trace: $stackTrace');
    calculateStatsFromComplaints();
  } finally {
    isStatsLoading.value = false;
    technicianStats.refresh();
  }
}

// Helper function to show beautiful error dialog
void _showCreativeErrorDialog({
  required String title,
  required String message,
  required String errorType,
  IconData icon = Icons.error_outline,
}) {
  // Use Get.dialog for a beautiful modal or show a snackbar
  Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Icon(icon, size: 50, color: Colors.orange),
          SizedBox(height: 10),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              errorType,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
      content: Text(message, textAlign: TextAlign.center),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text("Got it", style: TextStyle(color: Colors.blue)),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            getSummaryForTenant(
              FirebaseAuth.instance.currentUser?.uid ?? ''
            ); // Retry the request
          },
          child: Text("Try again", style: TextStyle(color: Colors.green)),
        ),
      ],
    ),
    barrierDismissible: true,
  );
}

// Get creative error message based on error type
String _getCreativeErrorMessage(String errorMsg) {
  final lowerError = errorMsg.toLowerCase();
  
  if (lowerError.contains('network') || lowerError.contains('connection')) {
    return '🌐 The digital highway seems to have a traffic jam!\n\nCheck your internet connection and try again. Our servers might be taking a quick coffee break. ☕';
  } else if (lowerError.contains('timeout')) {
    return '⏰ Our servers are working slower than a sloth on a Sunday!\n\nPlease try again in a moment. Good things take time, but this is ridiculous!';
  } else if (lowerError.contains('unauthorized') || lowerError.contains('401')) {
    return '🔐 Who goes there? It seems your access pass has expired.\n\nPlease log in again to continue your property management journey.';
  } else if (lowerError.contains('not found') || lowerError.contains('404')) {
    return '🧭 We\'ve searched high and low but this page seems to be on vacation!\n\nDon\'t worry, our digital detectives are on the case.';
  } else if (lowerError.contains('server')) {
    return '🛠️ Our hamsters are tired from running the server wheels!\n\nOur team has been alerted and is working to get things back to normal.';
  } else if (lowerError.contains('validation')) {
    return '📝 Oops! It looks like some information went on an adventure without us!\n\nPlease check your inputs and try again.';
  }
  
  return '🤖 Beep boop! Something unexpected happened:\n\n$errorMsg\n\nOur robot team is already working on a solution!';
}

// Get appropriate title based on error
String _getErrorTitle(String errorMsg) {
  final lowerError = errorMsg.toLowerCase();
  
  if (lowerError.contains('network') || lowerError.contains('connection')) {
    return 'Connection Interrupted!';
  } else if (lowerError.contains('timeout')) {
    return 'Taking Too Long!';
  } else if (lowerError.contains('unauthorized')) {
    return 'Access Expired!';
  } else if (lowerError.contains('not found')) {
    return 'Page Not Found!';
  } else if (lowerError.contains('server')) {
    return 'Server Tired!';
  }
  
  return 'Oops! Something Went Wrong';
}

// Get appropriate icon based on error
IconData _getErrorIcon(String errorMsg) {
  final lowerError = errorMsg.toLowerCase();
  
  if (lowerError.contains('network') || lowerError.contains('connection')) {
    return Icons.wifi_off;
  } else if (lowerError.contains('timeout')) {
    return Icons.timer_off;
  } else if (lowerError.contains('unauthorized')) {
    return Icons.lock_outline;
  } else if (lowerError.contains('not found')) {
    return Icons.search_off;
  } else if (lowerError.contains('server')) {
    return Icons.dns;
  }
  
  return Icons.error_outline;
}

// Add this helper method to calculate stats from existing complaints
void calculateStatsFromComplaints() {
  if (complaints.isEmpty) {
    debugPrint('[calculateStatsFromComplaints] No complaints available');
    technicianStats.value = TenantSummary(propertyStats: [], location: '', userId: '', totalProperties: '');
    return;
  }
  
  debugPrint('[calculateStatsFromComplaints] Calculating from ${complaints.length} complaints');
  
  // Group complaints by property
  final Map<String, List<Complaint>> complaintsByProperty = {};
  
  for (final complaint in complaints) {
    final propertyKey = complaint.propertyName.isNotEmpty 
        ? complaint.propertyName 
        : 'Default Property';
    
    complaintsByProperty.putIfAbsent(propertyKey, () => []).add(complaint);
  }
  
  // Create property stats from complaints
  final List<PropertyStats> calculatedStats = [];
  
  complaintsByProperty.forEach((propertyName, propertyComplaints) {
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
        pending++; // Default to pending for unknown statuses
      }
    }
    
    debugPrint('''
    [calculateStatsFromComplaints] $propertyName:
    - Total: $totalComplaints, Pending: $pending, In Progress: $inProgress, Resolved: $resolved
    ''');
    
    calculatedStats.add(PropertyStats(
      propertyId: propertyComplaints.first.flatnoId ?? '',
      propertyName: propertyName,
      totalComplaints: totalComplaints.toString(),
      startedWorking: pending.toString(),
      inProgress: inProgress.toString(),
      resolved: resolved.toString(),
    ));
  });
  
  // If no properties found, create a default one
  if (calculatedStats.isEmpty && complaints.isNotEmpty) {
    int totalComplaints = complaints.length;
    int resolved = complaints.where((c) => 
        c.status.toLowerCase().contains('resolved') || 
        c.statusText.en.toLowerCase().contains('resolved')).length;
    int pending = totalComplaints - resolved;
    
    calculatedStats.add(PropertyStats(
      propertyId: 'default',
      propertyName: 'My Properties',
      totalComplaints: totalComplaints.toString(),
      startedWorking: pending.toString(),
      inProgress: '0',
      resolved: resolved.toString(),
    ));
  }
  
  technicianStats.value = TenantSummary(propertyStats: calculatedStats, location: '', userId: '', totalProperties: '');
  technicianStats.refresh();
  
  debugPrint('[calculateStatsFromComplaints] Fallback calculation completed with ${calculatedStats.length} properties');
}
}