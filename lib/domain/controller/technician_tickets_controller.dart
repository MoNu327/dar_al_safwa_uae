import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/technican_list_model.dart';
import 'package:dar_al_safwa/data/model/technican_summary_model.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart'; // ADD THIS IMPORT
import 'package:intl/intl.dart';
import '../../../../data/model/technician_complaints_response.dart';
import '../../../../data/model/technican_ticket_view_model.dart';

class TechnicianTicketsController extends GetxController {
  var isLoading = false.obs;
  var tickets = <Complaint>[].obs;
  var selectedTicket = Rxn<TicketModel>();
  
  // ✅ Assignment state management
  final RxMap<String, bool> isAssigningMap = <String, bool>{}.obs;
  final RxMap<String, String> assignedTechnicianIds = <String, String>{}.obs;
  final RxMap<String, String> assignedTechnicianNames = <String, String>{}.obs;
  final RxMap<String, String> selectedTechnicianIds = <String, String>{}.obs;
  final RxMap<String, bool> showAssignmentSection = <String, bool>{}.obs;
  
  final RxList<Map<String, dynamic>> availableTechnicians = <Map<String, dynamic>>[].obs;
  RxList<Complaint> ticket = <Complaint>[].obs;
  var filteredTickets = <Complaint>[].obs;
  final Rx<ComplaintStatisticsResponse?> technicianStats = Rx<ComplaintStatisticsResponse?>(null);
  final RxBool isStatsLoading = false.obs;
  final RxString statsErrorMessage = ''.obs;

  final ApiClient apiClient = ApiClient();
  
  // 🆕 ADD: GetStorage instance
  final GetStorage _storage = GetStorage();

  // ✅ Initialize controller and load data
  @override
  void onInit() {
    super.onInit();
    debugPrint("🚀 TechnicianTicketsController onInit called");
    _initializeController();
  }

  // 🆕 ADD: Initialize controller with proper data loading sequence
  Future<void> _initializeController() async {
    try {
      // Load assignments from storage first
      await _loadAssignmentsFromStorage();
      
      // Then load technicians
      await getAvailableTechnicians();
      
      debugPrint("✅ Controller initialization complete");
    } catch (e) {
      debugPrint("❌ Error initializing controller: $e");
    }
  }

  @override
  void onClose() {
    debugPrint("🔄 TechnicianTicketsController onClose called");
    // Don't clear assignment data on close - keep it persistent
    super.onClose();
  }

  // ✅ UPDATED: Enhanced assignment method with persistent storage
  Future<void> assignTechnicianWithoutRemoval(String complaintId, String technicianId) async {
    debugPrint("🔄 Assigning technician: $technicianId to complaint: $complaintId");
    try {
      setAssigning(complaintId, true);

      final userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid == null) {
        debugPrint("❌ User UID is null");
        throw Exception('User not logged in');
      }

      final response = await apiClient.request(
        "complaints/escalate",
        method: "post",
        data: {
          "complaint_id": complaintId,
          "technician_uid": technicianId,
          "user_uid": userUid,
        },
      );
      
      debugPrint("📡 Escalate API Status: ${response.statusCode}");
      debugPrint("📥 Escalate API Response: ${response.data}");
      
      if (response.data['success'] == true) {
        // Update assignment state
        await _updateAssignmentState(complaintId, technicianId);
        debugPrint("✅ Technician assigned successfully");
      } else {
        final errorMsg = response.data['message']?['en'] ?? 'Assignment failed';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint("❌ Assignment error: $e");
      rethrow;
    } finally {
      setAssigning(complaintId, false);
    }
  }

  // 🆕 UPDATED: Enhanced assignment state update with persistent storage
  Future<void> _updateAssignmentState(String complaintId, String technicianId) async {
    try {
      // Find technician info
      final tech = availableTechnicians.firstWhere(
        (t) => t['id'] == technicianId,
        orElse: () => {'id': technicianId, 'name': 'Unknown Technician'},
      );
      
      final technicianName = tech['name'] ?? 'Unknown Technician';
      
      // Update local state
      assignedTechnicianIds[complaintId] = technicianId;
      assignedTechnicianNames[complaintId] = technicianName;
      
      // 🆕 Save to persistent storage
      await _saveAssignmentToStorage(complaintId, technicianId, technicianName);
      
      // Clear UI state
      selectedTechnicianIds.remove(complaintId);
      showAssignmentSection[complaintId] = false;
      
      // Update ticket in the list
      _updateTicketInList(complaintId, technicianId, technicianName);
      
      // Force UI refresh
      tickets.refresh();
      filteredTickets.refresh();
      
      debugPrint("✅ Assignment state updated and saved for $complaintId");
    } catch (e) {
      debugPrint("❌ Error updating assignment state: $e");
    }
  }

