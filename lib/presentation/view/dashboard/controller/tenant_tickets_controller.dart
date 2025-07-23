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
import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/tenatpropertymodel.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/data/repositories/api_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class TenantsTicketsController extends GetxController {
  final ApiService apiService = ApiService();
  final ApiClient apiClient = ApiClient();

  RxList<Complaint> complaints = <Complaint>[].obs;
  RxBool isComplaintLoading = false.obs;
  RxString complaintErrorMessage = ''.obs;

  RxList<TenantPropertyModel> properties = <TenantPropertyModel>[].obs;
  RxBool isLoading = false.obs;
  RxString errorMessage = ''.obs;

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

    try {
      final ComplaintsResponse response = await apiService.getTenantComplaints();
      debugPrint("Complaints API Response: ${response.toJson()}");

      if (response.status == true) {
        complaints.value = response.data;
        debugPrint("Loaded Complaints Count: ${complaints.length}");
      } else {
        complaintErrorMessage.value =
            response.message.isNotEmpty ? response.message : "Failed to load complaints";
      }
    } catch (e) {
      complaintErrorMessage.value = "Error: $e";
      debugPrint("❌ Error in fetchTenantComplaints: $e");
    } finally {
      isComplaintLoading.value = false;
    }
  }
}

