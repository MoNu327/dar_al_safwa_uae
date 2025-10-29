import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/technician_complaints_response.dart';
import 'package:majan/data/model/ticket_list_response_model.dart';
import 'package:majan/domain/controller/technician_tickets_controller.dart';
import 'package:majan/presentation/view/dashboard/widgets/technician_ticket_card_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TechnicianViewTickets extends StatefulWidget {
  const TechnicianViewTickets({super.key});

  @override
  State<TechnicianViewTickets> createState() => _TechnicianViewTicketsState();
}

class _TechnicianViewTicketsState extends State<TechnicianViewTickets> {
  final controller = Get.put(TechnicianTicketsController());
  
  // Local lists for filtering
  List<Complaint> allTickets = [];
  List<Complaint> filteredTickets = [];
  
  // Filter variables
  String? selectedStatus;
  String? selectedCategory;
  DateTime? startDate;
  DateTime? endDate;
  
  // Loading state
  bool isInitializing = true;

 @override
void initState() {
  super.initState();
  _initializeData();
  
  // Listen for changes in controller tickets and update local state
  ever(controller.tickets, (_) {
    if (mounted) {
      _loadTicketsLocally();
    }
  });
}


  /// Initialize all data with proper error handling
  Future<void> _initializeData() async {
    setState(() => isInitializing = true);
    
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('❌ No authenticated user found');
        _showErrorMessage('Authentication required');
        return;
      }

      debugPrint('🚀 Initializing data for user: $userId');
      
      // Fetch all data concurrently
      await Future.wait([
        _loadTechnicianTickets(userId),
        _loadTechnicianStats(userId),
        _loadAvailableTechnicians(),
      ]);

    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      _showErrorMessage('Failed to load data: $e');
    } finally {
      setState(() => isInitializing = false);
    }
  }

  /// Load technician tickets with better error handling
  Future<void> _loadTechnicianTickets(String userId) async {
    try {
      debugPrint('📋 Loading tickets for technician: $userId');
      await controller.fetchTickets(userId);
      
      // Check if we have tickets in the controller
      if (controller.filteredTickets.isNotEmpty) {
        debugPrint('✅ Found ${controller.filteredTickets.length} tickets in controller');
        _loadTicketsLocally();
      } else {
        debugPrint('⚠️ No tickets found in controller, checking assignments...');
        // Try to reload assignments
        await controller.loadAssignmentsFromStorage();
        await controller.loadAssignedTicketsFromStorage();
        
        if (controller.filteredTickets.isNotEmpty) {
          debugPrint('✅ Found ${controller.filteredTickets.length} tickets after reloading');
          _loadTicketsLocally();
        } else {
          debugPrint('⚠️ Still no tickets found - may be assignment issue');
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading tickets: $e');
      throw Exception('Failed to load tickets: $e');
    }
  }

  /// Load technician statistics
  Future<void> _loadTechnicianStats(String userId) async {
    try {
      debugPrint('📊 Loading stats for technician: $userId');
      await controller.getSummaryForTechnician(userId);
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
      // Don't throw - stats are not critical
    }
  }

  /// Load available technicians
  Future<void> _loadAvailableTechnicians() async {
    try {
      debugPrint('👥 Loading available technicians');
      await controller.getAvailableTechnicians();
    } catch (e) {
      debugPrint('❌ Error loading technicians: $e');
      // Don't throw - this is not critical for viewing tickets
    }
  }

 /// Load tickets locally for filtering
void _loadTicketsLocally() {
  if (controller.filteredTickets.isEmpty) {
    debugPrint('⚠️ No tickets to load locally yet');
    return;
  }
  
  debugPrint('📋 Loading ${controller.filteredTickets.length} tickets locally');
  setState(() {
    allTickets = List.from(controller.filteredTickets);
    filteredTickets = allTickets;
  });
  debugPrint('✅ Local tickets loaded: ${allTickets.length}');
}

  /// Show error message to user
  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.redColor,
        ),
      );
    }
  }

  /// Apply comprehensive filters similar to tenant version
  void _applyFilters() {
  debugPrint("🔍 Applying filters - Status: $selectedStatus, Start: $startDate, End: $endDate");
  
  setState(() {
    filteredTickets = allTickets.where((ticket) {
      // Status filter
      if (selectedStatus != null && selectedStatus != 'All') {
        final statusMatch = ticket.statusText.en.toLowerCase() == selectedStatus!.toLowerCase();
        if (!statusMatch) return false;
      }

      // Date range filter
      if (startDate != null || endDate != null) {
        try {
          // Use the existing _parseTicketDate method from controller
          // This handles multiple date formats including ISO format
          final ticketDate = _parseTicketDateForFilter(
            (ticket.createdBy as String?) ??
            (ticket.lastUpdated as String?) ??
            (ticket.formattedDate as String?)
          );
          
          if (ticketDate == null) {
            debugPrint("⚠️ Could not parse date for ticket ${ticket.complaintId}");
            // Include tickets with unparseable dates to avoid hiding them
            return true;
          }

          // Normalize dates to compare only year/month/day
          final ticketDateOnly = DateTime(ticketDate.year, ticketDate.month, ticketDate.day);
          
          if (startDate != null) {
            final startDateOnly = DateTime(startDate!.year, startDate!.month, startDate!.day);
            if (ticketDateOnly.isBefore(startDateOnly)) {
              return false;
            }
          }
          
          if (endDate != null) {
            final endDateOnly = DateTime(endDate!.year, endDate!.month, endDate!.day);
            // Add one day to include the end date in the range
            final endDateInclusive = endDateOnly.add(const Duration(days: 1));
            if (ticketDateOnly.isAfter(endDateInclusive) || ticketDateOnly.isAtSameMomentAs(endDateInclusive)) {
              return false;
            }
          }
        } catch (e) {
          debugPrint("⚠️ Error parsing date for ticket ${ticket.complaintId}: $e");
          // Include tickets with parsing errors to avoid hiding them
          return true;
        }
      }

      return true;
    }).toList();
  });
  
  debugPrint("✅ Filtered tickets count: ${filteredTickets.length}");
}