  // 🆕 IMPLEMENTED: Save assignment to persistent storage using GetStorage
  Future<void> _saveAssignmentToStorage(String complaintId, String technicianId, String technicianName) async {
    try {
      final assignmentData = {
        'technicianId': technicianId,
        'technicianName': technicianName,
        'assignedAt': DateTime.now().toIso8601String(),
      };
      
      await _storage.write('assigned_technician_$complaintId', assignmentData);
      
      debugPrint("💾 Assignment saved to storage: $complaintId -> $technicianName");
    } catch (e) {
      debugPrint("❌ Failed to save assignment to storage: $e");
    }
  }

  // 🆕 IMPLEMENTED: Load assignments from persistent storage using GetStorage
  Future<void> _loadAssignmentsFromStorage() async {
    try {
      // Get all stored assignments
      final allKeys = _storage.getKeys();
      final assignmentKeys = allKeys.where((key) => key.startsWith('assigned_technician_')).toList();
      
      debugPrint("📂 Found ${assignmentKeys.length} stored assignments");
      
      for (final key in assignmentKeys) {
        try {
          final complaintId = key.replaceFirst('assigned_technician_', '');
          final assignmentData = _storage.read(key);
          
          if (assignmentData != null && assignmentData is Map) {
            assignedTechnicianIds[complaintId] = assignmentData['technicianId'] ?? '';
            assignedTechnicianNames[complaintId] = assignmentData['technicianName'] ?? 'Unknown Technician';
            
            debugPrint("📂 Loaded assignment: $complaintId -> ${assignmentData['technicianName']}");
          }
        } catch (e) {
          debugPrint("❌ Error loading assignment for key $key: $e");
        }
      }
      
      debugPrint("✅ Loaded ${assignedTechnicianIds.length} assignments from storage");
    } catch (e) {
      debugPrint("❌ Failed to load assignments from storage: $e");
    }
  }

