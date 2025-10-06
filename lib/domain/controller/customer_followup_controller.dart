import 'package:majan/data/model/customer_followUp_response%20.dart';
import 'package:majan/data/model/technican_drop_downforcustomerfollowup.dart';
import 'package:majan/data/model/followup_history_response.dart';
import 'package:majan/data/repositories/api_services.dart';
import 'package:get/get.dart';

class CustomerFollowUpController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();
  
  // Reactive variables for supervisors/technicians
  var isLoading = false.obs;
  var supervisorsList = <Supervisor>[].obs;
  var selectedSupervisor = RxnString();
  
  // Reactive variables for customer follow-up
  var isFollowUpLoading = false.obs;
  var followUpData = Rxn<CustomerFollowUpData>();
  var followUpResponse = Rxn<CustomerFollowUpResponse>();
  var followUpErrorMessage = ''.obs;
  
  // Reactive variables for follow-up history
  var isHistoryLoading = false.obs;
  var followUpHistory = <FollowUpHistoryItem>[].obs;
  var historyErrorMessage = ''.obs;
  
  // Reactive variable for submission
  var isSubmitting = false.obs;
  
  // Add retry mechanism
  var retryCount = 0.obs;
  static const int maxRetries = 3;
  
  // Add cache for supervisors to avoid repeated API calls
  final Map<int, List<Supervisor>> _supervisorsCache = {};

 @override