/// Parse ticket date with multiple format support
DateTime? _parseTicketDateForFilter(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;

  // Clean the date string
  final cleanDateString = dateString.trim().replaceAll(RegExp(r'[+-]\d{2}:?\d{2}\)?'), '');

  // Try multiple date formats
  final possibleFormats = [
    "yyyy-MM-dd HH:mm:ss",
    "yyyy-MM-ddTHH:mm:ss",
    "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
    "yyyy-MM-dd",
    "dd/MM/yyyy HH:mm:ss",
    "dd/MM/yyyy",
    "MM/dd/yyyy HH:mm:ss",
    "MM/dd/yyyy",
    "yyyy/MM/dd HH:mm:ss",
    "MMM dd, yyyy hh:mm a", // Format like "Dec 25, 2024 10:30 AM"
    "EEE, dd MMM yyyy HH:mm:ss",
  ];

  for (final format in possibleFormats) {
    try {
      return DateFormat(format).parse(cleanDateString);
    } catch (e) {
      continue;
    }
  }

  // Last resort: try standard DateTime.parse
  try {
    return DateTime.parse(cleanDateString);
  } catch (e) {
    debugPrint("❌ Failed to parse date with all formats: '$dateString'");
    return null;
  }
}

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
      _applyFilters();
    }
  }

  /// Refresh data manually
  Future<void> _refreshData() async {
    await _initializeData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Get.back(),
        ),
        title: const CustomTextWidget(
          title: 'View Tickets',
          fontSize: 18,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: AppColors.black),
        //     onPressed: _refreshData,
        //   ),
        // ],
      ),  
      body: isInitializing 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistics Summary Section
                _buildStatisticsSection(),

                // Enhanced Filters Section
                _buildFiltersSection(),

                // Tickets List
                Expanded(child: _buildTicketsList()),
              ],
            ),
    );
  }

  /// Build statistics section
  /// Build statistics section
