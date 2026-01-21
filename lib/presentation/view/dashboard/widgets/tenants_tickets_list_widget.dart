import 'package:majan/core/utils/date_formater.dart';
import 'package:majan/data/model/technican_ticket_view_model.dart'
    show TicketModel, TicketStatus;
import 'package:majan/data/model/tenatpropertymodel.dart';
import 'package:majan/data/model/ticket_list_response_model.dart';
import 'package:majan/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
import 'package:majan/presentation/view/dashboard/widgets/technician_view_tickets.dart';
import 'package:majan/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import 'tenants_create_ticket_screen.dart';
import 'tenants_ticket_details_screen.dart';


class TenantsTicketsListWidget extends StatefulWidget {
  const TenantsTicketsListWidget({super.key});

  @override
  State<TenantsTicketsListWidget> createState() =>
      _TenantsTicketsListWidgetState();
}

class _TenantsTicketsListWidgetState extends State<TenantsTicketsListWidget> {
  final TenantsTicketsController controller = Get.put(TenantsTicketsController());

  List<Complaint> complaints = [];
  List<Complaint> filteredComplaints = [];
  
  // Filter variables
  String? selectedStatus;
  String? selectedCategory;
  DateTime? startDate;
  DateTime? endDate;

  @override
void initState() {
  super.initState();
  // Call loadData which handles the proper sequence
  _loadData();
}

Future<void> _loadData() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    // First load complaints
    await controller.fetchTenantComplaints();
    
    // Then load summary (with fallback to complaints data)
    await controller.getSummaryForTenant(userId);
    
    // Update the filtered lists
    setState(() {
      complaints = controller.complaints;
      filteredComplaints = complaints;
    });
  }
}

  /// Fetch complaints from API
  Future<void> _loadComplaints() async {
    try {
      await controller.fetchTenantComplaints();
      setState(() {
        complaints = controller.complaints;
        filteredComplaints = complaints;
      });
    } catch (e) {
      debugPrint("Error loading complaints: $e");
    }
  }

 /// Apply filters to the complaints list
void _applyFilters() {
  debugPrint("Applying filters - Status: $selectedStatus, Start: $startDate, End: $endDate");
  
  setState(() {
    filteredComplaints = complaints.where((complaint) {
      // Status filter
      if (selectedStatus != null && selectedStatus != 'All') {
        final statusMatch = complaint.statusText.en.toLowerCase() == selectedStatus!.toLowerCase();
        if (!statusMatch) return false;
      }

      // Date range filter
      if (startDate != null || endDate != null) {
        try {
          // Use the helper method to parse the date
          final complaintDate = _parseComplaintDate(
            complaint.date ?? complaint.lastUpdated ?? complaint.formattedDate
          );
          
          if (complaintDate == null) {
            debugPrint("⚠️ Could not parse date for complaint ${complaint.complaintId}");
            // Include complaints with unparseable dates to avoid hiding them
            return true;
          }

          // Normalize dates to compare only year/month/day
          final complaintDateOnly = DateTime(
            complaintDate.year,
            complaintDate.month,
            complaintDate.day
          );
          
          if (startDate != null) {
            final startDateOnly = DateTime(
              startDate!.year,
              startDate!.month,
              startDate!.day
            );
            if (complaintDateOnly.isBefore(startDateOnly)) {
              return false;
            }
          }
          
          if (endDate != null) {
            final endDateOnly = DateTime(
              endDate!.year,
              endDate!.month,
              endDate!.day
            );
            // Include the end date by comparing with the next day
            final endDateInclusive = endDateOnly.add(const Duration(days: 1));
            if (complaintDateOnly.isAfter(endDateInclusive) || 
                complaintDateOnly.isAtSameMomentAs(endDateInclusive)) {
              return false;
            }
          }
        } catch (e) {
          debugPrint("⚠️ Error parsing date for complaint ${complaint.complaintId}: $e");
          // Include complaints with parsing errors to avoid hiding them
          return true;
        }
      }

      return true;
    }).toList();
  });
  
  debugPrint("Filtered complaints count: ${filteredComplaints.length}");
}

