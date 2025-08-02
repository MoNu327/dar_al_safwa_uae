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
}