import 'package:dar_al_safwa/data/datasources/api_client.dart';
import 'package:dar_al_safwa/data/model/technican_list_model.dart';
import 'package:dar_al_safwa/data/model/technican_summary_model.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../data/model/technician_complaints_response.dart';
import '../../../../data/model/technican_ticket_view_model.dart';

class TechnicianTicketsController extends GetxController {
  var isLoading = false.obs;
  var tickets = <Complaint>[].obs; // List of complaints
  var selectedTicket = Rxn<TicketModel>(); // Single ticket details
final RxMap<String, bool> isAssigningMap = <String, bool>{}.obs;
final RxList<Map<String, dynamic>> availableTechnicians = <Map<String, dynamic>>[].obs;
final RxMap<String, String> selectedTechnicianIds = <String, String>{}.obs;
  RxList<Complaint> ticket = <Complaint>[].obs;
  var filteredTickets = <Complaint>[].obs;
  final Rx<ComplaintStatisticsResponse?> technicianStats = Rx<ComplaintStatisticsResponse?>(null);
  final RxBool isStatsLoading = false.obs;
  final RxString statsErrorMessage = ''.obs;


  final ApiClient apiClient = ApiClient();  


  

void applyFilters({
  String? status,
  DateTime? startDate,
  DateTime? endDate,
}) {
  List<Complaint> result = List.from(tickets); // Start with all tickets

  // Status filtering
  if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
    final normalizedSelectedStatus = status.toLowerCase().trim();
    
    result = result.where((tickets) {
      final ticketStatus = tickets.statusText.en?.toLowerCase().trim() ?? '';
      debugPrint("🔍 Status Filter: Comparing selected '$normalizedSelectedStatus' vs ticket '$ticketStatus'");
      
      // Enhanced status matching
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

  // Date range filtering
  if (startDate != null || endDate != null) {
    result = result.where((tickets) {
      try {
        final ticketDate = _parseTicketDate(tickets.lastUpdated ?? tickets.lastUpdated);
        if (ticketDate == null) {
          debugPrint("⚠️ Could not parse date for ticket ${tickets.complaintId}");
          return false;
        }

        // Normalize dates to midnight for comparison
        final ticketDateOnly = DateTime(ticketDate.year, ticketDate.month, ticketDate.day);
        final startDateOnly = startDate != null 
            ? DateTime(startDate.year, startDate.month, startDate.day)
            : DateTime(1900); // Very early date if no start filter
        final endDateOnly = endDate != null
            ? DateTime(endDate.year, endDate.month, endDate.day)
            : DateTime(2100); // Very late date if no end filter

        debugPrint("📅 Date Filter: Ticket ${ticketDateOnly.toString()} between $startDateOnly and $endDateOnly");

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
  if (dateString == null || dateString.isEmpty) {
    debugPrint("⚠️ Date string is null or empty");
    return null;
  }

  // Trim any whitespace and remove timezone indicators if present
  final cleanDateString = dateString.trim().replaceAll(RegExp(r'[+-]\d{2}:?\d{2}$'), '');

  // Try multiple common date formats
  final possibleFormats = [
    "yyyy-MM-dd HH:mm:ss",      // 2025-08-01 14:30:00
    "yyyy-MM-ddTHH:mm:ss",      // 2025-08-01T14:30:00
    "yyyy-MM-dd",               // 2025-08-01
    "dd-MM-yyyy HH:mm:ss",      // 01-08-2025 14:30:00
    "MM/dd/yyyy HH:mm:ss",      // 08/01/2025 14:30:00
    "yyyy/MM/dd HH:mm:ss",      // 2025/08/01 14:30:00
    "EEE, dd MMM yyyy HH:mm:ss", // Tue, 01 Aug 2025 14:30:00
  ];

  for (final format in possibleFormats) {
    try {
      final date = DateFormat(format).parse(cleanDateString);
      debugPrint("✅ Parsed date '$dateString' as $date using format '$format'");
      return date;
    } catch (e) {
      // Try next format
    }
  }

  // Fallback to DateTime.parse if none of the formats worked
  try {
    final date = DateTime.parse(cleanDateString);
    debugPrint("✅ Parsed date '$dateString' as $date using DateTime.parse");
    return date;
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
        debugPrint('Technician stats loaded: ${technicianStats.value?.data.propertyStats.length} properties');
      } else {
        statsErrorMessage.value = 
            response.data['message']?['en'] ?? 'Failed to load technician statistics';
      }
    } catch (e) {
      statsErrorMessage.value = 'Error loading technician stats: $e';
      debugPrint('Exception in getSummaryForTechnician: $e');
    } finally {
      isStatsLoading.value = false;
    }
  }

  // You can add helper methods to access the statistics more easily
  


  /// Fetch available technicians (excluding current technician)
Future<void> getAvailableTechnicians() async {
  try {
    print("🔄 Starting technician fetch...");
    isLoading.value = true;
    print("🔁 isLoading set to true");

    availableTechnicians.clear();
    print("🧹 Cleared availableTechnicians list");

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    print("🧑‍💻 Current User UID (to exclude): $currentUid");

    final response = await apiClient.request(
      "technicians/except",
      method: "post",
      data: {
        "exclude_uid": currentUid,
      },
    );

    print("📡 Response received from API with status: ${response.statusCode}");
    print("📥 Raw response data: ${response.data}");

    if (response.statusCode == 200) {
      final parsedResponse = TechnicianDropdownResponse.fromJson(response.data);
      print("✅ Parsed response: ${parsedResponse.success}, Message: ${parsedResponse.displayMessage}");

      if (parsedResponse.success) {
        final techniciansList = parsedResponse.data.technicians.map((tech) => {
          'id': tech.uid,
          'name': tech.fullName,
        }).toList();

        availableTechnicians.assignAll(techniciansList);
        print("📋 Assigned ${techniciansList.length} available technicians to list");
        for (var tech in techniciansList) {
          print("🧑 Technician => ID: ${tech['id']}, Name: ${tech['name']}");
        }
      } else {
        print("❌ API responded with failure: ${parsedResponse.displayMessage}");
      }
    } else {
      print("❌ Unexpected status code: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Erroroccurred while fetching technicians: $e");
  } finally {
    isLoading.value = false;
  }
}

Future<void> assignTechnician(String complaintId, String technicianId) async {
  print("🔄 Assigning technician: $technicianId to complaint: $complaintId");
  try {
    setAssigning(complaintId, true);

    final userUid = FirebaseAuth.instance.currentUser?.uid;
    if (userUid == null) {
      print("❌ User UID is null");
      Get.snackbar('Error', 'User not logged in');
      return;
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
    
    print("📡 Escalate API Status: ${response.statusCode}");
    print("📥 Escalate API Raw Body: ${response.data}");
    
    if (response.data['success'] == true) {
      Get.snackbar('✅ Success', 'Technician assigned successfully');
      selectedTechnicianIds.remove(complaintId);
      
      // Instead of fetching all tickets, just remove the assigned one
      tickets.removeWhere((ticket) => ticket.complaintId == complaintId);
    } else {
      final errorMsg = response.data['message']?['en'] ?? 'Assignment failed';
      Get.snackbar('Error', errorMsg);
    }
  } catch (e) {
    Get.snackbar('Error', 'Failed to assign technician: ${e.toString()}');
  } finally {
    setAssigning(complaintId, false);
  }
}




  /// Fetch technician complaints (tickets)
Future<void> fetchTickets(String userId) async {
  try {
    isLoading.value = true;
    tickets.clear();

    final response = await apiClient.request(
      "technician/complaints",
      method: "post",
      data: {"uid": userId},
    );

    print("Response Status: ${response.statusCode}");
    print("🔍 Fetched complaints: ${response.data ?? 'null'}");

    final data = response.data;
    if (data == null) {
      print("⚠️ API returned null response");
      return;
    }

    if (data is List) {
      // Rare: API returns a bare list (no {status, data})
      final complaints = data
          .whereType<Map<String, dynamic>>()
          .map(Complaint.fromJson)
          .toList();
      tickets.addAll(complaints);
      print("✅ Complaints fetched (bare list): ${tickets.length}");
      return;
    }

    if (data is Map<String, dynamic>) {
      // Normal: { status, data: [...] } OR { status, data: {...} }
      final map = data;

     final bool ok = TechnicianComplaintsResponse.statusFromJson(map['status']);


      if (!ok) {
        print("⚠️ API status not OK");
        return;
      }

      final dynamic inner = map['data'];
      if (inner is List) {
        // Your current API shape (list of complaints)
        final complaints = inner
            .whereType<Map<String, dynamic>>()
            .map(Complaint.fromJson)
            .toList();

        if (complaints.isEmpty) {
          print("⚠️ API returned empty complaints list");
        } else {
          tickets.addAll(complaints);
          print("✅ Complaints fetched: ${tickets.length}");
        }
      } 
    //
    //else if (inner is Map<String, dynamic>) {
    //     // Fallback: single complaint shape using your existing model
    //     final parsed = ComplaintsResponse.fromJson(map);
    //     final single = parsed.data?.;
    //     if (single != null) {
    //       tickets.add(single);
    //       print("✅ Single complaint fetched: ${tickets.length}");
    //     } else {
    //       print("⚠️ No complaint data found");
    //     }
    //   } else {
    //     print("⚠️ Unexpected 'data' type: ${inner.runtimeType}");
    //   }
    //   return;
    }

    print("⚠️ Unexpected top-level response type: ${data.runtimeType}");
  } catch (e, st) {
    tickets.clear();
    print("❌ Error fetching complaints: $e");
    print(st);
  } finally {
    isLoading.value = false;
  }
}


  /// Fetch single complaint details by complaintId
  Future<void> fetchComplaintDetails(String complaintId) async {
    try {
      isLoading.value = true;

      final response = await apiClient.request(
        "complaint-details",
        method: "get", // Or "post" if API requires it
        data: {
          "complaint_id": complaintId,
        },
      );

      if (response.data['success'] == true) {
        selectedTicket.value = TicketModel.fromJson(response.data['data']);
        print("✅ Ticket details fetched: ${selectedTicket.value?.complaintNumber}");
      } else {
        print("⚠️ Failed to load ticket details: ${response.data['message']['en']}");
      }
    } catch (e) {
      print("❌ Error fetching complaint details: $e");
    } finally {
      isLoading.value = false;
    }
  }
  void setAssigning(String complaintId, bool value) {
  isAssigningMap[complaintId] = value;
}

}
