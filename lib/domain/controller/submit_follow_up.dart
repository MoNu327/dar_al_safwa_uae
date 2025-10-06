// import 'package:majan/data/model/customer_followUp_response%20.dart';
// import 'package:majan/data/model/technican_drop_downforcustomerfollowup.dart';
// import 'package:majan/data/repositories/api_services.dart';
// import 'package:get/get.dart';

// class CustomerFollowUpController extends GetxController {
//   final ApiService apiService = Get.find<ApiService>();
  
//   // Reactive variables for supervisors/technicians
//   var isLoading = false.obs;
//   var supervisorsList = <Supervisor>[].obs;
//   var selectedSupervisor = RxnString();
  
//   // Reactive variables for customer follow-up
//   var isFollowUpLoading = false.obs;
//   var followUpData = Rxn<CustomerFollowUpData>();
//   var followUpResponse = Rxn<CustomerFollowUpResponse>();
//   var followUpErrorMessage = ''.obs;
  
//   // Reactive variable for submission
//   var isSubmitting = false.obs;

//   @override
//   void onInit() {
//     super.onInit();
//     // You can load supervisors when controller initializes
//     // or call loadSupervisors() from the widget when needed
//   }

//   // Method to fetch technicians/supervisors by property ID
//   Future<void> loadSupervisors(int propertyId) async {
//     try {
//       isLoading(true);
//       followUpErrorMessage('');
      
//       final response = await apiService.gettechnicianbyproperty(propertyId);
      
//       if (response.statusCode == 200) {
//         final data = response.data;
        
//         if (data['status'] == true) {
//           // Extract technicians list from response
//           final technicians = data['data']['technicians'] as List<dynamic>;
          
//           // Convert to Supervisor objects
//           supervisorsList.assignAll(
//             technicians.map((tech) => Supervisor.fromJson(tech)).toList()
//           );
//         } else {
//           followUpErrorMessage(data['message']['en'] ?? 'Failed to load supervisors');
//         }
//       } else {
//         followUpErrorMessage('Failed to load supervisors: ${response.statusCode}');
//       }
//     } catch (e) {
//       followUpErrorMessage('Error loading supervisors: $e');
//       print('Error loading supervisors: $e');
//     } finally {
//       isLoading(false);
//     }
//   }

//   // Method to fetch customer follow-up data by chat ID
//   Future<void> loadCustomerFollowUp(String chatId) async {
//     try {
//       isFollowUpLoading(true);
//       followUpErrorMessage('');
      
//       final response = await apiService.getcustomerfollowup(chatId);
      
//       if (response.statusCode == 200) {
//         final data = response.data;
        
//         if (data['status'] == true) {
//           // Parse the response using the model
//           final followUpResponse = CustomerFollowUpResponse.fromJson(data);
//           this.followUpResponse.value = followUpResponse;
//           followUpData.value = followUpResponse.data;
//         } else {
//           followUpErrorMessage(data['message']['en'] ?? 'Failed to load follow-up data');
//         }
//       } else {
//         followUpErrorMessage('Failed to load follow-up data: ${response.statusCode}');
//       }
//     } catch (e) {
//       followUpErrorMessage('Error loading follow-up data: $e');
//       print('Error loading follow-up data: $e');
//     } finally {
//       isFollowUpLoading(false);
//     }
//   }

//   // Method to submit follow-up
//   Future<bool> submitFollowUp({
//     required String customerId,
//     required int propertyId,
//     required String unitType,
//     required String technicianId,
//     required int saleStatus,
//     required String notes,
//   }) async {
//     try {
//       isSubmitting(true);
//       followUpErrorMessage('');
      
//       final response = await apiService.submitFollowUp(
//         customerId: customerId,
//         propertyId: propertyId,
//         unitType: unitType,
//         technicianId: technicianId,
//         saleStatus: saleStatus,
//         notes: notes,
//       );
      
//       if (response.statusCode == 200) {
//         final data = response.data;
        
//         if (data['status'] == true) {
//           return true;
//         } else {
//           followUpErrorMessage(data['message']['en'] ?? 'Failed to submit follow-up');
//           return false;
//         }
//       } else {
//         followUpErrorMessage('Failed to submit follow-up: ${response.statusCode}');
//         return false;
//       }
//     } catch (e) {
//       followUpErrorMessage('Error submitting follow-up: $e');
//       print('Error submitting follow-up: $e');
//       return false;
//     } finally {
//       isSubmitting(false);
//     }
//   }

//   // Method to set selected supervisor
//   void setSelectedSupervisor(String? value) {
//     selectedSupervisor.value = value;
//   }

//   // Clear supervisors list
//   void clearSupervisors() {
//     supervisorsList.clear();
//   }

//   // Clear follow-up data
//   void clearFollowUpData() {
//     followUpData.value = null;
//     followUpResponse.value = null;
//     followUpErrorMessage('');
//   }
  
//   // Helper method to convert status string to integer
//   int getStatusValue(String status) {
//     switch (status) {
//       case 'Property Visit Pending':
//         return 1;
//       case 'Property Visit Scheduled':
//         return 2;
//       case 'Property Visited':
//         return 3;
//       case 'Property Agreed':
//         return 4;
//       default:
//         return 1;
//     }
//   }
// }