  // ✅ UPDATED: Enhanced ticket fetching with assignment restoration
  Future<void> fetchTickets(String userId) async {
    try {
      debugPrint("🔄 Fetching tickets for user: $userId");
      isLoading.value = true;
      
      // Load assignments from storage before fetching tickets
      await _loadAssignmentsFromStorage();
      
      tickets.clear();
      filteredTickets.clear();

      final response = await apiClient.request(
        "technician/complaints",
        method: "post",
        data: {"uid": userId},
      );

      debugPrint("📡 Fetch tickets response status: ${response.statusCode}");

      final data = response.data;
      if (data == null) {
        debugPrint("⚠️ API returned null response");
        return;
      }

      List<Complaint> complaints = [];

      if (data is List) {
        complaints = data
            .whereType<Map<String, dynamic>>()
            .map(Complaint.fromJson)
            .toList();
      } else if (data is Map<String, dynamic>) {
        final bool ok = TechnicianComplaintsResponse.statusFromJson(data['status']);
        
        if (ok) {
          final dynamic inner = data['data'];
          if (inner is List) {
            complaints = inner
                .whereType<Map<String, dynamic>>()
                .map(Complaint.fromJson)
                .toList();
          }
        }
      }

      if (complaints.isNotEmpty) {
        tickets.addAll(complaints);
        filteredTickets.addAll(complaints);
        
        // Apply stored assignments to tickets
        _applyStoredAssignments();
        
        debugPrint("✅ Fetched ${tickets.length} tickets with ${assignedTechnicianIds.length} assignments restored");
      }
      
    } catch (e, st) {
      debugPrint("❌ Error fetching tickets: $e");
      debugPrint(st.toString());
      tickets.clear();
      filteredTickets.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // 🆕 ADD: Apply stored assignments to fetched tickets
  void _applyStoredAssignments() {
    for (int i = 0; i < tickets.length; i++) {
      final complaint = tickets[i];
      final complaintId = complaint.complaintId;
      
      // Check if we have stored assignment for this ticket
      final storedTechId = assignedTechnicianIds[complaintId];
      final storedTechName = assignedTechnicianNames[complaintId];
      
      if (storedTechId != null && storedTechName != null && storedTechId.isNotEmpty) {
        // Update the complaint object with stored assignment info
        try {
          tickets[i] = complaint.copyWith(
            assignedTechnicianId: storedTechId,
            assignedTechnicianName: storedTechName,
            status: complaint.status == 'pending' ? 'Assigned' : complaint.status,
          );
          
          debugPrint("🔄 Applied stored assignment to ticket $complaintId: $storedTechName");
        } catch (e) {
          debugPrint("❌ Error applying assignment to ticket $complaintId: $e");
          // If copyWith fails, at least keep the assignment in memory
          debugPrint("ℹ️ Assignment kept in memory for $complaintId");
        }
      }
    }
    
    // Update filtered tickets as well
    filteredTickets.assignAll(tickets);
  }

  // 🆕 ADD: Update ticket in list helper method
  void _updateTicketInList(String complaintId, String technicianId, String technicianName) {
    try {
      for (int i = 0; i < tickets.length; i++) {
        if (tickets[i].complaintId == complaintId) {
          tickets[i] = tickets[i].copyWith(
            assignedTechnicianId: technicianId,
            assignedTechnicianName: technicianName,
            status: tickets[i].status == 'pending' ? 'Assigned' : tickets[i].status,
          );
          break;
        }
      }
      
      // Update filtered tickets
      for (int i = 0; i < filteredTickets.length; i++) {
        if (filteredTickets[i].complaintId == complaintId) {
          filteredTickets[i] = filteredTickets[i].copyWith(
            assignedTechnicianId: technicianId,
            assignedTechnicianName: technicianName,
            status: filteredTickets[i].status == 'pending' ? 'Assigned' : filteredTickets[i].status,
          );
          break;
        }
      }
    } catch (e) {
      debugPrint("❌ Error updating ticket in list: $e");
      // If copyWith fails, the assignment is still in memory and will show in UI
    }
  }

  // ✅ UPDATED: Clear assignment with storage cleanup
  Future<void> clearAssignment(String complaintId) async {
    assignedTechnicianIds.remove(complaintId);
    assignedTechnicianNames.remove(complaintId);
    selectedTechnicianIds.remove(complaintId);
    showAssignmentSection.remove(complaintId);
    
    // Remove from persistent storage
    try {
      await _storage.remove('assigned_technician_$complaintId');
      debugPrint("🗑️ Cleared assignment from storage for: $complaintId");
    } catch (e) {
      debugPrint("❌ Failed to clear assignment from storage: $e");
    }
    
    // Update UI
    tickets.refresh();
    filteredTickets.refresh();
  }

  // 🆕 ADD: Method to get all stored assignments (for debugging)
  void debugStoredAssignments() {
    debugPrint("🔍 Current stored assignments:");
    for (final entry in assignedTechnicianIds.entries) {
      debugPrint("  ${entry.key} -> ${assignedTechnicianNames[entry.key]} (${entry.value})");
    }
  }

  // Rest of your existing methods remain the same...
  
  void applyFilters({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    List<Complaint> result = List.from(tickets);

    if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
      final normalizedSelectedStatus = status.toLowerCase().trim();
      
      result = result.where((tickets) {
        final ticketStatus = tickets.statusText.en?.toLowerCase().trim() ?? '';
        debugPrint("🔍 Status Filter: Comparing '$normalizedSelectedStatus' vs '$ticketStatus'");
        
        switch (normalizedSelectedStatus) {
          case 'pending':
            return ticketStatus == 'pending' || 
                   ticketStatus.contains('pend') ||
                   ticketStatus.contains('open');
          case 'in progress':
            return ticketStatus.contains('progress') || 
                   ticketStatus.contains('progres') ||
                   ticketStatus.contains('processing') ||
                   ticketStatus.contains('in-progress');
          case 'resolved':
            return ticketStatus.contains('resolve') ||
                   ticketStatus.contains('complete') ||
                   ticketStatus.contains('closed') ||
                   ticketStatus.contains('finished');
          default:
            return ticketStatus == normalizedSelectedStatus;
        }
      }).toList();
    }

    if (startDate != null || endDate != null) {
      result = result.where((tickets) {
        try {
          final ticketDate = _parseTicketDate(tickets.lastUpdated ?? tickets.lastUpdated);
          if (ticketDate == null) {
            debugPrint("⚠️ Could not parse date for ticket ${tickets.complaintId}");
            return false;
          }

          final ticketDateOnly = DateTime(ticketDate.year, ticketDate.month, ticketDate.day);
          final startDateOnly = startDate != null 
              ? DateTime(startDate.year, startDate.month, startDate.day)
              : DateTime(1900);
          final endDateOnly = endDate != null
              ? DateTime(endDate.year, endDate.month, endDate.day)
              : DateTime(2100);

          return (ticketDateOnly.isAtSameMomentAs(startDateOnly) || 
                  ticketDateOnly.isAfter(startDateOnly)) &&
                 (ticketDateOnly.isAtSameMomentAs(endDateOnly) || 
                  ticketDateOnly.isBefore(endDateOnly));
        } catch (e) {
          debugPrint("❌ Error filtering by date for ticket ${tickets.complaintId}: $e");
          return false;
        }
      }).toList();
    }

    filteredTickets.assignAll(result);
    debugPrint("✅ Applied filters. ${filteredTickets.length} tickets match criteria.");
  }

  DateTime? _parseTicketDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    final cleanDateString = dateString.trim().replaceAll(RegExp(r'[+-]\d{2}:?\d{2}$'), '');

    final possibleFormats = [
      "yyyy-MM-dd HH:mm:ss",
      "yyyy-MM-ddTHH:mm:ss",
      "yyyy-MM-dd",
      "dd-MM-yyyy HH:mm:ss",
      "MM/dd/yyyy HH:mm:ss",
      "yyyy/MM/dd HH:mm:ss",
      "EEE, dd MMM yyyy HH:mm:ss",
    ];

    for (final format in possibleFormats) {
      try {
        return DateFormat(format).parse(cleanDateString);
      } catch (e) {
        continue;
      }
    }

    try {
      return DateTime.parse(cleanDateString);
    } catch (e) {
      debugPrint("❌ Failed to parse date: '$dateString'");
      return null;
    }
  }

  // Keep all your other existing methods...
  
  Future<void> getSummaryForTechnician(String uid) async {
    isStatsLoading.value = true;
    statsErrorMessage.value = '';
    technicianStats.value = null;
    
    try {
      final response = await apiClient.request(
        "Technician/PropertyStats",
        method: "post",
        data: {"technician_id": uid},
      );
      
      if (response.data['success'] == true) {
        technicianStats.value = ComplaintStatisticsResponse.fromJson(response.data);
        final propertyCount = technicianStats.value?.data?.propertyStats.length ?? 0;
        debugPrint('Technician stats loaded: $propertyCount properties');
      } else {
        String errorMessage = 'Failed to load technician statistics';
        
        if (response.data['message'] != null) {
          final messageData = response.data['message'];
          if (messageData is Map && messageData['en'] != null) {
            errorMessage = messageData['en'].toString();
          } else if (messageData is String) {
            errorMessage = messageData;
          } else {
            errorMessage = messageData.toString();
          }
        }
        
        statsErrorMessage.value = errorMessage;
      }
    } catch (e) {
      statsErrorMessage.value = 'Error loading technician stats: $e';
      debugPrint('Exception in getSummaryForTechnician: $e');
    } finally {
      isStatsLoading.value = false;
    }
  }

  Future<void> getAvailableTechnicians() async {
    try {
      debugPrint("🔄 Starting technician fetch...");
      isLoading.value = true;

      availableTechnicians.clear();

      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      debugPrint("🧑‍💻 Current User UID (to exclude): $currentUid");

      final response = await apiClient.request(
        "technicians/except",
        method: "post",
        data: {"exclude_uid": currentUid},
      );

      debugPrint("📡 Response received: ${response.statusCode}");

      if (response.statusCode == 200) {
        final parsedResponse = TechnicianDropdownResponse.fromJson(response.data);
        
        if (parsedResponse.success) {
          final techniciansList = parsedResponse.data.technicians.map((tech) => {
            'id': tech.uid,
            'name': tech.fullName,
          }).toList();

          availableTechnicians.assignAll(techniciansList);
          debugPrint("📋 Loaded ${techniciansList.length} available technicians");
        }
      }
    } catch (e) {
      debugPrint("❌ Error fetching technicians: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> assignTechnician(String complaintId, String technicianId) async {
    try {
      await assignTechnicianWithoutRemoval(complaintId, technicianId);
      
      Get.snackbar(
        '✅ Success', 
        'Technician assigned successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      debugPrint("❌ Assignment error: $e");
      Get.snackbar(
        'Error', 
        'Failed to assign technician: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  bool isTicketAssigned(String complaintId) {
    return assignedTechnicianIds.containsKey(complaintId);
  }

  String? getAssignedTechnicianName(String complaintId) {
    return assignedTechnicianNames[complaintId];
  }

  Future<void> fetchComplaintDetails(String complaintId) async {
    try {
      isLoading.value = true;

      final response = await apiClient.request(
        "complaint-detailscopy",
        method: "post",
        data: {"complaint_id": complaintId},
      );

      if (response.data['success'] == true) {
        selectedTicket.value = TicketModel.fromJson(response.data['data']);
        debugPrint("✅ Ticket details fetched: ${selectedTicket.value?.complaintNumber}");
      }
    } catch (e) {
      debugPrint("❌ Error fetching complaint details: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void setAssigning(String complaintId, bool value) {
    if (isAssigningMap[complaintId] == value) return;
    isAssigningMap[complaintId] = value;
    debugPrint("🔄 Setting assignment state for $complaintId: $value");
  }
}