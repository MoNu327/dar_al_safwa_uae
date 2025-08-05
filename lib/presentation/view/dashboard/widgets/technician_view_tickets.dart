import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/data/model/technician_complaints_response.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_ticket_card_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
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
  String? selectedStatus;
  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      controller.fetchTickets(userId).then((_) {
        _applyFilters();
      });
      controller.getAvailableTechnicians();
      controller.getSummaryForTechnician(userId); // Load technician stats
    }
  }
void _applyFilters() {
  debugPrint("Applying filters - Status: $selectedStatus, Start: $startDate, End: $endDate");
  controller.applyFilters(
    status: selectedStatus == 'All' ? null : selectedStatus,
    startDate: startDate,
    endDate: endDate,
  );
  debugPrint("Filtered tickets count: ${controller.filteredTickets.length}");
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
      ),
      body: Column(
        children: [
          // Statistics Summary Section
          Obx(() {
            if (controller.isStatsLoading.value) {
              return const Padding(
                padding: EdgeInsets.all(8.0),
                child: LinearProgressIndicator(),
              );
            }
            
            if (controller.statsErrorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  controller.statsErrorMessage.value,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final stats = controller.technicianStats.value;
            if (stats == null) return const SizedBox();

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
    value: (stats.data?.propertyStats.length ?? 0).toString(),
    label: 'Properties',
    color: AppColors.warning
  ),
  _buildStatItem(
    icon: Icons.list_alt,
    value: (stats.data?.propertyStats.fold<int>(0, (sum, stat) {
      final totalComplaints = int.tryParse(stat.totalComplaints) ?? 0;
      return sum + totalComplaints;
    }) ?? 0).toString(),
    label: 'Total Tickets',
    color: AppColors.warning
  ),
  _buildStatItem(
    icon: Icons.pending_actions,
    value: (stats.data?.propertyStats.fold<int>(0, (sum, stat) {
      final unattended = int.tryParse(stat.unattended) ?? 0;
      final inProgress = int.tryParse(stat.inProgress) ?? 0;
      return sum + unattended + inProgress;
    }) ?? 0).toString(),
    label: 'Active Tickets',
    color: AppColors.warning,
  ),
  _buildStatItem(
    icon: Icons.check_circle,
    value: (stats.data?.propertyStats.fold<int>(0, (sum, stat) {
      final resolved = int.tryParse(stat.resolved) ?? 0;
      return sum + resolved;
    }) ?? 0).toString(),
    label: 'Resolved',
    color: AppColors.onlineGreen,
  ),
],
                  ),
                ],
              ),
            );
          }),

          // Filters Section
      Padding(
  padding: const EdgeInsets.all(12.0),
  child: Row(
    children: [
      // Status Filter Dropdown
      Expanded(
        child: Container(
          height: 48, // Fixed height to match date picker
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
      // Date Range Selector
      Expanded(
        child: Container(
          height: 48, // Same height as filter dropdown
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
              // Calendar Icon
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
        ),
      ),
  ],
  ),
),

          // Tickets List
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filteredTickets.isEmpty) {
                return const Center(child: Text('No Tickets Found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.filteredTickets.length,
                itemBuilder: (context, index) {
                  final complaint = controller.filteredTickets[index];
                  final statusColors = getStatusColors(complaint.statusText.en ?? '');
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
                    ),
                  );
                },
              );
            }),
          ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
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
    case 'In Progress':
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
