import 'package:dar_al_safwa/core/utils/date_formater.dart';
import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart'
    show TicketModel, TicketStatus;
import 'package:dar_al_safwa/data/model/tenatpropertymodel.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_view_tickets.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/notification_navigation_widget.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final TenantsTicketsController controller = Get.put(TenantsTicketsController());

  List<Complaint> complaints = [];
  List<Complaint> filteredComplaints = [];

  @override
  void initState() {
    super.initState();
    _loadComplaints(); 
    _loadData();
  }
  
  

  Future<void> _loadData() async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId != null) {
    await controller.getSummaryForTenant(userId);
    await controller.fetchTenantComplaints();
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



 void _searchTickets(String query) {
  setState(() {
    if (query.isEmpty) {
      filteredComplaints = complaints;
    } else {
      filteredComplaints = complaints.where((complaint) {
        return complaint.category.toLowerCase().contains(query.toLowerCase()) ||
            complaint.description.toLowerCase().contains(query.toLowerCase()) ||
            complaint.complaintNumber.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  });
}



  @override
  void dispose() {
    _searchController.dispose();
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
          title: "Tickets",
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
                // Search Bar
                CustomTextFieldWidget(
                  hintText: "Search ticket by ID or Issue...",
                  keyboardType: TextInputType.text,
                  prefixIcon: Icons.search,
                  controller: _searchController,
                  onChanged: _searchTickets,
                ),

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

    // Use filteredComplaints if search is applied, else controller.complaints
    final complaintsList = filteredComplaints.isEmpty && _searchController.text.isEmpty
        ? controller.complaints
        : filteredComplaints;

    if (complaintsList.isEmpty) {
     return _buildEmptyState(
  message: "No complaints found", 
  showSearchHint: false
);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth1,
        vertical: screenHeight1,
      ),
      itemCount: complaintsList.length,
      itemBuilder: (context, index) {
        return _buildComplaintCard(complaintsList[index]);
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
                    buttonTitle: "Create Ticket",
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
                  // subtitle: CustomTextWidget(
                  //   title: "ID: ${property.id}",
                  //   fontSize: Get.height * 0.014,
                  //   color: AppColors.grey,
                  // ),
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
                        ));
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
    isScrollControlled: true, // <-- Allows full height if needed
  );
}

Widget _buildSummarySection() {
  return Obx(() {
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
    
    if (controller.statsErrorMessage.value.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              controller.statsErrorMessage.value,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 8),
            // Show fallback stats from complaints
            if (controller.complaints.isNotEmpty)
              Text(
                'Fallback: Found ${controller.complaints.length} complaints',
                style: const TextStyle(color: Colors.orange, fontSize: 12),
              ),
          ],
        ),
      );
    }

    final summary = controller.technicianStats.value;
    
    // Calculate totals - handle null/empty cases gracefully
    final propertyCount = summary?.propertyStats.length ?? 0;
    
    // Enhanced calculation with more debugging
    int totalTickets = 0;
    int totalActive = 0;
    int totalResolved = 0;
    
    if (summary?.propertyStats.isNotEmpty ?? false) {
      // API-based calculation
      debugPrint('[SummaryWidget] Using API data for calculations');
      
      for (final stat in summary!.propertyStats) {
        final tickets = int.tryParse(stat.totalComplaints) ?? 0;
        final started = int.tryParse(stat.startedWorking) ?? 0;
        final inProgress = int.tryParse(stat.inProgress) ?? 0;
        final resolved = int.tryParse(stat.resolved) ?? 0;
        
        debugPrint('[SummaryWidget] Property ${stat.propertyName}: $tickets total, $started started, $inProgress in progress, $resolved resolved');
        
        totalTickets += tickets;
        totalActive += started + inProgress;
        totalResolved += resolved;
      }
    } else {
      // Fallback calculation from complaints list
      debugPrint('[SummaryWidget] Using fallback calculation from complaints');
      
      totalTickets = controller.complaints.length;
      
      for (final complaint in controller.complaints) {
        final status = complaint.status.toLowerCase();
        final statusText = complaint.statusText.en.toLowerCase();
        
        if (status.contains('resolved') || status.contains('completed') || 
            statusText.contains('resolved') || statusText.contains('completed')) {
          totalResolved++;
        } else {
          totalActive++; // Everything else is considered active
        }
      }
      
      debugPrint('[SummaryWidget] Fallback calculation: $totalTickets total, $totalActive active, $totalResolved resolved');
    }

    // Show debug info in development
    final isDebugMode = true; // Set to false in production

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
                title: 'Your Tickets Summary',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryColor,
              ),
              if (isDebugMode)
                Icon(
                  summary?.propertyStats.isNotEmpty ?? false 
                    ? Icons.api : Icons.list,
                  size: 16,
                  color: summary?.propertyStats.isNotEmpty ?? false 
                    ? AppColors.onlineGreen : AppColors.warning,
                ),
            ],
          ),
          
          if (isDebugMode && (summary?.propertyStats != null && summary!.propertyStats.isEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              // child: Text(
              //   'Using fallback calculation from ${controller.complaints.length} complaints',
              //   style: const TextStyle(
              //     fontSize: 10,
              //     color: Colors.orange,
              //     fontStyle: FontStyle.italic,
              //   ),
              // ),
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
                icon: Icons.home_work_outlined,
                value: propertyCount > 0 ? propertyCount.toString() : '1', // Show at least 1 if we have complaints
                label: 'Properties',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.list_alt,
                value: totalTickets.toString(),
                label: 'Total Tickets',
                color: AppColors.warning,
              ),
              _buildStatItem(
                icon: Icons.pending_actions,
                value: totalActive.toString(),
                label: 'Active Tickets',
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
              child: Text(
                'Debug: API Stats=${summary?.propertyStats.length ?? 0}, Complaints=${controller.complaints.length}',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
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

  /// Builds a single ticket card
  Widget _buildComplaintCard(Complaint complaint) {
  return InkWell(
    onTap: () {
      Get.to(() => TicketDetailsScreen(complaint: complaint,
      // complaintId: complaint.complaintId,
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
  
  // Add this widget inside your _TenantsTicketsListWidgetState class
// Widget _buildComplaintItem(Complaint complaint) {
//   return InkWell(
//     onTap: () {
//       Get.to(() => TicketDetailsScreen(complaint: complaint));
//     },
//     child: Container(
//       margin: EdgeInsets.only(bottom: screenHeight1),
//       padding: EdgeInsets.all(screenWidth1),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CustomTextWidget(
//             title: "#${complaint.complaintNumber}",
//             fontSize: Get.height * 0.014,
//             fontWeight: FontWeight.w600,
//             color: AppColors.black800,
//           ),
//           SizedBox(height: screenHeight05),
//           CustomTextWidget(
//             title: complaint.category,
//             fontSize: Get.height * 0.018,
//             fontWeight: FontWeight.w600,
//             color: AppColors.black,
//             maxLines: 2,
//           ),
//           CustomTextWidget(
//             title: complaint.description,
//             fontSize: Get.height * 0.014,
//             fontWeight: FontWeight.w400,
//             color: AppColors.black,
//             maxLines: 2,
//           ),
//           SizedBox(height: screenHeight05),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               CustomTextWidget(
//                 title: "Last updated on ${complaint.date}",
//                 fontSize: Get.height * 0.014,
//                 fontWeight: FontWeight.w400,
//                 color: AppColors.black500,
//               ),
//               _buildStatusChipFromComplaint(complaint.statusText.en),
//             ],
//           ),
//         ],
//       ),
//     ),
//   );
// }

  /// Empty state
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
      itemCount: controller.complaints.length,
      itemBuilder: (context, index) => _buildComplaintCard(controller.complaints[index]),
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
    images: [],              
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

