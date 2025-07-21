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