void onInit() {
  super.onInit();
  // Clear any existing data when controller is initialized
  clearFollowUpHistory();
}
  // Enhanced method to fetch technicians/supervisors by property ID
  Future<void> loadSupervisors(int propertyId) async {
    try {
      isLoading(true);
      followUpErrorMessage('');
      
      // Check cache first
      if (_supervisorsCache.containsKey(propertyId)) {
        supervisorsList.assignAll(_supervisorsCache[propertyId]!);
        return;
      }
      
      final response = await apiService.gettechnicianbyproperty(propertyId);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == true) {
          // Extract technicians list from response
          final technicians = data['data']['technicians'] as List<dynamic>;
          
          // Convert to Supervisor objects
          final supervisorList = technicians.map((tech) => Supervisor.fromJson(tech)).toList();
          
          // Cache the result
          _supervisorsCache[propertyId] = supervisorList;
          
          supervisorsList.assignAll(supervisorList);
          
          // Reset retry count on success
          retryCount.value = 0;
        } else {
          followUpErrorMessage(data['message']['en'] ?? 'Failed to load supervisors');
        }
      } else {
        followUpErrorMessage('Failed to load supervisors: ${response.statusCode}');
      }
    } catch (e) {
      followUpErrorMessage('Error loading supervisors: $e');
      print('Error loading supervisors: $e');
      
      // Implement retry mechanism
      if (retryCount.value < maxRetries) {
        retryCount.value++;
        await Future.delayed(Duration(seconds: 2));
        return loadSupervisors(propertyId);
      }
    } finally {
      isLoading(false);
    }
  }

  // Enhanced method to fetch customer follow-up data by chat ID
  Future<void> loadCustomerFollowUp(String chatId) async {
    try {
      isFollowUpLoading(true);
      followUpErrorMessage('');
      
      final response = await apiService.getcustomerfollowup(chatId);
      
      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['status'] == true) {
          // Parse the response using the model
          final followUpResponse = CustomerFollowUpResponse.fromJson(data);
          this.followUpResponse.value = followUpResponse;
          followUpData.value = followUpResponse.data;
          
          // Reset retry count on success
          retryCount.value = 0;
        } else {
          followUpErrorMessage(data['message']['en'] ?? 'Failed to load follow-up data');
        }
      } else {
        followUpErrorMessage('Failed to load follow-up data: ${response.statusCode}');
      }
    } catch (e) {
      followUpErrorMessage('Error loading follow-up data: $e');
      print('Error loading follow-up data: $e');
      
      // Implement retry mechanism
      if (retryCount.value < maxRetries) {
        retryCount.value++;
        await Future.delayed(Duration(seconds: 2));
        return loadCustomerFollowUp(chatId);
      }
    } finally {
      isFollowUpLoading(false);
    }
  }

  // New method to fetch follow-up history
 Future<void> loadFollowUpHistory(String customerId, String propertyId) async {
  try {
    // Clear previous data when loading new history
    clearFollowUpHistory();
    
    // Validate parameters
    if (customerId.isEmpty || propertyId.isEmpty) {
      historyErrorMessage('Customer ID and Property ID are required');
      isHistoryLoading(false);
      return;
    }

    isHistoryLoading(true);
    historyErrorMessage('');
    
    print('Loading follow-up history for customer: $customerId, property: $propertyId');
    
    final response = await apiService.getFollowupHistory(customerId, propertyId);
    
    print('History Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = response.data;
      print('History Response Data: $data');
      
      if (data['status'] == true) {
        // Parse using the model
        final historyResponse = FollowUpHistoryResponse.fromJson(data);
        
        // Clear and update the list
        followUpHistory.clear();
        followUpHistory.addAll(historyResponse.data);
        
        print('Successfully loaded ${followUpHistory.length} history items');
        
        // Reset retry count on success
        retryCount.value = 0;
      } else {
        final errorMessage = data['message']?['en'] ?? data['message'] ?? 'Failed to load follow-up history';
        historyErrorMessage(errorMessage);
      }
    } else {
      historyErrorMessage('Failed to load follow-up history: ${response.statusCode}');
    }
  } catch (e) {
    final errorMessage = 'Error loading follow-up history: $e';
    historyErrorMessage(errorMessage);
    print(errorMessage);
  } finally {
    isHistoryLoading(false);
  }
}

  // Enhanced method to submit follow-up with better error handling
  Future<bool> submitFollowUp({
    required String customerId,
    required int propertyId,
    required String unitType,
    required String technicianId,
    required int saleStatus,
    required String notes,
  }) async {
    try {
      isSubmitting(true);
      followUpErrorMessage('');
      
      // Validate input data
      if (customerId.isEmpty) {
        followUpErrorMessage('Customer ID is required');
        return false;
      }
      
      if (notes.trim().isEmpty) {
        followUpErrorMessage('Notes are required');
        return false;
      }
      
      final response = await apiService.submitFollowUp(
        customerId: customerId,
        propertyId: propertyId,
        unitType: unitType,
        technicianId: technicianId,
        saleStatus: saleStatus,
        notes: notes,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        if (data['status'] == true) {
          // Clear form data on successful submission
          _clearFormData();
          
          // Reload history after successful submission
          if (propertyId != null) {
            await loadFollowUpHistory(customerId, propertyId.toString());
          }
          
          return true;
        } else {
          followUpErrorMessage(data['message']['en'] ?? 'Failed to submit follow-up');
          return false;
        }
      } else {
        followUpErrorMessage('Failed to submit follow-up: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      followUpErrorMessage('Error submitting follow-up: $e');
      print('Error submitting follow-up: $e');
      return false;
    } finally {
      isSubmitting(false);
    }
  }

  // Method to set selected supervisor with validation
  void setSelectedSupervisor(String? value) {
    selectedSupervisor.value = value;
    
    // Clear any previous errors when supervisor is selected
    if (value != null && value.isNotEmpty) {
      followUpErrorMessage('');
    }
  }

  // Clear supervisors list and cache
  void clearSupervisors() {
    supervisorsList.clear();
    selectedSupervisor.value = null;
  }

  // Clear follow-up data
  void clearFollowUpData() {
    followUpData.value = null;
    followUpResponse.value = null;
    followUpErrorMessage('');
  }
  
  // Clear follow-up history
 void clearFollowUpHistory() {
  followUpHistory.clear();
  historyErrorMessage('');
  isHistoryLoading(false);
}
  
  // Private method to clear form data
  void _clearFormData() {
    selectedSupervisor.value = null;
    followUpErrorMessage('');
  }
  
  // Enhanced helper method to convert status string to integer
  int getStatusValue(String status) {
    switch (status.toLowerCase().trim()) {
      case 'property visit pending':
        return 1;
      case 'property visit scheduled':
        return 2;
      case 'property visited':
        return 3;
      case 'property agreed':
        return 4;
      default:
        return 1;
    }
  }
  
  // Helper method to get status string from integer
  String getStatusString(int statusValue) {
    switch (statusValue) {
      case 1:
        return 'Property Visit Pending';
      case 2:
        return 'Property Visit Scheduled';
      case 3:
        return 'Property Visited';
      case 4:
        return 'Property Agreed';
      default:
        return 'Property Visit Pending';
    }
  }
  
  // Method to validate form data
  String? validateFormData({
    required String? selectedStatus,
    required String? selectedSupervisor,
    required String notes,
  }) {
    if (selectedStatus == null || selectedStatus.isEmpty) {
      return 'Please select a status';
    }
    
    if (selectedStatus == 'Property Visit Scheduled' && 
        (selectedSupervisor == null || selectedSupervisor.isEmpty)) {
      return 'Please select a technician for scheduled visit';
    }
    
    if (notes.trim().isEmpty) {
      return 'Please enter follow-up notes';
    }
    
    if (notes.trim().length < 10) {
      return 'Notes should be at least 10 characters long';
    }
    
    return null; // No validation errors
  }
  
  // Method to refresh all data
  Future<void> refreshData({
    required String chatId, 
    required String customerId,
    required int? propertyId,
  }) async {
    final tasks = [
      loadCustomerFollowUp(chatId),
      if (propertyId != null) loadSupervisors(propertyId),
      if (propertyId != null) loadFollowUpHistory(customerId, propertyId.toString()),
    ];
    
    await Future.wait(tasks.whereType<Future<void>>());
  }
  
  // Method to refresh only history
  Future<void> refreshHistory(String customerId, String propertyId) async {
    await loadFollowUpHistory(customerId, propertyId);
  }
  
  // Get sorted history (newest first)
  List<FollowUpHistoryItem> get sortedHistory {
    return followUpHistory.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  // Get history by status
  List<FollowUpHistoryItem> getHistoryByStatus(int status) {
    return followUpHistory.where((item) => item.saleStatus == status).toList();
  }
  
  // Get latest follow-up entry
  FollowUpHistoryItem? get latestFollowUp {
    if (followUpHistory.isEmpty) return null;
    return sortedHistory.first;
  }
  
  // Method to clear cache
  void clearCache() {
    _supervisorsCache.clear();
  }
  
  @override
  void onClose() {
    // Clean up resources
    clearCache();
    super.onClose();
  }
}