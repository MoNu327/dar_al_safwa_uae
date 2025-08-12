// FIXED VERSION - Properly maintains assigned tickets across page navigation
import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/technican_list_model.dart';
import 'package:dar_al_safwa/data/model/technican_summary_model.dart';
import 'package:dar_al_safwa/data/model/tenant_compliant_model.dart';
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
  final RxList<ComplaintCategory> complaintCategory = <ComplaintCategory>[].obs;
  final RxInt selectedComplaintId = 0.obs;
  final RxBool isLoadingCompliantList = false.obs;
  
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
  Future<void> fetchTickets(String userId) async {
    try {
      debugPrint("🔄 Fetching ALL tickets for user: $userId");
      isLoading.value = true;
      
      // CRITICAL FIX: Load assignments and assigned tickets BEFORE making API calls
      await _loadAssignmentsFromStorage();
      await _loadAssignedTicketsFromStorage();

      // 🆕 Fetch tickets from API
      final List<Complaint> apiComplaints = await _fetchTicketsFromAPI(userId);
      debugPrint("📥 API tickets fetched: ${apiComplaints.length}");

      // 🔧 CRITICAL FIX: Always merge with locally assigned tickets
      final mergedComplaints = _mergeWithLocallyAssignedTickets(apiComplaints);
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
      debugTicketVisibility();
      
    } catch (e, st) {
      debugPrint("❌ Error fetching tickets: $e");
      debugPrint(st.toString());
      _showLocallyAssignedTicketsOnly();
    } finally {
      isLoading.value = false;
    }
  }

  // 🆕 Simplified API call method
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

  // 🔧 CRITICAL FIX: Enhanced merge logic to properly preserve assigned tickets
  List<Complaint> _mergeWithLocallyAssignedTickets(List<Complaint> apiComplaints) {
    final Map<String, Complaint> mergedTickets = {};
    
    debugPrint("🔄 Starting enhanced merge process...");
    debugPrint("📥 API complaints: ${apiComplaints.length}");
    debugPrint("💾 Local assigned tickets: ${localAssignedTickets.length}");
    debugPrint("🎯 Assignments in memory: ${assignedTechnicianIds.length}");
    
    // First, add all API tickets
    for (final complaint in apiComplaints) {
      mergedTickets[complaint.complaintId] = complaint;
      debugPrint("📥 Added API ticket: ${complaint.complaintId}");
    }
    
    // 🔧 CRITICAL: Add ALL locally assigned tickets, even if not in API response
    for (final entry in localAssignedTickets.entries) {
      final complaintId = entry.key;
      final localTicket = entry.value;
      
      // Check if this ticket is still assigned
      if (assignedTechnicianIds.containsKey(complaintId)) {
        // Always include assigned tickets, prioritizing local version
        mergedTickets[complaintId] = localTicket;
        debugPrint("💾 Added/Preserved assigned ticket: $complaintId");
      }
    }
    
    final result = mergedTickets.values.toList();
    debugPrint("✅ Enhanced merge complete: ${result.length} total unique tickets");
    
    // Debug what we have
    final assignedCount = result.where((t) => 
      assignedTechnicianIds.containsKey(t.complaintId) || 
      t.assignedTechnicianId?.isNotEmpty == true
    ).length;
    debugPrint("📊 Assigned tickets in result: $assignedCount");
    
    return result;
  }

  // 🔧 IMPROVED: Better fallback when API fails
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

  // 🆕 ADD: Method to refresh and ensure assigned tickets are visible
  Future<void> refreshAllData(String userId) async {
    try {
      debugPrint("🔄 Starting complete data refresh for user: $userId");
      
      // First, ensure we have the latest assignments from storage
      await _loadAssignmentsFromStorage();
      await _loadAssignedTicketsFromStorage();
      
      // Then fetch fresh tickets
      await fetchTickets(userId);
      
      // Ensure all assigned tickets are still visible
      await _ensureAssignedTicketsVisible();
      
      // Refresh summary
      try {
        await getSummaryForTechnician(userId);
        debugPrint("✅ Summary refreshed successfully");
      } catch (summaryError) {
        debugPrint("❌ Error refreshing summary: $summaryError");
      }
      
      debugPrint("✅ Complete data refresh completed");
    } catch (e) {
      debugPrint("❌ Error during complete refresh: $e");
    }
  }

  // 🆕 ADD: Ensure assigned tickets are visible after refresh
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

  // Rest of your existing methods remain the same...
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
  String errorMessage = 'We are currently performing maintenance. Please try again later.';
  
  if (response.data['message'] != null) {
    final messageData = response.data['message'];
    if (messageData is Map && messageData['en'] != null) {
      errorMessage = "We're experiencing some issues. ${messageData['en'].toString()}";
    } else if (messageData is String) {
      // Check if the message indicates maintenance
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
// FIXED: Updated assignment handler with proper UI refresh after reassignment
Future<void> _handleTechnicianAssignment(
  String complaintId,
  String selectedTechId,
  TechnicianTicketsController controller,
  bool isReassigning,
) async {
  try {
    // Show loading state
    controller.setAssigning(complaintId, true);

    // Store technician info before assignment
    final selectedTech = controller.availableTechnicians.firstWhere(
      (tech) => tech['id'] == selectedTechId,
      orElse: () => {'id': selectedTechId, 'name': 'Unknown Technician'},
    );

    final technicianName = selectedTech['name'] ?? 'Unknown Technician';

    // Call API to assign technician
    await controller.assignTechnicianWithoutRemoval(complaintId, selectedTechId);
    
    // ✅ CRITICAL FIX: Force immediate UI refresh after successful assignment
    await _forceRefreshAfterAssignment(
      complaintId, 
      selectedTechId, 
      technicianName, 
      controller, 
      isReassigning
    );

    // Show success message
    Get.snackbar(
      'Success',
      isReassigning 
          ? 'Ticket reassigned successfully to $technicianName'
          : 'Ticket assigned successfully to $technicianName',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.8),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to ${isReassigning ? 'reassign' : 'assign'} technician: ${e.toString()}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.withOpacity(0.8),
      colorText: Colors.white,
    );
  } finally {
    // Clear loading state
    controller.setAssigning(complaintId, false);
  }
}

// ✅ NEW: Force refresh method specifically for post-assignment UI updates
Future<void> _forceRefreshAfterAssignment(
  String complaintId,
  String selectedTechId,
  String technicianName,
  TechnicianTicketsController controller,
  bool isReassigning,
) async {
  try {
    debugPrint("🔄 Starting post-assignment refresh for: $complaintId");
    
    // 1. Update local assignment state immediately
    controller.assignedTechnicianIds[complaintId] = selectedTechId;
    controller.assignedTechnicianNames[complaintId] = technicianName;
    
    // 2. Clear UI selection state
    controller.selectedTechnicianIds[complaintId] = '';
    if (isReassigning) {
      controller.showAssignmentSection[complaintId] = false;
    }
    
    // 3. Update tickets in both lists immediately
    _updateTicketInBothLists(complaintId, selectedTechId, technicianName, controller, isReassigning);
    
    // 4. Force reactive refresh of the observable lists
    controller.tickets.refresh();
    controller.filteredTickets.refresh();
    
    // 5. Trigger a small delay and then full refresh to ensure consistency
    await Future.delayed(const Duration(milliseconds: 500));
    
    // 6. Optional: Fetch latest data from server to ensure consistency
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      debugPrint("🔄 Fetching latest data from server after assignment");
      await controller.fetchTickets(currentUser.uid);
      
      // Ensure assigned tickets remain visible after server refresh
      await controller._ensureAssignedTicketsVisible();
    }
    
    debugPrint("✅ Post-assignment refresh completed for: $complaintId");
    
  } catch (e) {
    debugPrint("❌ Error in post-assignment refresh: $e");
    // Even if refresh fails, ensure local state is updated
    controller.tickets.refresh();
    controller.filteredTickets.refresh();
  }
}

