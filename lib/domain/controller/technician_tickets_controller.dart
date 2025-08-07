  // FIXED VERSION - Prevents assigned tickets from being removed
  import 'package:dar_al_safwa/data/datasources/api_client.dart';
  import 'package:dar_al_safwa/data/model/technican_list_model.dart';
  import 'package:dar_al_safwa/data/model/technican_summary_model.dart';
  import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
  import 'package:dio/dio.dart';
  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:get_storage/get_storage.dart';
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
    
    // 🆕 Store assigned tickets to prevent removal
    final RxMap<String, Complaint> localAssignedTickets = <String, Complaint>{}.obs;
    
    final RxList<Map<String, dynamic>> availableTechnicians = <Map<String, dynamic>>[].obs;
    RxList<Complaint> ticket = <Complaint>[].obs;
    var filteredTickets = <Complaint>[].obs;
    final Rx<ComplaintStatisticsResponse?> technicianStats = Rx<ComplaintStatisticsResponse?>(null);
    final RxBool isStatsLoading = false.obs;
    final RxString statsErrorMessage = ''.obs;

    final ApiClient apiClient = ApiClient();
    final GetStorage _storage = GetStorage();

    @override
void onInit() {
  super.onInit();
  debugPrint("🚀 TechnicianTicketsController onInit called");
  _initializeController();
}