/// Parse complaint date with multiple format support
DateTime? _parseComplaintDate(String? dateString) {
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
  /// Select date for filtering
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
              primary: AppColors.secondaryColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.secondaryColor, // Button text color
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

  @override
  void dispose() {
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomTextWidget(
          title: "Maintenance",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [notificationNavigation()],
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth2),
        child: Stack(
          children: [
            Column(
              children: [
                _buildSummarySection(),
                
                // Filters Section
                _buildFiltersSection(),

                // Tickets List
                Expanded(
                  child: Obx(() {
                    if (controller.isComplaintLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (controller.complaintErrorMessage.isNotEmpty) {
                      return Center(
                        child: CustomTextWidget(
                          title: controller.complaintErrorMessage.value,
                          color: AppColors.black,
                          fontSize: Get.height * 0.018,
                        ),
                      );
                    }

                    // Use filteredComplaints
                    if (filteredComplaints.isEmpty) {
                      return _buildEmptyState(
                        message: "No Complaints found",
                        showSearchHint: true
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth1,
                        vertical: screenHeight1,
                      ),
                      itemCount: filteredComplaints.length,
                      itemBuilder: (context, index) {
                        return _buildComplaintCard(filteredComplaints[index]);
                      },
                    );
                  }),
                ),
              ],
            ),
            Positioned(
              bottom: screenHeight * 0.05,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: Get.width * 0.9,
                  child: CustomButtonWidget(
                    buttonColor: AppColors.secondaryColor,
                    buttonTitle: "Create Maintenance",
                    buttonTextColor: AppColors.white,
                    onPressed: () async {
                      try {
                        await controller.fetchTenantProperties();

                        if (controller.properties.isNotEmpty) {
                          _showPropertySelectionBottomSheet(controller.properties);
                        } else {
                          Get.snackbar("No Properties", "No properties found for this user.");
                        }
                      } catch (e) {
                        Get.snackbar("Error", "Failed to fetch properties: $e");
                      }
                    },
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Build filters section
  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
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
              const SizedBox(width: 8),
              // Category Filter
              // Expanded(
              //   child: Container(
              //     height: 48,
              //     decoration: BoxDecoration(
              //       borderRadius: BorderRadius.circular(6),
              //       border: Border.all(color: AppColors.darkGrey.withOpacity(0.2)),
              //     ),
              //     child: Padding(
              //       padding: const EdgeInsets.symmetric(horizontal: 12),
              //       child: DropdownButtonHideUnderline(
              //         child: DropdownButton<String>(
              //           isExpanded: true,
              //           value: selectedCategory,
              //           hint: Text(
              //             'Filter by Category',
              //             style: TextStyle(
              //               fontSize: 14,
              //               color: AppColors.black.withOpacity(0.5),
              //             ),
              //           ),
              //           items: _getUniqueCategories().map((category) {
              //             return DropdownMenuItem<String>(
              //               value: category,
              //               child: Text(
              //                 category,
              //                 style: const TextStyle(
              //                   fontSize: 14,
              //                   color: AppColors.black,
              //                 ),
              //               ),
              //             );
              //           }).toList(),
              //           onChanged: (value) {
              //             setState(() => selectedCategory = value);
              //             _applyFilters();
              //           },
              //         ),
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 8),
          // Date Range Filter
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

  void _showPropertySelectionBottomSheet(List<TenantPropertyModel> properties) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                title: "Select Property",
                fontSize: Get.height * 0.02,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                itemCount: properties.length,
                itemBuilder: (context, index) {
                  final property = properties[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: CustomTextWidget(
                      title: "${property.propertyTitle} - Flat No: ${property.unitNumber ?? 'N/A'}",
                      fontSize: Get.height * 0.016,
                      color: AppColors.black,
                    ),
                    onTap: () {
                      debugPrint(
                        'Selected Property: ${property.propertyTitle},  Flat No: ${property.unitNumber}, unitAddressId: ${property.unitAddressId}, userId: $userId',
                      );

                      Get.back(); // Close bottom sheet
                      Get.to(() => TenantsCreateTicketScreen(
                            propertyName: property.propertyTitle,
                            propertyId: property.propertyId,
                            unitAddressId: property.unitAddressId,
                            userId: userId,
                            FlatNO: property.unitNumber,
                          
                          ));
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSummarySection() {
  return Obx(() {
    final isDebugMode = false; // Set to false in production
    
    debugPrint('[SummaryWidget] Building with:');
    debugPrint('- isLoading: ${controller.isStatsLoading.value}');
    debugPrint('- error: ${controller.statsErrorMessage.value}');
    debugPrint('- stats: ${controller.technicianStats.value?.propertyStats.length} properties');
    debugPrint('- complaints count: ${controller.complaints.length}');
    
    if (controller.isStatsLoading.value) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: LinearProgressIndicator(),
      );
    }

    final summary = controller.technicianStats.value;
    
    // Calculate totals with enhanced debugging
    final propertyCount = int.tryParse(summary?.totalProperties ?? '0') ?? 0;
    
    int totalTickets = 0;
    int totalActive = 0;
    int totalResolved = 0;
    
    if (summary?.propertyStats.isNotEmpty ?? false) {
      debugPrint('[SummaryWidget] Using API data for calculations');
      
      for (final stat in summary!.propertyStats) {
        final tickets = int.tryParse(stat.totalComplaints) ?? 0;
        final started = int.tryParse(stat.startedWorking) ?? 0;
        final inProgress = int.tryParse(stat.inProgress) ?? 0;
        final resolved = int.tryParse(stat.resolved) ?? 0;
        
        totalTickets += tickets;
        totalActive += started + inProgress;
        totalResolved += resolved;
      }
    } else {
      debugPrint('[SummaryWidget] Using fallback calculation from complaints');
      
      totalTickets = controller.complaints.length;
      
      for (final complaint in controller.complaints) {
        final status = complaint.status.toLowerCase();
        final statusText = complaint.statusText.en.toLowerCase();
        
        if (status.contains('resolved') || status.contains('completed') || 
            statusText.contains('resolved') || statusText.contains('completed')) {
          totalResolved++;
        } else {
          totalActive++;
        }
      }
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CustomTextWidget(
                title: 'Your Maintenance Summary',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryColor,
              ),
              if (isDebugMode) ...[
                Row(
                  children: [
                    Icon(
                      summary?.propertyStats.isNotEmpty ?? false 
                        ? Icons.api : Icons.list,
                      size: 16,
                      color: summary?.propertyStats.isNotEmpty ?? false 
                        ? AppColors.onlineGreen : AppColors.warning,
                    ),
                    SizedBox(width: 4),
                    Text(
                      summary?.propertyStats.isNotEmpty ?? false ? 'API' : 'Fallback',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              _buildStatItem(
                icon: Icons.home_work_outlined,
                value: propertyCount.toString(), 
                label: 'Properties',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.list_alt,
                value: totalTickets.toString(),
                label: 'Total Complaints',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.pending_actions,
                value: totalActive.toString(),
                label: 'Active Complaints',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: totalResolved.toString(),
                label: 'Resolved',
                color: AppColors.onlineGreen,
              ),
            ],
          ),
          
          // Debug information
          if (isDebugMode)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Debug Info:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'API Stats: ${summary?.propertyStats.length ?? 0}',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                    Text(
                      'Complaints: ${controller.complaints.length}',
                      style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                    ),
                    Text(
                      'Error: ${controller.statsErrorMessage.value}',
                      style: TextStyle(fontSize: 9, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  });
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
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),  // Reduced padding
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),  // Slightly smaller icon
        ),
        const SizedBox(width: 6),  // Reduced spacing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,  // Important: don't expand unnecessarily
            children: [
              FittedBox(  // Ensures value text scales down if needed
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,  // Reduced from 18
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 2),  // Small spacing between value and label
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,  // Reduced from 12
                  color: Colors.black,
                  height: 1.2,  // Tighter line height
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
  /// Builds a single ticket card
  Widget _buildComplaintCard(Complaint complaint) {
    return InkWell(
      onTap: () {
        Get.to(() => TicketDetailsScreen(
          complaintId: complaint.complaintId,
          previewImageUrl: _getFirstAvailableImage(complaint),
        ));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: screenHeight1),
        padding: EdgeInsets.all(screenWidth1),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextWidget(
              title: "#${complaint.complaintNumber}",
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w600,
              color: AppColors.black800,
            ),
            SizedBox(height: screenHeight05),
            CustomTextWidget(
              title: complaint.category,
              fontSize: Get.height * 0.018,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
              maxLines: 2,
            ),
            CustomTextWidget(
              title: complaint.description,
              fontSize: Get.height * 0.014,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
              maxLines: 2,
            ),
            SizedBox(height: screenHeight05),
             Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomTextWidget(
                  title: "Last updated on ${complaint.formattedDate}",
                  fontSize: Get.height * 0.014,
                  fontWeight: FontWeight.w400,
                  color: AppColors.black500,
                ),
                _buildStatusChipFromComplaint(complaint.statusText.en),
              ],
            ),
            kHeight(0.02),
            Container(
              height: Get.height * 0.001,
              width: Get.width * 0.90,
              color: AppColors.grey.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get first available image
String _getFirstAvailableImage(Complaint complaint) {
  // if (complaint.complaintImages.isNotEmpty) return complaint.images.first;

  if (complaint.complaintImages.tenantUploaded.isNotEmpty) {
    return complaint.complaintImages.tenantUploaded.first;
  }

  if (complaint.complaintImages.adminUploaded.isNotEmpty) {
    return complaint.complaintImages.adminUploaded.first;
  }

  if (complaint.complaintImages.technicianUploaded.isNotEmpty) {
    return complaint.complaintImages.technicianUploaded.first;
  }

  if (complaint.complaintImages.adminTechnicianUploaded.isNotEmpty) {
    return complaint.complaintImages.adminTechnicianUploaded.first;
  }

  return '';
}

// Helper method to check if complaint has images
bool _hasImages(Complaint? complaint) {
  if (complaint == null) return false;
  
  // return complaint.images.isNotEmpty ||
     return complaint.complaintImages.tenantUploaded.isNotEmpty ||
      complaint.complaintImages.adminUploaded.isNotEmpty ||
      complaint.complaintImages.technicianUploaded.isNotEmpty ||
      complaint.complaintImages.adminTechnicianUploaded.isNotEmpty;
}

bool _canAssignOrReassign(String status, Complaint? complaint) {
  // Allow assignment for pending tickets
  if (status.toLowerCase() == 'pending') return true;
  
  final reassignableStatuses = ['assigned', 'in_progress'];
  return reassignableStatuses.contains(status.toLowerCase()) && _canReassign(complaint);
}

bool _canReassign(Complaint? complaint) {

  return true;
}

  /// Builds the status chip
  Widget _buildStatusChipFromComplaint(String statusText) {
    Color backgroundColor;
    Color textColor;

    switch (statusText.toLowerCase()) {
      case "pending":
        backgroundColor = AppColors.primaryColor.withOpacity(0.1);
        textColor = AppColors.primaryColor;
        break;
      case "rectified":
        backgroundColor = AppColors.onlineGreen.withOpacity(0.1);
        textColor = AppColors.onlineGreenDark;
        break;
      case "in progress":
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        break;
      case "completed":
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      default:
        backgroundColor = AppColors.grey.withOpacity(0.1);
        textColor = AppColors.grey;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.010,
        vertical: screenHeight * 0.002,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomTextWidget(
        title: statusText,
        fontSize: Get.height * 0.012,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget buildComplaintsList() {
    return Obx(() {
      if (controller.isComplaintLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (!controller.hasComplaints.value) {
        return _buildEmptyState(
          message: controller.complaintErrorMessage.value,
          showSearchHint: controller.complaintErrorMessage.value == "No complaints found",
        );
      }
      
      return ListView.builder(
        itemCount: filteredComplaints.length,
        itemBuilder: (context, index) => _buildComplaintCard(filteredComplaints[index]),
      );
    });
  }

  Widget _buildEmptyState({required String message, bool showSearchHint = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: Get.height * 0.08,
            color: AppColors.lightGrey,
          ),
          SizedBox(height: screenHeight1),
          CustomTextWidget(
            title: message,
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w600,
            color: AppColors.black500,
          ),
          if (showSearchHint) SizedBox(height: screenHeight05),
          if (showSearchHint)
            CustomTextWidget(
              title: "Try adjusting your search criteria",
              fontSize: Get.height * 0.016,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGrey,
            ),
        ],
      ),
    );
  }
}
  /// Show Create Ticket Dialog
  void _showCreateTicketDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomTextWidget(
            title: "Create New Ticket",
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w600,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Ticket Category",
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.lightGrey,
                    fontSize: Get.height * 0.016,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(height: screenHeight1),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe the issue",
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.lightGrey,
                    fontSize: Get.height * 0.016,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: CustomTextWidget(
                title: "Cancel",
                color: AppColors.black500,
                fontSize: Get.height * 0.016,
              ),
            ),
            TextButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    descriptionController.text.isNotEmpty) {
                  Navigator.pop(context);
                  _createNewComplaint(
                      titleController.text, descriptionController.text);
                }
              },
              child: CustomTextWidget(
                title: "Create",
                color: AppColors.primaryColor,
                fontSize: Get.height * 0.016,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Add new ticket
void _createNewComplaint(String category, String description) {
  final now = DateTime.now();
  final formattedDate = DateFormatter.formatCurrentDate();

  final newComplaint = Complaint(
    complaintId: 'CID-${now.millisecondsSinceEpoch.toString().substring(8)}',
    complaintNumber: 'CMP-${now.millisecondsSinceEpoch.toString().substring(8)}',
    description: description,
    replyByTechnician: null,  // Changed from empty string to null
    replyByAdmin: null,      
    amountPaid: null,       
    amountPaidStatus: null, 
    date: formattedDate,
    lastUpdated: null,       
    lastUpdatedByAdmin: null,
    addedByAdmin: false,     
    statusText: StatusText(en: 'Pending'),
    status: 'pending',
    category: category,
    subcategory: '',         
    propertyName: '',     
    unitNumber: '',          
    unitType: '',           
    fullAddress: '',         
    flatnoId: '',            
    // images: [],              
    assignedTechnicians: [], 
    complaintImages: ComplaintImages(  
      tenantUploaded: [],
      adminUploaded: [],
      technicianUploaded: [],
      adminTechnicianUploaded: [],
    ),
  );

  // setState(() {
  //   complaints.insert(0, newComplaint);
  //   filteredComplaints = complaints;
  // });
}