// ✅ ENHANCED: Update ticket in both lists with better error handling
void _updateTicketInBothLists(
  String complaintId, 
  String selectedTechId, 
  String technicianName,
  TechnicianTicketsController controller,
  bool isReassigning
) {
  try {
    debugPrint("🔄 Updating ticket $complaintId in both lists");
    
    // Helper function to update a single ticket
    Complaint updateSingleTicket(Complaint ticket) {
      return ticket.copyWith(
        assignedTechnicianId: selectedTechId,
        assignedTechnicianName: technicianName,
        status: isReassigning ? ticket.status : 'Assigned',
      );
    }
    
    // Update in main tickets list
    final mainTicketIndex = controller.tickets.indexWhere((t) => t.complaintId == complaintId);
    if (mainTicketIndex != -1) {
      controller.tickets[mainTicketIndex] = updateSingleTicket(controller.tickets[mainTicketIndex]);
      debugPrint("✅ Updated ticket in main list at index: $mainTicketIndex");
    } else {
      debugPrint("⚠️ Ticket not found in main list: $complaintId");
    }
    
    // Update in filtered tickets list
    final filteredTicketIndex = controller.filteredTickets.indexWhere((t) => t.complaintId == complaintId);
    if (filteredTicketIndex != -1) {
      controller.filteredTickets[filteredTicketIndex] = updateSingleTicket(controller.filteredTickets[filteredTicketIndex]);
      debugPrint("✅ Updated ticket in filtered list at index: $filteredTicketIndex");
    } else {
      debugPrint("⚠️ Ticket not found in filtered list: $complaintId");
    }
    
    // Update in locally assigned tickets storage
    if (controller.localAssignedTickets.containsKey(complaintId)) {
      controller.localAssignedTickets[complaintId] = updateSingleTicket(controller.localAssignedTickets[complaintId]!);
      debugPrint("✅ Updated ticket in local assigned tickets storage");
    }
    
  } catch (e) {
    debugPrint("❌ Error updating ticket in lists: $e");
  }
}

// ✅ ALTERNATIVE: If you want immediate refresh without server call, use this simpler version
Future<void> _immediateUIRefreshOnly(
  String complaintId,
  String selectedTechId,
  String technicianName,
  TechnicianTicketsController controller,
  bool isReassigning,
) async {
  // Update local state
  controller.assignedTechnicianIds[complaintId] = selectedTechId;
  controller.assignedTechnicianNames[complaintId] = technicianName;
  
  // Clear selection state
  controller.selectedTechnicianIds[complaintId] = '';
  if (isReassigning) {
    controller.showAssignmentSection[complaintId] = false;
  }
  
  // Update both lists
  _updateTicketInBothLists(complaintId, selectedTechId, technicianName, controller, isReassigning);
  
  // Force UI refresh
  controller.tickets.refresh();
  controller.filteredTickets.refresh();
  
  // Save to persistent storage
  await controller._saveAssignmentToStorage(complaintId, selectedTechId, technicianName);
  
  debugPrint("✅ Immediate UI refresh completed for reassignment: $complaintId -> $technicianName");
}
    }