Widget _buildStatisticsSection() {
  return Obx(() {
    if (controller.isStatsLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: LinearProgressIndicator(),
      );
    }
    
    if (controller.statsErrorMessage.value.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.redColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.redColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.redColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stats Error: ${controller.statsErrorMessage.value}',
                  style: TextStyle(color: AppColors.redColor, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final stats = controller.technicianStats.value;
    if (stats?.data == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.warning),
              SizedBox(width: 8),
              Text(
                'No statistics available',
                style: TextStyle(color: AppColors.warning),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomTextWidget(
            title: 'Your Performance Summary',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryColor,
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
             _buildStatItem(
                    icon: Icons.apartment,
                    value: (stats!.data?.totalAssignedProperties ?? 0).toString(), // ✅ FIXED HERE
                    label: 'Properties',
                    color: AppColors.warning,
             ),
              _buildStatItem(
                icon: Icons.list_alt,
                value: _calculateTotalTickets(stats.data?.propertyStats ?? []).toString(),
                label: 'Total Tickets',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.pending_actions,
                value: _calculateActiveTickets(stats.data?.propertyStats ?? []).toString(),
                label: 'Active Tickets',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: _calculateResolvedTickets(stats.data?.propertyStats ?? []).toString(),
                label: 'Resolved',
                color: AppColors.onlineGreen,
              ),
            ],
          ),
        ],
      ),
    );
  });
}
  /// Calculate total tickets from stats
  int _calculateTotalTickets(List<dynamic> propertyStats) {
    return propertyStats.fold<int>(0, (sum, stat) {
      final totalComplaints = int.tryParse(stat.totalComplaints?.toString() ?? '0') ?? 0;
      return sum + totalComplaints;
    });
  }

  /// Calculate active tickets from stats
  int _calculateActiveTickets(List<dynamic> propertyStats) {
    return propertyStats.fold<int>(0, (sum, stat) {
      final unattended = int.tryParse(stat.unattended?.toString() ?? '0') ?? 0;
      final inProgress = int.tryParse(stat.inProgress?.toString() ?? '0') ?? 0;
      return sum + unattended + inProgress;
    });
  }

  /// Calculate resolved tickets from stats
  int _calculateResolvedTickets(List<dynamic> propertyStats) {
    return propertyStats.fold<int>(0, (sum, stat) {
      final resolved = int.tryParse(stat.resolved?.toString() ?? '0') ?? 0;
      return sum + resolved;
    });
  }

  /// Build tickets list
