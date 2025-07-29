import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart'
    show TicketModel, TicketStatus;
import 'package:dar_al_safwa/data/model/tenatpropertymodel.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_view_tickets.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_create_ticket_screen.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/notification_navigation_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

import '../../../../../../core/constants/custom_size.dart';
import '../../../../../../core/theme/app_colors.dart';


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
    _loadComplaints(); // Load from API instead of mock data
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
  child: filteredComplaints.isEmpty
      ? _buildEmptyState()
      : ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth1,
            vertical: screenHeight1,
          ),
          itemCount: filteredComplaints.length,
          itemBuilder: (context, index) {
            return _buildComplaintCard(filteredComplaints[index]);
          },
        ),
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
    Container(
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
                  title: property.propertyTitle,
                  fontSize: Get.height * 0.016,
                  color: AppColors.black,
                ),
                subtitle: CustomTextWidget(
                  title: "ID: ${property.id}",
                  fontSize: Get.height * 0.014,
                  color: AppColors.grey,
                ),
                onTap: () {
                  debugPrint(
                    'Selected Property: ${property.propertyTitle}, ID: ${property.id},unitAddressId: ${property.unitAddressId}, userId: $userId,propertyName: ${property.propertyTitle},',
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
  );
}

  /// Builds a single ticket card
  Widget _buildComplaintCard(Complaint complaint) {
  return InkWell(
    onTap: () {
      Get.to(() => TicketDetailsScreen(complaint: complaint,
        // complaintId: complaint.complaintId ?? '',
    
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
                title: "Last updated on ${complaint.date}",
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


  /// Empty state
  Widget _buildEmptyState() {
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
            title: "No tickets found",
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w600,
            color: AppColors.black500,
          ),
          SizedBox(height: screenHeight05),
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

  /// Show Create Ticket Dialog
  void _showCreateTicketDialog() {
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
  final now = DateTime.now().toString();
  final newComplaint = Complaint(
    complaintId: 'CID-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    complaintNumber: 'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    description: description,
    replyByTechnician: null,
    replyByAdmin: null,
    amountPaid: null,
    amountPaidStatus: null,
    date: now,
    lastUpdated: null,
    lastUpdatedByAdmin: null,
    addedByAdmin: false,
    statusText: StatusText(en: 'Pending'),
    status: 'pending',
    category: category,
    subcategory: '', // You can add subcategory if needed
    propertyName: '', // Add property name if available
    unitNumber: '', // Add unit number if available
    unitType: '', // Add unit type if available
    fullAddress: '', // Add full address if available
    flatnoId: '', // Add flat ID if available
    images: [], // Add images if available
    assignedTechnicians: [], // Add technicians if available
    complaintImages: ComplaintImages(
      tenantUploaded: [],
      adminUploaded: [],
      technicianUploaded: [],
      adminTechnicianUploaded: [],
    ),
  );

  setState(() {
    complaints.insert(0, newComplaint);
    filteredComplaints = complaints;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: CustomTextWidget(
        title: "Complaint created successfully!",
        color: AppColors.white,
        fontSize: Get.height * 0.016,
      ),
      backgroundColor: Colors.green,
    ),
  );
}
}