Future<void> _initializeController() async {
  try {
    // Load assignments and assigned tickets from storage first
    await _loadAssignmentsFromStorage();
    await _loadAssignedTicketsFromStorage();
    
    // Then load technicians
    await getAvailableTechnicians();
    
    // Get current user and fetch tickets
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await fetchTickets(currentUser.uid);
      debugTicketVisibility(); // Debug the ticket state
    }
    
    debugPrint("✅ Controller initialization complete");
  } catch (e) {
    debugPrint("❌ Error initializing controller: $e");
  }
}

    @override
    void onClose() {
      debugPrint("🔄 TechnicianTicketsController onClose called");
      super.onClose();
    }

    // ✅ UPDATED: Enhanced assignment method with ticket preservation
    Future<void> assignTechnicianWithoutRemoval(String complaintId, String technicianId) async {
      debugPrint("🔄 Assigning technician: $technicianId to complaint: $complaintId");
      try {
        setAssigning(complaintId, true);

        final userUid = FirebaseAuth.instance.currentUser?.uid;
        if (userUid == null) {
          debugPrint("❌ User UID is null");
          throw Exception('User not logged in');
        }

        // 🆕 Store the ticket before assignment to prevent loss
        final ticketToAssign = tickets.firstWhere(
          (ticket) => ticket.complaintId == complaintId,
          orElse: () => filteredTickets.firstWhere(
            (ticket) => ticket.complaintId == complaintId,
          ),
        );

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
          // 🆕 Store the original ticket before updating assignment state
          await _saveAssignedTicketToStorage(complaintId, ticketToAssign);
          
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

    // 🆕 UPDATED: Enhanced assignment state update with ticket preservation
    Future<void> _updateAssignmentState(String complaintId, String technicianId) async {
      try {
        // Find technician info
        final tech = availableTechnicians.firstWhere(
          (t) => t['id'] == technicianId,
          orElse: () => {'id': technicianId, 'name': 'Unknown Technician'},
        );
        
        final technicianName = tech['name'] ?? 'Unknown Technician';
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null) {
          await getSummaryForTechnician(currentUserId);
          debugPrint("✅ Refreshed technician stats after reassignment");
        }
        
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

    // 🆕 Save assigned ticket to storage to prevent removal during API refresh
    Future<void> _saveAssignedTicketToStorage(String complaintId, Complaint ticket) async {
      try {
        // Store the full ticket data
        localAssignedTickets[complaintId] = ticket;
        
        // Convert ticket to JSON and save to persistent storage
        final ticketJson = ticket.toJson();
        await _storage.write('assigned_ticket_$complaintId', ticketJson);
        
        debugPrint("💾 Assigned ticket saved to storage: $complaintId");
      } catch (e) {
        debugPrint("❌ Failed to save assigned ticket to storage: $e");
      }
    }

    // 🆕 Load assigned tickets from storage
    Future<void> _loadAssignedTicketsFromStorage() async {
      try {
        final allKeys = _storage.getKeys();
        final List<String> keysList = [];
        
        for (final key in allKeys) {
          if (key is String && key.startsWith('assigned_ticket_')) {
            keysList.add(key);
          }
        }
        
        debugPrint("📂 Found ${keysList.length} stored assigned tickets");
        
        for (final key in keysList) {
          try {
            final complaintId = key.replaceFirst('assigned_ticket_', '');
            final ticketData = _storage.read(key);
            
            if (ticketData != null && ticketData is Map<String, dynamic>) {
              final ticket = Complaint.fromJson(ticketData);
              localAssignedTickets[complaintId] = ticket;
              
              debugPrint("📂 Loaded assigned ticket: $complaintId");
            }
          } catch (e) {
            debugPrint("❌ Error loading assigned ticket for key $key: $e");
          }
        }
        
        debugPrint("✅ Loaded ${localAssignedTickets.length} assigned tickets from storage");
      } catch (e) {
        debugPrint("❌ Failed to load assigned tickets from storage: $e");
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

    // 🔧 FIXED: Load assignments from persistent storage using GetStorage
    Future<void> _loadAssignmentsFromStorage() async {
      try {
        final allKeys = _storage.getKeys();
        final List<String> keysList = [];
        
        for (final key in allKeys) {
          if (key is String && key.startsWith('assigned_technician_')) {
            keysList.add(key);
          }
        }
        
        debugPrint("📂 Found ${keysList.length} stored assignments");
        
        for (final key in keysList) {
          try {
            final complaintId = key.replaceFirst('assigned_technician_', '');
            final assignmentData = _storage.read(key);
            
            if (assignmentData != null && assignmentData is Map) {
              final technicianId = assignmentData['technicianId']?.toString() ?? '';
              final technicianName = assignmentData['technicianName']?.toString() ?? 'Unknown Technician';
              
              if (technicianId.isNotEmpty) {
                assignedTechnicianIds[complaintId] = technicianId;
                assignedTechnicianNames[complaintId] = technicianName;
                
                debugPrint("📂 Loaded assignment: $complaintId -> $technicianName");
              }
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

    // 🔧 MAJOR FIX: Enhanced ticket fetching that preserves assigned tickets
  // FIXED VERSION - Properly shows assigned tickets
// 🆕 SOLUTION: Fetch both unassigned and assigned tickets
Future<void> fetchTickets(String userId) async {
  try {
    debugPrint("🔄 Fetching ALL tickets for user: $userId");
    isLoading.value = true;
    
    // Load assignments and assigned tickets BEFORE clearing
    await _loadAssignmentsFromStorage();
    await _loadAssignedTicketsFromStorage();

    // 🆕 Fetch both unassigned and assigned tickets
    final List<Complaint> allComplaints = [];
    
    try {
      // 1. Get unassigned tickets (current API)
      final unassignedTickets = await _fetchUnassignedTickets(userId);
      debugPrint("📥 Unassigned tickets: ${unassignedTickets.length}");
      allComplaints.addAll(unassignedTickets);
      
      // 2. Get assigned tickets for this technician
      final assignedTickets = await _fetchAssignedTickets(userId);
      debugPrint("📥 Assigned tickets: ${assignedTickets.length}");
      allComplaints.addAll(assignedTickets);
      
    } catch (e) {
      debugPrint("❌ Error fetching tickets from API: $e");
      // If API fails, show locally stored tickets
      _showLocallyAssignedTicketsOnly();
      return;
    }

    debugPrint("📥 Total API tickets: ${allComplaints.length}");

    // Merge with locally assigned tickets
    final mergedComplaints = _mergeWithLocallyAssignedTickets(allComplaints);
    debugPrint("🔄 After merge: ${mergedComplaints.length} tickets");
    
    // Apply stored assignments to all tickets
    final updatedComplaints = _applyStoredAssignmentsToComplaints(mergedComplaints);
    debugPrint("✅ After applying assignments: ${updatedComplaints.length} tickets");
    
    // Clear and update lists
    tickets.clear();
    filteredTickets.clear();
    tickets.addAll(updatedComplaints);
    filteredTickets.addAll(updatedComplaints);
    
    // Debug output
    debugPrint("✅ Final ticket count: ${tickets.length}");
    debugPrint("📊 Should match stats total: 14");
    
    // Log each ticket for debugging
    for (int i = 0; i < tickets.length; i++) {
      final ticket = tickets[i];
      final isAssigned = assignedTechnicianIds.containsKey(ticket.complaintId) || 
                        ticket.assignedTechnicianId?.isNotEmpty == true;
      debugPrint("🎫 Ticket ${i + 1}: ${ticket.complaintId} - Status: ${ticket.status} - Assigned: $isAssigned");
    }
    
  } catch (e, st) {
    debugPrint("❌ Error fetching tickets: $e");
    debugPrint(st.toString());
    _showLocallyAssignedTicketsOnly();
  } finally {
    isLoading.value = false;
  }
}

// 🆕 Fetch unassigned tickets (current API call)
Future<List<Complaint>> _fetchUnassignedTickets(String userId) async {
  try {
    final response = await apiClient.request(
      "technician/complaints", // Current API - returns unassigned tickets
      method: "post",
      data: {"uid": userId},
    );

    debugPrint("📡 Unassigned tickets response status: ${response.statusCode}");

    final data = response.data;
    if (data == null) {
      debugPrint("⚠️ Unassigned tickets API returned null response");
      return [];
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

    return complaints;
  } catch (e) {
    debugPrint("❌ Error fetching unassigned tickets: $e");
    return [];
  }
}

// 🆕 Fetch assigned tickets for this technician
Future<List<Complaint>> _fetchAssignedTickets(String userId) async {
  try {
    // Option 1: Try a different API endpoint for assigned tickets
    try {
      final response = await apiClient.request(
        "technician/assigned-complaints", // Try this endpoint first
        method: "post",
        data: {"technician_uid": userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseComplaintsFromResponse(response.data, "assigned tickets API");
      }
    } catch (e) {
      debugPrint("ℹ️ assigned-complaints endpoint not available: $e");
    }

    // Option 2: Try getting all tickets for this technician
    try {
      final response = await apiClient.request(
        "technician/all-complaints", // Try this endpoint
        method: "post",
        data: {"technician_uid": userId},
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseComplaintsFromResponse(response.data, "all tickets API");
      }
    } catch (e) {
      debugPrint("ℹ️ all-complaints endpoint not available: $e");
    }

    // Option 3: Try getting tickets with a different parameter
    try {
      final response = await apiClient.request(
        "technician/complaints",
        method: "post",
        data: {
          "uid": userId,
          "include_assigned": true, // Try adding this parameter
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final tickets = _parseComplaintsFromResponse(response.data, "complaints with include_assigned");
        // Filter out tickets we already have from unassigned call
        return tickets.where((ticket) => 
          ticket.assignedTechnicianId?.isNotEmpty == true
        ).toList();
      }
    } catch (e) {
      debugPrint("ℹ️ include_assigned parameter not supported: $e");
    }

    debugPrint("⚠️ No assigned tickets API available - will rely on local storage");
    return [];
    
  } catch (e) {
    debugPrint("❌ Error fetching assigned tickets: $e");
    return [];
  }
}

// 🆕 Helper method to parse complaints from API response
List<Complaint> _parseComplaintsFromResponse(dynamic data, String source) {
  try {
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

    debugPrint("📥 Parsed ${complaints.length} tickets from $source");
    return complaints;
  } catch (e) {
    debugPrint("❌ Error parsing complaints from $source: $e");
    return [];
  }
}

// 🆕 ENHANCED: Better merge logic to avoid duplicates
List<Complaint> _mergeWithLocallyAssignedTickets(List<Complaint> apiComplaints) {
  final Map<String, Complaint> mergedTickets = {};
  
  debugPrint("🔄 Starting enhanced merge process...");
  debugPrint("📥 API complaints: ${apiComplaints.length}");
  debugPrint("💾 Local assigned tickets: ${localAssignedTickets.length}");
  
  // First, add all API tickets (avoid duplicates by using Map)
  for (final complaint in apiComplaints) {
    mergedTickets[complaint.complaintId] = complaint;
    debugPrint("📥 Added API ticket: ${complaint.complaintId}");
  }
  
  // Then, add locally assigned tickets that might not be in API response
  for (final entry in localAssignedTickets.entries) {
    final complaintId = entry.key;
    final localTicket = entry.value;
    
    // Always include locally assigned tickets, prioritizing local version if conflict
    if (assignedTechnicianIds.containsKey(complaintId)) {
      mergedTickets[complaintId] = localTicket;
      debugPrint("💾 Added/Updated locally assigned ticket: $complaintId");
    }
  }
  
  final result = mergedTickets.values.toList();
  debugPrint("✅ Enhanced merge complete: ${result.length} total unique tickets");
  return result;
}

// 🆕 IMPROVED: Better merge logic
// List<Complaint> _mergeWithLocallyAssignedTickets(List<Complaint> apiComplaints) {
//   final Map<String, Complaint> mergedTickets = {};
  
//   debugPrint("🔄 Starting merge process...");
//   debugPrint("📥 API complaints: ${apiComplaints.length}");
//   debugPrint("💾 Local assigned tickets: ${localAssignedTickets.length}");
  
//   // First, add all API tickets
//   for (final complaint in apiComplaints) {
//     mergedTickets[complaint.complaintId] = complaint;
//     debugPrint("📥 Added API ticket: ${complaint.complaintId}");
//   }
  
//   // Then, add locally assigned tickets that might not be in API response
//   for (final entry in localAssignedTickets.entries) {
//     final complaintId = entry.key;
//     final localTicket = entry.value;
    
//     // Always include locally assigned tickets, even if not in API response
//     if (assignedTechnicianIds.containsKey(complaintId)) {
//       mergedTickets[complaintId] = localTicket;
//       debugPrint("💾 Added/Updated locally assigned ticket: $complaintId");
//     }
//   }
  
//   final result = mergedTickets.values.toList();
//   debugPrint("✅ Merge complete: ${result.length} total tickets");
//   return result;
// }

// 🆕 IMPROVED: Better fallback when API fails
void _showLocallyAssignedTicketsOnly() {
  try {
    debugPrint("🔄 Showing locally assigned tickets only...");
    final assignedTickets = <Complaint>[];
    
    for (final entry in localAssignedTickets.entries) {
      final complaintId = entry.key;
      if (assignedTechnicianIds.containsKey(complaintId)) {
        assignedTickets.add(entry.value);
        debugPrint("💾 Including assigned ticket: $complaintId");
      }
    }
    
    if (assignedTickets.isNotEmpty) {
      final updatedComplaints = _applyStoredAssignmentsToComplaints(assignedTickets);
      tickets.assignAll(updatedComplaints);
      filteredTickets.assignAll(updatedComplaints);
      
      debugPrint("✅ Showing ${assignedTickets.length} locally assigned tickets");
    } else {
      debugPrint("⚠️ No locally assigned tickets found");
      tickets.clear();
      filteredTickets.clear();
    }
  } catch (e) {
    debugPrint("❌ Error showing locally assigned tickets: $e");
    tickets.clear();
    filteredTickets.clear();
  }
}

// 🆕 ADD: Debug method to check ticket visibility
void debugTicketVisibility() {
  debugPrint("🔍 TICKET VISIBILITY DEBUG:");
  debugPrint("📊 Stats show: 14 total, 12 active, 2 resolved");
  debugPrint("🎫 UI shows: ${tickets.length} tickets");
  debugPrint("💾 Assigned tickets in storage: ${assignedTechnicianIds.length}");
  debugPrint("📥 Local assigned tickets: ${localAssignedTickets.length}");
  
  debugPrint("\n📋 Assignment Details:");
  for (final entry in assignedTechnicianIds.entries) {
    final complaintId = entry.key;
    final techName = assignedTechnicianNames[complaintId] ?? 'Unknown';
    final hasLocalTicket = localAssignedTickets.containsKey(complaintId);
    final inCurrentList = tickets.any((t) => t.complaintId == complaintId);
    
    debugPrint("  $complaintId -> $techName (Local: $hasLocalTicket, InList: $inCurrentList)");
  }
  
  debugPrint("\n🎫 Current Tickets in UI:");
  for (int i = 0; i < tickets.length; i++) {
    final ticket = tickets[i];
    final isAssigned = assignedTechnicianIds.containsKey(ticket.complaintId);
    debugPrint("  ${i + 1}. ${ticket.complaintId} - ${ticket.status} - Assigned: $isAssigned");
  }
}
    // 🔧 Apply stored assignments to complaints before adding to lists
    List<Complaint> _applyStoredAssignmentsToComplaints(List<Complaint> complaints) {
      final updatedComplaints = <Complaint>[];
      
      for (final complaint in complaints) {
        final complaintId = complaint.complaintId;
        final storedTechId = assignedTechnicianIds[complaintId];
        final storedTechName = assignedTechnicianNames[complaintId];
        
        if (storedTechId != null && storedTechName != null && storedTechId.isNotEmpty) {
          try {
            // Create updated complaint with assignment info
            final updatedComplaint = complaint.copyWith(
              assignedTechnicianId: storedTechId,
              assignedTechnicianName: storedTechName,
              status: complaint.status == 'pending' ? 'Assigned' : complaint.status,
            );
            
            updatedComplaints.add(updatedComplaint);
            debugPrint("🔄 Applied stored assignment to complaint $complaintId: $storedTechName");
          } catch (e) {
            debugPrint("❌ Error applying assignment to complaint $complaintId: $e");
            updatedComplaints.add(complaint);
          }
        } else {
          updatedComplaints.add(complaint);
        }
      }
      
      return updatedComplaints;
    }

    // ✅ UPDATED: Clear assignment with complete cleanup
    Future<void> clearAssignment(String complaintId) async {
      assignedTechnicianIds.remove(complaintId);
      assignedTechnicianNames.remove(complaintId);
      selectedTechnicianIds.remove(complaintId);
      showAssignmentSection.remove(complaintId);
      
      // 🆕 Remove from local assigned tickets
      localAssignedTickets.remove(complaintId);
      
      try {
        await _storage.remove('assigned_technician_$complaintId');
        await _storage.remove('assigned_ticket_$complaintId');
        debugPrint("🗑️ Cleared assignment and ticket from storage for: $complaintId");
      } catch (e) {
        debugPrint("❌ Failed to clear assignment from storage: $e");
      }
      
      tickets.refresh();
      filteredTickets.refresh();
    }

    // Rest of the existing methods remain the same...
    Future<void> refreshAllData(String userId) async {
      try {
        debugPrint("🔄 Starting complete data refresh for user: $userId");
        
        final previousTickets = List<Complaint>.from(tickets);
        final previousStats = technicianStats.value;
        
        try {
          await fetchTickets(userId);
          debugPrint("✅ Tickets refreshed successfully");
        } catch (ticketError) {
          debugPrint("❌ Error refreshing tickets: $ticketError");
          if (tickets.isEmpty && previousTickets.isNotEmpty) {
            tickets.assignAll(previousTickets);
            filteredTickets.assignAll(previousTickets);
          }
        }
        
        try {
          await getSummaryForTechnician(userId);
          debugPrint("✅ Summary refreshed successfully");
        } catch (summaryError) {
          debugPrint("❌ Error refreshing summary: $summaryError");
          if (technicianStats.value == null && previousStats != null) {
            technicianStats.value = previousStats;
          }
        }
        
        debugPrint("✅ Complete data refresh completed");
      } catch (e) {
        debugPrint("❌ Error during complete refresh: $e");
      }
    }

    Future<void> refreshTicketsOnly(String userId) async {
      try {
        debugPrint("🔄 Refreshing tickets only for user: $userId");
        await fetchTickets(userId);
        debugPrint("✅ Tickets refresh completed");
      } catch (e) {
        debugPrint("❌ Error refreshing tickets: $e");
      }
    }

    Future<void> refreshSummaryOnly(String userId) async {
      try {
        debugPrint("🔄 Refreshing summary only for user: $userId");
        await getSummaryForTechnician(userId);
        debugPrint("✅ Summary refresh completed");
      } catch (e) {
        debugPrint("❌ Error refreshing summary: $e");
      }
    }

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
      }
    }

    void debugStoredAssignments() {
      debugPrint("🔍 Current stored assignments:");
      for (final entry in assignedTechnicianIds.entries) {
        debugPrint("  ${entry.key} -> ${assignedTechnicianNames[entry.key]} (${entry.value})");
      }
      
      debugPrint("🔍 Current locally assigned tickets:");
      for (final entry in localAssignedTickets.entries) {
        debugPrint("  ${entry.key} -> ${entry.value}");
      }
    }

    // Filter, stats, and other existing methods remain exactly the same...
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
      Future<void> forceRefreshAllTickets(String userId) async {
  try {
    debugPrint("🔄 FORCE REFRESH: Starting complete ticket refresh");
    
    // Step 1: Load all stored data
    await _loadAssignmentsFromStorage();
    await _loadAssignedTicketsFromStorage();
    debugPrint("📂 Loaded ${assignedTechnicianIds.length} assignments from storage");
    
    // Step 2: Fetch fresh data from API
    await fetchTickets(userId);
    
    // Step 3: Ensure all assigned tickets are visible
    await _ensureAssignedTicketsVisible();
    
    // Step 4: Debug the final state
    debugTicketVisibility();
    
    debugPrint("✅ FORCE REFRESH: Complete");
  } catch (e) {
    debugPrint("❌ FORCE REFRESH: Error: $e");
  }
}

// 🆕 ADD: Ensure assigned tickets are visible
Future<void> _ensureAssignedTicketsVisible() async {
  final missingTickets = <Complaint>[];
  
  // Check if any assigned tickets are missing from the current list
  for (final entry in assignedTechnicianIds.entries) {
    final complaintId = entry.key;
    final isInCurrentList = tickets.any((t) => t.complaintId == complaintId);
    
    if (!isInCurrentList && localAssignedTickets.containsKey(complaintId)) {
      final localTicket = localAssignedTickets[complaintId]!;
      missingTickets.add(localTicket);
      debugPrint("🔍 Found missing assigned ticket: $complaintId");
    }
  }
  
  if (missingTickets.isNotEmpty) {
    debugPrint("🔧 Adding ${missingTickets.length} missing assigned tickets");
    
    // Apply assignments to missing tickets
    final updatedMissingTickets = _applyStoredAssignmentsToComplaints(missingTickets);
    
    // Add to current lists
    tickets.addAll(updatedMissingTickets);
    filteredTickets.addAll(updatedMissingTickets);
    
    // Refresh UI
    tickets.refresh();
    filteredTickets.refresh();
    
    debugPrint("✅ Added missing tickets. New total: ${tickets.length}");
  }
}

    }