/// Build tickets list
Widget _buildTicketsList() {
  return Obx(() {
    // Show loading indicator while data is initializing OR while controller is loading
    if (isInitializing || (controller.isLoading.value && allTickets.isEmpty)) {
      return const Center(child: CircularProgressIndicator());
    }

    // Use local filteredTickets instead of controller's filteredTickets
    if (filteredTickets.isEmpty) {
      return _buildEmptyState(
        message: allTickets.isEmpty ? 'No Tickets Assigned' : 'No tickets match your filters',
        showSearchHint: allTickets.isNotEmpty,
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTickets.length,
        itemBuilder: (context, index) {
  final complaint = filteredTickets[index];
  final statusColors = getStatusColors(complaint.statusText.en ?? '');
  
  // ✅ Show unit info since tenant name is not available from API
  String locationInfo = '${complaint.unitNumber}';
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: buildTicketCard(
      complaintId: complaint.complaintId ?? '',
      propertyName: complaint.propertyName ?? '',
      category: complaint.category ?? '',
      issue: complaint.subcategory ?? '',
      status: complaint.statusText.en ?? '',
      statusColor: statusColors.textColor,
      description: complaint.description ?? '',
      date: complaint.formattedDate ?? 'No date',
      categoryIcon: Icons.build,
      images: ComplaintImages(),
      complaint: complaint,
      time: complaint.lastUpdated ?? '',
      created_by: locationInfo, // Shows "Unit Flat 21", "Unit Test1", etc.
    ),
  );
},
      ),
    );
  });
}

  /// Enhanced filters section
  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              // Status Filter
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedStatus,
                        hint: Text(
                          'Filter by Status',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black.withOpacity(0.5),
                          ),
                        ),
                        items: [
                          'All',
                          'Pending',
                          'In Progress',
                          'Resolved',
                        ].map((status) {
                          return DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.black,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedStatus = value);
                          _applyFilters();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Enhanced Date Range Filter
          Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                // Start Date
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.black.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            startDate != null 
                                ? DateFormat('MMM dd').format(startDate!)
                                : 'Select',
                            style: TextStyle(
                              fontSize: 14,
                              color: startDate != null 
                                  ? AppColors.secondaryColor 
                                  : AppColors.black.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Divider
                Container(
                  height: 24,
                  width: 1,
                  color: AppColors.darkGrey.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                ),
                // End Date
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'To',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.black.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            endDate != null 
                                ? DateFormat('MMM dd').format(endDate!)
                                : 'Select',
                            style: TextStyle(
                              fontSize: 14,
                              color: endDate != null 
                                  ? AppColors.secondaryColor 
                                  : AppColors.black.withOpacity(0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Calendar Icon and Clear Button
                Row(
                  children: [
                    if (startDate != null || endDate != null)
                      InkWell(
                        onTap: () {
                          setState(() {
                            startDate = null;
                            endDate = null;
                          });
                          _applyFilters();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.clear,
                            size: 18,
                            color: AppColors.redColor,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.secondaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state widget
  Widget _buildEmptyState({required String message, bool showSearchHint = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering_outlined,
            size: 80,
            color: AppColors.lightGrey,
          ),
          const SizedBox(height: 16),
          CustomTextWidget(
            title: message,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.black500 ?? AppColors.black,
          ),
          if (showSearchHint) const SizedBox(height: 8),
          if (showSearchHint)
            CustomTextWidget(
              title: "Try adjusting your search criteria",
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGrey,
            ),
          if (allTickets.isEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

 Widget _buildStatItem({
  required IconData icon,
  required String value,
  required String label,
  Color color = AppColors.primaryColor,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // ✅ ADDED - Prevents overflow
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16, // ✅ REDUCED from 18 to 16
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1, // ✅ ADDED - Limit to 1 line
                overflow: TextOverflow.ellipsis, // ✅ ADDED - Handle overflow
              ),
              const SizedBox(height: 2), // ✅ ADDED - Small spacing
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11, // ✅ REDUCED from 12 to 11
                  color: Colors.black,
                ),
                maxLines: 1, // ✅ ADDED - Limit to 1 line
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}

class StatusColors {
  final Color backgroundColor;
  final Color textColor;

  StatusColors({required this.backgroundColor, required this.textColor});
}

StatusColors getStatusColors(String status) {
  final normalizedStatus = status.trim().toLowerCase();

  switch (normalizedStatus) {
    case 'pending':
      return StatusColors(
        backgroundColor: AppColors.warning,
        textColor: AppColors.primaryColor,
      );
    case 'rectified':
      return StatusColors(
        backgroundColor: AppColors.onlineGreen,
        textColor: AppColors.onlineGreenDark,
      );
    case 'in progress':
    case 'processing':
      return StatusColors(
        backgroundColor: Colors.blue,
        textColor: Colors.blue,
      );
    case 'resolved':
    case 'completed':
    case 'closed':
      return StatusColors(
        backgroundColor: Colors.green,
        textColor: Colors.green,
      );
    case 'rejected':
    case 'cancelled':
    case 'canceled':
      return StatusColors(
        backgroundColor: AppColors.redColor.withOpacity(0.1),
        textColor: AppColors.redColor,
      );
    case 'on hold':
    case 'hold':
      return StatusColors(
        backgroundColor: AppColors.blueColor.withOpacity(0.1),
        textColor: AppColors.blueColor,
      );
    default:
      return StatusColors(
        backgroundColor: AppColors.grey.withOpacity(0.1),
        textColor: AppColors.grey,
      );
  }
}