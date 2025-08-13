import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/technican_list_model.dart';
import 'package:dar_al_safwa/data/model/technican_summary_model.dart';
import 'package:dar_al_safwa/data/model/tenant_compliant_model.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
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
  final RxMap<String, bool> isAssigningMap = <String, bool>{}.obs;
  final RxMap<String, String> assignedTechnicianIds = <String, String>{}.obs;
  final RxMap<String, String> assignedTechnicianNames = <String, String>{}.obs;
  final RxMap<String, String> selectedTechnicianIds = <String, String>{}.obs;
  final RxMap<String, bool> showAssignmentSection = <String, bool>{}.obs;
  final RxList<ComplaintCategory> complaintCategory = <ComplaintCategory>[].obs;
  final RxMap<String, Complaint> localAssignedTickets = <String, Complaint>{}.obs;
  final RxMap<String, Map<String, dynamic>> assignmentHistory = <String, Map<String, dynamic>>{}.obs;
  final RxInt selectedComplaintId = 0.obs;
  final RxBool isLoadingCompliantList = false.obs;
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
      await _loadAssignmentsFromStorage();
      await _loadAssignedTicketsFromStorage();
      await _loadAssignmentHistoryFromStorage();
      await GetStorage.init();
      await getAvailableTechnicians();
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await fetchTickets(currentUser.uid);
        debugTicketVisibility();
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

  // Public methods to access private storage methods (for UI compatibility)
  Future<void> loadAssignmentsFromStorage() async {
    await _loadAssignmentsFromStorage();
  }

  Future<void> loadAssignedTicketsFromStorage() async {
    await _loadAssignedTicketsFromStorage();
  }

  Future<void> loadAssignmentHistoryFromStorage() async {
    await _loadAssignmentHistoryFromStorage();
  }

  // 🚨 MAJOR FIX: Enhanced merging to ALWAYS include assigned tickets
  List<Complaint> _mergeWithAssignedTickets(List<Complaint> apiComplaints, String currentUserId) {
    final Map<String, Complaint> mergedTickets = {};
    
    // 1. Add all API tickets
    for (final complaint in apiComplaints) {
      mergedTickets[complaint.complaintId] = complaint;
    }
    
    // 2. Add all locally assigned tickets
    for (final entry in localAssignedTickets.entries) {
      if (!mergedTickets.containsKey(entry.key)) {
        mergedTickets[entry.key] = entry.value;
      }
    }
    
    // 3. Apply any stored assignments
    for (final entry in assignedTechnicianIds.entries) {
      if (mergedTickets.containsKey(entry.key)) {
        final ticket = mergedTickets[entry.key]!;
        mergedTickets[entry.key] = ticket.copyWith(
          assignedTechnicianId: entry.value,
          assignedTechnicianName: assignedTechnicianNames[entry.key],
          status: 'Assigned',
        );
      }
    }
    
    return mergedTickets.values.toList();
  }

  Future<void> _saveAssignmentHistory(String complaintId, String fromTechnicianId, String toTechnicianId, String toTechnicianName) async {
    try {
      final historyData = {
        'fromTechnicianId': fromTechnicianId,
        'toTechnicianId': toTechnicianId,
        'toTechnicianName': toTechnicianName,
        'assignedAt': DateTime.now().toIso8601String(),
        'complaintId': complaintId,
      };
      
      assignmentHistory[complaintId] = historyData;
      await _storage.write('assignment_history_$complaintId', historyData);
      
      debugPrint("📝 Assignment history saved: $complaintId -> $toTechnicianName");
    } catch (e) {
      debugPrint("❌ Failed to save assignment history: $e");
    }
  }

  Future<void> _loadAssignmentHistoryFromStorage() async {
    try {
      final allKeys = _storage.getKeys();
      final List<String> keysList = [];
      
      for (final key in allKeys) {
        if (key is String && key.startsWith('assignment_history_')) {
          keysList.add(key);
        }
      }
      
      debugPrint("📂 Found ${keysList.length} assignment history records");
      
      for (final key in keysList) {
        try {
          final complaintId = key.replaceFirst('assignment_history_', '');
          final historyData = _storage.read(key);
          
          if (historyData != null && historyData is Map) {
            assignmentHistory[complaintId] = Map<String, dynamic>.from(historyData);
            debugPrint("📂 Loaded assignment history: $complaintId");
          }
        } catch (e) {
          debugPrint("❌ Error loading assignment history for key $key: $e");
        }
      }
      
      debugPrint("✅ Loaded ${assignmentHistory.length} assignment history records");
    } catch (e) {
      debugPrint("❌ Failed to load assignment history from storage: $e");
    }
  }

  Future<void> assignTechnicianWithoutRemoval(String complaintId, String technicianId) async {
    debugPrint("🔄 Assigning technician: $technicianId to complaint: $complaintId");
    try {
      setAssigning(complaintId, true);

      final userUid = FirebaseAuth.instance.currentUser?.uid;
      if (userUid == null) {
        debugPrint("❌ User UID is null");
        throw Exception('User not logged in');
      }

      // 🚨 CRITICAL: Clear previous assignment state before new assignment
      await _clearPreviousAssignmentState(complaintId);

      // Find and store the ticket
      final ticketToAssign = _findTicketInAllLists(complaintId);
      if (ticketToAssign != null) {
        await _saveAssignedTicketToStorage(complaintId, ticketToAssign);
        debugPrint("💾 Ticket saved to storage before assignment: $complaintId");
      }

      // Make API call
      final response = await apiClient.request(
        "complaints/escalate",
        method: "post",
        data: {
          "complaint_id": complaintId,
          "technician_uid": technicianId,
          "user_uid": userUid,
        },
      );
      
      if (response.data['success'] == true) {
        final techName = availableTechnicians.firstWhere(
          (t) => t['id'] == technicianId,
          orElse: () => {'name': 'Unknown Technician'},
        )['name'] ?? 'Unknown Technician';
        
        // 🚨 CRITICAL: Force update all assignment states
        await _forceUpdateAssignmentState(
          complaintId: complaintId,
          technicianId: technicianId,
          technicianName: techName,
          fromTechnicianId: userUid,
        );
        
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

  Future<void> _forceUpdateAssignmentState({
    required String complaintId,
    required String technicianId,
    required String technicianName,
    required String fromTechnicianId,
  }) async {
    try {
      // 1. Update all local state maps
      assignedTechnicianIds[complaintId] = technicianId;
      assignedTechnicianNames[complaintId] = technicianName;
      selectedTechnicianIds.remove(complaintId);
      showAssignmentSection[complaintId] = false;

      // 2. Update storage
      await _saveAssignmentToStorage(complaintId, technicianId, technicianName);
      await _saveAssignmentHistory(complaintId, fromTechnicianId, technicianId, technicianName);

      // 3. Update all ticket lists
      _updateTicketInAllLists(
        complaintId: complaintId,
        technicianId: technicianId,
        technicianName: technicianName,
      );

      // 4. Force UI refresh
      tickets.refresh();
      filteredTickets.refresh();

      debugPrint("✅ FORCE UPDATED assignment state for $complaintId -> $technicianName");
    } catch (e) {
      debugPrint("❌ Error in force update assignment: $e");
      rethrow;
    }
  }

  Future<void> _clearPreviousAssignmentState(String complaintId) async {
    try {
      debugPrint("🧹 Clearing previous assignment state for $complaintId");
      
      // Clear from memory
      assignedTechnicianIds.remove(complaintId);
      assignedTechnicianNames.remove(complaintId);
      selectedTechnicianIds.remove(complaintId);
      showAssignmentSection.remove(complaintId);
      
      // Clear from storage
      await _storage.remove('assigned_$complaintId');
      await _storage.remove('assignment_history_$complaintId');
      
      debugPrint("✅ Cleared previous assignment state");
    } catch (e) {
      debugPrint("❌ Error clearing previous assignment: $e");
    }
  }

  void _updateTicketInAllLists({
    required String complaintId,
    required String technicianId,
    required String technicianName,
  }) {
    try {
      // Update in main tickets list
      tickets.value = tickets.map((ticket) {
        if (ticket.complaintId == complaintId) {
          return ticket.copyWith(
            assignedTechnicianId: technicianId,
            assignedTechnicianName: technicianName,
            status: 'Assigned',
          );
        }
        return ticket;
      }).toList();

      // Update in filtered tickets list
      filteredTickets.value = filteredTickets.map((ticket) {
        if (ticket.complaintId == complaintId) {
          return ticket.copyWith(
            assignedTechnicianId: technicianId,
            assignedTechnicianName: technicianName,
            status: 'Assigned',
          );
        }
        return ticket;
      }).toList();

      // Update in local assigned tickets
      if (localAssignedTickets.containsKey(complaintId)) {
        localAssignedTickets[complaintId] = localAssignedTickets[complaintId]!.copyWith(
          assignedTechnicianId: technicianId,
          assignedTechnicianName: technicianName,
          status: 'Assigned',
        );
      }

      debugPrint("✅ Updated ticket in all lists: $complaintId -> $technicianName");
    } catch (e) {
      debugPrint("❌ Error updating ticket in all lists: $e");
    }
  }

  // 🆕 Helper method to find ticket in all available lists
  Complaint? _findTicketInAllLists(String complaintId) {
    try {
      // First try in main tickets list
      final ticketInMain = tickets.where((t) => t.complaintId == complaintId).firstOrNull;
      if (ticketInMain != null) {
        debugPrint("🔍 Found ticket in main list: $complaintId");
        return ticketInMain;
      }
      
      // Then try in filtered tickets list
      final ticketInFiltered = filteredTickets.where((t) => t.complaintId == complaintId).firstOrNull;
      if (ticketInFiltered != null) {
        debugPrint("🔍 Found ticket in filtered list: $complaintId");
        return ticketInFiltered;
      }
      
      // Finally try in local assigned tickets
      if (localAssignedTickets.containsKey(complaintId)) {
        debugPrint("🔍 Found ticket in local storage: $complaintId");
        return localAssignedTickets[complaintId];
      }
      
      debugPrint("❌ Ticket not found in any list: $complaintId");
      return null;
    } catch (e) {
      debugPrint("❌ Error finding ticket: $e");
      return null;
    }
  }

  // 🚨 ENHANCED: Ticket fetching with comprehensive assigned ticket preservation
Future<void> fetchTickets(String userId) async {
  try {
    debugPrint("🔄 Fetching ALL tickets for user: $userId");
    isLoading.value = true;
    
    // STEP 1: Load all stored assignment data FIRST (critical!)
    await _loadAssignmentsFromStorage();
    await _loadAssignedTicketsFromStorage();
    await _loadAssignmentHistoryFromStorage();
    
    debugPrint("📂 Loaded storage data:");
    debugPrint("  - Assignments: ${assignedTechnicianIds.length}");
    debugPrint("  - Local tickets: ${localAssignedTickets.length}");
    debugPrint("  - Assignment history: ${assignmentHistory.length}");

    // STEP 2: Fetch current tickets from API (these are tickets currently assigned TO this technician)
    final List<Complaint> currentApiTickets = await _fetchTicketsFromAPI(userId);
    debugPrint("📥 Current API tickets: ${currentApiTickets.length}");

    // STEP 3: 🚨 PRESERVE ASSIGNED TICKETS - Include tickets that were assigned BY this technician
    final List<Complaint> assignedByThisTechnician = await _getTicketsAssignedByThisTechnician(userId);
    debugPrint("📤 Tickets assigned BY this technician: ${assignedByThisTechnician.length}");
    
    // STEP 4: 🚨 COMPREHENSIVE MERGE - Combine all tickets
    final mergedComplaints = _comprehensiveMergeAllTickets(
      currentApiTickets, 
      assignedByThisTechnician, 
      userId
    );
    debugPrint("🔄 After COMPREHENSIVE merge: ${mergedComplaints.length} tickets");
    
    // STEP 5: Apply stored assignments to ensure consistency
    final updatedComplaints = _applyStoredAssignmentsToComplaints(mergedComplaints);
    debugPrint("✅ After applying assignments: ${updatedComplaints.length} tickets");
    
    // STEP 6: Update the observable lists
    tickets.clear();
    filteredTickets.clear();
    tickets.addAll(updatedComplaints);
    filteredTickets.addAll(updatedComplaints);
    
    // STEP 7: Final verification and recovery
    await _verifyAndRecoverAssignedTickets();
    
    debugPrint("✅ Final ticket count: ${tickets.length}");
    debugTicketVisibility();
    
  } catch (e, st) {
    debugPrint("❌ Error fetching tickets: $e");
    debugPrint(st.toString());
    _showLocallyAssignedTicketsOnly();
  } finally {
    isLoading.value = false;
  }
}

Future<List<Complaint>> _getTicketsAssignedByThisTechnician(String currentUserId) async {
  final List<Complaint> assignedTickets = [];
  
  try {
    // Get tickets from assignment history where this technician was the assignor
    for (final entry in assignmentHistory.entries) {
      final complaintId = entry.key;
      final historyData = entry.value;
      final fromTechnicianId = historyData['fromTechnicianId']?.toString() ?? '';
      
      // Only include tickets assigned BY this technician
      if (fromTechnicianId == currentUserId) {
        // Check if we have the ticket in local storage
        if (localAssignedTickets.containsKey(complaintId)) {
          final ticket = localAssignedTickets[complaintId]!;
          assignedTickets.add(ticket);
          debugPrint("📤 Including ticket assigned BY this technician: $complaintId -> ${historyData['toTechnicianName']}");
        }
      }
    }
    
    // Also include any currently assigned tickets (from assignedTechnicianIds)
    for (final entry in assignedTechnicianIds.entries) {
      final complaintId = entry.key;
      final technicianId = entry.value;
      final technicianName = assignedTechnicianNames[complaintId] ?? 'Unknown';
      
      // Skip if already added from history
      if (assignedTickets.any((t) => t.complaintId == complaintId)) {
        continue;
      }
      
      // Include if we have the ticket in local storage
      if (localAssignedTickets.containsKey(complaintId)) {
        final ticket = localAssignedTickets[complaintId]!;
        assignedTickets.add(ticket);
        debugPrint("📤 Including currently assigned ticket: $complaintId -> $technicianName");
      }
    }
    
    debugPrint("✅ Found ${assignedTickets.length} tickets assigned by this technician");
    return assignedTickets;
    
  } catch (e) {
    debugPrint("❌ Error getting assigned tickets: $e");
    return [];
  }
}

// 🆕 ENHANCED: Comprehensive merge that handles all ticket sources
List<Complaint> _comprehensiveMergeAllTickets(
  List<Complaint> currentApiTickets, 
  List<Complaint> assignedByThisTechnician, 
  String currentUserId
) {
  final Map<String, Complaint> mergedTickets = {};
  
  // 1. Add current API tickets (tickets currently assigned TO this technician)
  for (final complaint in currentApiTickets) {
    mergedTickets[complaint.complaintId] = complaint;
    debugPrint("➕ API ticket: ${complaint.complaintId} - ${complaint.status}");
  }
  
  // 2. Add tickets assigned BY this technician (even if no longer in API)
  for (final complaint in assignedByThisTechnician) {
    if (!mergedTickets.containsKey(complaint.complaintId)) {
      mergedTickets[complaint.complaintId] = complaint;
      debugPrint("➕ Assigned ticket: ${complaint.complaintId} - ${complaint.status}");
    } else {
      // If ticket exists in both, prefer the one with assignment info
      final existingTicket = mergedTickets[complaint.complaintId]!;
      if (complaint.assignedTechnicianId != null && existingTicket.assignedTechnicianId == null) {
        mergedTickets[complaint.complaintId] = complaint;
        debugPrint("🔄 Updated with assignment info: ${complaint.complaintId}");
      }
    }
  }
  
  // 3. Add any other locally stored tickets
  for (final entry in localAssignedTickets.entries) {
    final complaintId = entry.key;
    final localTicket = entry.value;
    
    if (!mergedTickets.containsKey(complaintId)) {
      mergedTickets[complaintId] = localTicket;
      debugPrint("➕ Local ticket: $complaintId - ${localTicket.status}");
    }
  }
  
  debugPrint("🔄 COMPREHENSIVE MERGE COMPLETE: ${mergedTickets.length} total tickets");
  return mergedTickets.values.toList();
}

  // 🆕 CRITICAL: Verification and recovery method for assigned tickets
  Future<void> _verifyAndRecoverAssignedTickets() async {
  debugPrint("🔍 VERIFICATION: Checking all assigned tickets are present...");
  
  final missingTickets = <Complaint>[];
  final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // Check assignments (tickets currently assigned to others)
  for (final entry in assignedTechnicianIds.entries) {
    final complaintId = entry.key;
    final assignedTechName = assignedTechnicianNames[complaintId] ?? 'Unknown';
    
    final ticketPresent = tickets.any((t) => t.complaintId == complaintId);
    if (!ticketPresent) {
      debugPrint("❌ MISSING: Assigned ticket not in UI: $complaintId -> $assignedTechName");
      
      // Try to recover from local storage
      if (localAssignedTickets.containsKey(complaintId)) {
        missingTickets.add(localAssignedTickets[complaintId]!);
        debugPrint("🔧 Will recover: $complaintId");
      }
    } else {
      debugPrint("✅ PRESENT: $complaintId -> $assignedTechName");
    }
  }
  
  // Check assignment history (tickets assigned BY this technician)
  for (final entry in assignmentHistory.entries) {
    final complaintId = entry.key;
    final historyData = entry.value;
    final fromTechnicianId = historyData['fromTechnicianId']?.toString() ?? '';
    
    // Only check tickets assigned BY this technician
    if (fromTechnicianId == currentUserId) {
      final ticketPresent = tickets.any((t) => t.complaintId == complaintId);
      if (!ticketPresent && localAssignedTickets.containsKey(complaintId)) {
        // Don't add duplicates
        if (!missingTickets.any((t) => t.complaintId == complaintId)) {
          missingTickets.add(localAssignedTickets[complaintId]!);
          debugPrint("🔧 Will recover from history: $complaintId -> ${historyData['toTechnicianName']}");
        }
      }
    }
  }
  
  // Recover missing tickets
  if (missingTickets.isNotEmpty) {
    debugPrint("🔧 RECOVERING ${missingTickets.length} missing assigned tickets...");
    
    final updatedMissingTickets = _applyStoredAssignmentsToComplaints(missingTickets);
    
    tickets.addAll(updatedMissingTickets);
    filteredTickets.addAll(updatedMissingTickets);
    
    // Force UI refresh
    tickets.refresh();
    filteredTickets.refresh();
    
    debugPrint("✅ RECOVERY COMPLETE: Added ${updatedMissingTickets.length} tickets");
    debugPrint("✅ New total ticket count: ${tickets.length}");
  } else {
    debugPrint("✅ VERIFICATION PASSED: All assigned tickets are present");
  }
}
  Future<void> _updateAssignmentState(String complaintId, String technicianId) async {
    try {
      final tech = availableTechnicians.firstWhere(
        (t) => t['id'] == technicianId,
        orElse: () => {'id': technicianId, 'name': 'Unknown Technician'},
      );
      
      final technicianName = tech['name'] ?? 'Unknown Technician';
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      
      // Update local state IMMEDIATELY
      assignedTechnicianIds[complaintId] = technicianId;
      assignedTechnicianNames[complaintId] = technicianName;
      
      // Save to persistent storage
      await _saveAssignmentToStorage(complaintId, technicianId, technicianName);
      
      // Clear UI state
      selectedTechnicianIds.remove(complaintId);
      showAssignmentSection[complaintId] = false;
      
      // Update ticket in current lists
      _updateTicketInList(complaintId, technicianId, technicianName);
      
      // Force UI refresh
      tickets.refresh();
      filteredTickets.refresh();
      
      // Refresh technician stats
      if (currentUserId != null) {
        await getSummaryForTechnician(currentUserId);
        debugPrint("✅ Refreshed technician stats after assignment");
      }
      
      debugPrint("✅ Assignment state updated and saved for $complaintId -> $technicianName");
    } catch (e) {
      debugPrint("❌ Error updating assignment state: $e");
    }
  }

  void _showLocallyAssignedTicketsOnly() {
    try {
      debugPrint("🔄 API failed - showing ALL locally stored tickets...");
      final ticketsToShow = <Complaint>[];
      
      // Include ALL locally assigned tickets
      for (final entry in localAssignedTickets.entries) {
        final complaintId = entry.key;
        if (assignedTechnicianIds.containsKey(complaintId) || assignmentHistory.containsKey(complaintId)) {
          ticketsToShow.add(entry.value);
          debugPrint("💾 Including ticket: $complaintId");
        }
      }
      
      if (ticketsToShow.isNotEmpty) {
        final updatedComplaints = _applyStoredAssignmentsToComplaints(ticketsToShow);
        tickets.assignAll(updatedComplaints);
        filteredTickets.assignAll(updatedComplaints);
        
        debugPrint("✅ Showing ${ticketsToShow.length} locally stored tickets");
      } else {
        debugPrint("⚠️ No locally stored tickets found");
        tickets.clear();
        filteredTickets.clear();
      }
    } catch (e) {
      debugPrint("❌ Error showing locally stored tickets: $e");
      tickets.clear();
      filteredTickets.clear();
    }
  }

  Future<void> _saveAssignedTicketToStorage(String complaintId, Complaint ticket) async {
    try {
      // Store in local memory immediately
      localAssignedTickets[complaintId] = ticket;
      
      // Convert ticket to JSON and save to persistent storage
      final ticketJson = ticket.toJson();
      await _storage.write('assigned_ticket_$complaintId', ticketJson);
      
      debugPrint("💾 Assigned ticket saved to storage: $complaintId");
      debugPrint("  - Status: ${ticket.status}");
      debugPrint("  - Property: ${ticket.propertyName}");
    } catch (e) {
      debugPrint("❌ Failed to save assigned ticket to storage: $e");
    }
  }

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
      
      int successfullyLoaded = 0;
      for (final key in keysList) {
        try {
          final complaintId = key.replaceFirst('assigned_ticket_', '');
          final ticketData = _storage.read(key);
          
          if (ticketData != null && ticketData is Map<String, dynamic>) {
            final ticket = Complaint.fromJson(ticketData);
            localAssignedTickets[complaintId] = ticket;
            successfullyLoaded++;
            
            debugPrint("📂 Loaded assigned ticket: $complaintId - ${ticket.propertyName}");
          }
        } catch (e) {
          debugPrint("❌ Error loading assigned ticket for key $key: $e");
          // Continue loading other tickets even if one fails
        }
      }
      
      debugPrint("✅ Successfully loaded $successfullyLoaded assigned tickets from storage");
    } catch (e) {
      debugPrint("❌ Failed to load assigned tickets from storage: $e");
    }
  }

  Future<void> _saveAssignmentToStorage(String complaintId, String technicianId, String technicianName) async {
    try {
      // Save to memory
      assignedTechnicianIds[complaintId] = technicianId;
      assignedTechnicianNames[complaintId] = technicianName;
      
      // Save to persistent storage
      await _storage.write('assigned_$complaintId', {
        'technicianId': technicianId,
        'technicianName': technicianName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      debugPrint("💾 Assignment saved for $complaintId");
    } catch (e) {
      debugPrint("❌ Failed to save assignment: $e");
    }
  }

  Future<void> _loadAssignmentsFromStorage() async {
    try {
      final allKeys = _storage.getKeys();
      final List<String> assignmentKeys = [];
      
      // First collect all relevant keys
      for (final key in allKeys) {
        if (key is String && key.startsWith('assigned_') && !key.contains('ticket') && !key.contains('history')) {
          assignmentKeys.add(key);
        }
      }
      
      debugPrint("📂 Found ${assignmentKeys.length} assignment records");
      
      // Now load each assignment
      for (final key in assignmentKeys) {
        try {
          final data = _storage.read(key);
          if (data is Map) {
            final complaintId = key.replaceFirst('assigned_', '');
            assignedTechnicianIds[complaintId] = data['technicianId']?.toString() ?? '';
            assignedTechnicianNames[complaintId] = data['technicianName']?.toString() ?? '';
            debugPrint("📂 Loaded assignment: $complaintId -> ${assignedTechnicianNames[complaintId]}");
          }
        } catch (e) {
          debugPrint("❌ Error loading assignment for key $key: $e");
        }
      }
      
      debugPrint("✅ Successfully loaded ${assignedTechnicianIds.length} assignments");
    } catch (e) {
      debugPrint("❌ Failed to load assignments from storage: $e");
    }
  }

  Future<List<Complaint>> _fetchTicketsFromAPI(String userId) async {
    try {
      final response = await apiClient.request(
        "technician/complaints",
        method: "post",
        data: {"uid": userId},
      );

      debugPrint("📡 API response status: ${response.statusCode}");

      final data = response.data;
      if (data == null) {
        debugPrint("⚠️ API returned null response");
        return [];
      }

      return _parseComplaintsFromResponse(data, "API");
    } catch (e) {
      debugPrint("❌ Error fetching tickets from API: $e");
      return [];
    }
  }

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

  List<Complaint> _applyStoredAssignmentsToComplaints(List<Complaint> complaints) {
    final updatedComplaints = <Complaint>[];
    
    for (final complaint in complaints) {
      final complaintId = complaint.complaintId;
      final storedTechId = assignedTechnicianIds[complaintId];
      final storedTechName = assignedTechnicianNames[complaintId];
      
      if (storedTechId != null && storedTechName != null && storedTechId.isNotEmpty) {
        try {
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

  Future<void> clearAssignment(String complaintId) async {
    assignedTechnicianIds.remove(complaintId);
    assignedTechnicianNames.remove(complaintId);
    selectedTechnicianIds.remove(complaintId);
    showAssignmentSection.remove(complaintId);
    
    localAssignedTickets.remove(complaintId);
    assignmentHistory.remove(complaintId);
    
    try {
      await _storage.remove('assigned_technician_$complaintId');
      await _storage.remove('assigned_ticket_$complaintId');
      await _storage.remove('assignment_history_$complaintId');
      debugPrint("🗑️ Cleared assignment, ticket, and history from storage for: $complaintId");
    } catch (e) {
      debugPrint("❌ Failed to clear assignment from storage: $e");
    }
    
    tickets.refresh();
    filteredTickets.refresh();
  }

  void debugTicketVisibility() {
    debugPrint("🔍 TICKET VISIBILITY DEBUG:");
    debugPrint("🎫 UI shows: ${tickets.length} tickets");
    debugPrint("💾 Assigned tickets in storage: ${assignedTechnicianIds.length}");
    debugPrint("📥 Local assigned tickets: ${localAssignedTickets.length}");
    debugPrint("📝 Assignment history: ${assignmentHistory.length}");
    
    debugPrint("\n📋 Assignment Details:");
    for (final entry in assignedTechnicianIds.entries) {
      final complaintId = entry.key;
      final techName = assignedTechnicianNames[complaintId] ?? 'Unknown';
      final hasLocalTicket = localAssignedTickets.containsKey(complaintId);
      final inCurrentList = tickets.any((t) => t.complaintId == complaintId);
      final hasHistory = assignmentHistory.containsKey(complaintId);
      
      debugPrint("  $complaintId -> $techName (Local: $hasLocalTicket, InList: $inCurrentList, History: $hasHistory)");
    }
    
    debugPrint("\n🎫 Current Tickets in UI:");
    for (int i = 0; i < tickets.length; i++) {
      final ticket = tickets[i];
      final isAssigned = assignedTechnicianIds.containsKey(ticket.complaintId);
      final assignedTo = assignedTechnicianNames[ticket.complaintId] ?? 'None';
      debugPrint("  ${i + 1}. ${ticket.complaintId} - ${ticket.status} - Assigned to: $assignedTo");
    }
  }

  // 🆕 ENHANCED: Comprehensive refresh that ensures ALL assigned tickets remain visible
  Future<void> refreshAllData(String userId) async {
    try {
      debugPrint("🔄 Starting COMPREHENSIVE data refresh for user: $userId");
      
      // Step 1: Load all stored data first
      await _loadAssignmentsFromStorage();
      await _loadAssignedTicketsFromStorage();
      await _loadAssignmentHistoryFromStorage();
      
      debugPrint("📂 Loaded ${assignedTechnicianIds.length} assignments from storage");
      debugPrint("📂 Loaded ${localAssignedTickets.length} local tickets from storage");
      
      // Step 2: Fetch fresh tickets (which will automatically merge with stored assignments)
      await fetchTickets(userId);
      
      // Step 3: Ensure ALL assigned tickets are visible (redundant safety check)
      await _ensureAssignedTicketsVisible();
      
      // Step 4: Refresh summary stats
      try {
        await getSummaryForTechnician(userId);
        debugPrint("✅ Summary refreshed successfully");
      } catch (summaryError) {
        debugPrint("❌ Error refreshing summary: $summaryError");
      }
      
      // Step 5: Final verification
      debugTicketVisibility();
      
      debugPrint("✅ COMPREHENSIVE data refresh completed");
      debugPrint("✅ Final UI ticket count: ${tickets.length}");
    } catch (e) {
      debugPrint("❌ Error during comprehensive refresh: $e");
    }
  }

  // 🆕 ENHANCED: Ensure assigned tickets are visible with better recovery
  Future<void> _ensureAssignedTicketsVisible() async {
    debugPrint("🔍 ENSURING all assigned tickets are visible...");
    
    final missingTickets = <Complaint>[];
    
    // Check if any assigned tickets are missing from the current list
    for (final entry in assignedTechnicianIds.entries) {
      final complaintId = entry.key;
      final assignedTechName = assignedTechnicianNames[complaintId] ?? 'Unknown';
      final isInCurrentList = tickets.any((t) => t.complaintId == complaintId);
      
      if (!isInCurrentList) {
        debugPrint("❌ MISSING assigned ticket: $complaintId -> $assignedTechName");
        
        if (localAssignedTickets.containsKey(complaintId)) {
          final localTicket = localAssignedTickets[complaintId]!;
          missingTickets.add(localTicket);
          debugPrint("🔧 Will recover: $complaintId from local storage");
        } else {
          debugPrint("⚠️ WARNING: No local ticket data for missing assignment: $complaintId");
        }
      } else {
        debugPrint("✅ Assignment present in UI: $complaintId -> $assignedTechName");
      }
    }
    
    // Also check assignment history for tickets assigned BY this technician
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    for (final entry in assignmentHistory.entries) {
      final complaintId = entry.key;
      final historyData = entry.value;
      final fromTechnicianId = historyData['fromTechnicianId']?.toString() ?? '';
      
      // Only check tickets assigned BY this technician
      if (fromTechnicianId == currentUserId) {
        final isInCurrentList = tickets.any((t) => t.complaintId == complaintId);
        
        if (!isInCurrentList && localAssignedTickets.containsKey(complaintId)) {
          // Don't add duplicates
          if (!missingTickets.any((t) => t.complaintId == complaintId)) {
            final localTicket = localAssignedTickets[complaintId]!;
            missingTickets.add(localTicket);
            debugPrint("🔧 Will recover from history: $complaintId -> ${historyData['toTechnicianName']}");
          }
        }
      }
    }
    
    // Recover missing tickets
    if (missingTickets.isNotEmpty) {
      debugPrint("🔧 RECOVERING ${missingTickets.length} missing assigned tickets...");
      
      final updatedMissingTickets = _applyStoredAssignmentsToComplaints(missingTickets);
      
      tickets.addAll(updatedMissingTickets);
      filteredTickets.addAll(updatedMissingTickets);
      
      // Force UI refresh
      tickets.refresh();
      filteredTickets.refresh();
      
      debugPrint("✅ RECOVERY COMPLETE: Added ${updatedMissingTickets.length} missing tickets");
      debugPrint("✅ New total ticket count: ${tickets.length}");
      
      // Verify all assignments are now present
      _verifyAllAssignmentsPresent();
    } else {
      debugPrint("✅ All assigned tickets are already present in UI");
    }
  }

  // 🆕 Final verification method
  void _verifyAllAssignmentsPresent() {
    debugPrint("🔍 FINAL VERIFICATION: Checking all assignments are present...");
    
    int presentCount = 0;
    int missingCount = 0;
    
    for (final entry in assignedTechnicianIds.entries) {
      final complaintId = entry.key;
      final assignedTechName = assignedTechnicianNames[complaintId] ?? 'Unknown';
      final isPresent = tickets.any((t) => t.complaintId == complaintId);
      
      if (isPresent) {
        presentCount++;
        debugPrint("✅ VERIFIED: $complaintId -> $assignedTechName");
      } else {
        missingCount++;
        debugPrint("❌ STILL MISSING: $complaintId -> $assignedTechName");
      }
    }
    
    debugPrint("📊 VERIFICATION RESULTS:");
    debugPrint("  - Present assignments: $presentCount");
    debugPrint("  - Missing assignments: $missingCount");
    debugPrint("  - Total UI tickets: ${tickets.length}");
    
    if (missingCount == 0) {
      debugPrint("🎉 SUCCESS: All assigned tickets are present in UI!");
    } else {
      debugPrint("⚠️ WARNING: $missingCount assigned tickets are still missing from UI");
    }
  }

  Future<void> refreshTicketsOnly(String userId) async {
    try {
      debugPrint("🔄 Refreshing tickets only for user: $userId");
      await fetchTickets(userId);
      await _ensureAssignedTicketsVisible();
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
      // Update in main tickets list
      for (int i = 0; i < tickets.length; i++) {
        if (tickets[i].complaintId == complaintId) {
          tickets[i] = tickets[i].copyWith(
            assignedTechnicianId: technicianId,
            assignedTechnicianName: technicianName,
            status: tickets[i].status == 'pending' ? 'Assigned' : tickets[i].status,
          );
          debugPrint("✅ Updated ticket in main list: $complaintId");
          break;
        }
      }
      
      // Update in filtered tickets list
      for (int i = 0; i < filteredTickets.length; i++) {
        if (filteredTickets[i].complaintId == complaintId) {
          filteredTickets[i] = filteredTickets[i].copyWith(
            assignedTechnicianId: technicianId,
            assignedTechnicianName: technicianName,
            status: filteredTickets[i].status == 'pending' ? 'Assigned' : filteredTickets[i].status,
          );
          debugPrint("✅ Updated ticket in filtered list: $complaintId");
          break;
        }
      }
      
      // Also update in local assigned tickets storage
      if (localAssignedTickets.containsKey(complaintId)) {
        final existingTicket = localAssignedTickets[complaintId]!;
        localAssignedTickets[complaintId] = existingTicket.copyWith(
          assignedTechnicianId: technicianId,
          assignedTechnicianName: technicianName,
          status: existingTicket.status == 'pending' ? 'Assigned' : existingTicket.status,
        );
        debugPrint("✅ Updated ticket in local storage: $complaintId");
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
      debugPrint("  ${entry.key} -> Status: ${entry.value.status}, Property: ${entry.value.propertyName}");
    }
  }

  // 🆕 Force refresh method that guarantees assigned tickets remain visible
  Future<void> forceRefreshAllTickets(String userId) async {
    try {
      debugPrint("🔄 FORCE REFRESH: Starting comprehensive ticket refresh");
      
      // Step 1: Load all stored data
      await _loadAssignmentsFromStorage();
      await _loadAssignedTicketsFromStorage();
      await _loadAssignmentHistoryFromStorage();
      
      debugPrint("📂 Loaded ${assignedTechnicianIds.length} assignments from storage");
      debugPrint("📂 Loaded ${localAssignedTickets.length} local tickets from storage");
      
      // Step 2: Fetch tickets with comprehensive merge
      await fetchTickets(userId);
      
      // Step 3: Multiple safety checks to ensure assigned tickets are visible
      await _ensureAssignedTicketsVisible();
      await _verifyAndRecoverAssignedTickets();
      
      // Step 4: Final verification and debug
      debugTicketVisibility();
      _verifyAllAssignmentsPresent();
      
      debugPrint("✅ FORCE REFRESH: Complete - Final count: ${tickets.length} tickets");
    } catch (e) {
      debugPrint("❌ FORCE REFRESH: Error: $e");
    }
  }

  // Rest of the existing methods (filters, stats, etc.) remain the same...
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

    final cleanDateString = dateString.trim().replaceAll(RegExp(r'[+-]\d{2}:?\d{2}\)?'), '');

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
        String errorMessage = 'We are currently performing maintenance. Please try again later.';
        
        if (response.data['message'] != null) {
          final messageData = response.data['message'];
          if (messageData is Map && messageData['en'] != null) {
            errorMessage = "We're experiencing some issues. ${messageData['en'].toString()}";
          } else if (messageData is String) {
            if (messageData.toLowerCase().contains('maintenance') || 
                messageData.toLowerCase().contains('unavailable')) {
              errorMessage = 'The system is currently under maintenance. Please try again later.';
            } else {
              errorMessage = "We're having technical difficulties. $messageData";
            }
          }
        }
        
        statsErrorMessage.value = errorMessage;
      }
    } catch (e) {
      statsErrorMessage.value = 'Our systems are temporarily unavailable. Please check back shortly.';
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
