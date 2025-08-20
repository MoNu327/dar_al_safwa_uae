// import 'package:majan/data/model/technican_ticket_view_model.dart'
//     show TicketModel, TicketStatus;
// import 'package:majan/data/model/tenatpropertymodel.dart';
// import 'package:majan/data/model/ticket_list_response_model.dart';
// import 'package:majan/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
// import 'package:majan/presentation/view/dashboard/widgets/technician_view_tickets.dart';
// import 'package:majan/presentation/view/dashboard/widgets/tenants_create_ticket_screen.dart';
// import 'package:majan/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart';
// import 'package:majan/presentation/widgets/custom_elevated_button.dart';
// import 'package:majan/presentation/widgets/custom_text_formfield_widget.dart';
// import 'package:majan/presentation/widgets/custom_text_widget.dart';
// import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:get/get.dart';

// import '../../../../../../core/constants/custom_size.dart';
// import '../../../../../../core/theme/app_colors.dart';


// class TenantsTicketsListWidget extends StatefulWidget {
//   const TenantsTicketsListWidget({super.key});

//   @override
//   State<TenantsTicketsListWidget> createState() =>
//       _TenantsTicketsListWidgetState();
// }

// class _TenantsTicketsListWidgetState extends State<TenantsTicketsListWidget> {
//   final TextEditingController _searchController = TextEditingController();
//   final TenantsTicketsController controller = Get.put(TenantsTicketsController());

//   List<Complaint> complaints = [];
//   List<Complaint> filteredComplaints = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadComplaints(); // Load from API instead of mock data
//   }

//   /// Fetch complaints from API
//   Future<void> _loadComplaints() async {
//     try {
//       await controller.fetchTenantComplaints();
//       setState(() {
//         complaints = controller.complaints;
//         filteredComplaints = complaints;
//       });
//     } catch (e) {
//       debugPrint("Error loading complaints: $e");
//     }
//   }

//  void _searchTickets(String query) {
//     setState(() {
//       if (query.isEmpty) {
//         filteredComplaints = complaints;
//       } else {
//         filteredComplaints = complaints.where((complaint) {
//           return complaint.category.toLowerCase().contains(query.toLowerCase()) ||
//                  complaint.description.toLowerCase().contains(query.toLowerCase()) ||
//                  complaint.complaintNumber.toLowerCase().contains(query.toLowerCase());
//         }).toList();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.white,
//       appBar: AppBar(
//         backgroundColor: AppColors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: AppColors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: CustomTextWidget(
//           title: "Tickets",
//           fontSize: Get.height * 0.022,
//           fontWeight: FontWeight.w600,
//           color: AppColors.black,
//         ),
//         actions: [notificationNavigation()],
//       ),
//       body: Padding(
//         padding: EdgeInsets.all(screenWidth2),
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 // Search Bar
//                 CustomTextFieldWidget(
//                   hintText: "Search ticket by ID or Issue...",
//                   keyboardType: TextInputType.text,
//                   prefixIcon: Icons.search,
//                   controller: _searchController,
//                   onChanged: _searchTickets,
//                 ),

//                 // Tickets List
//                Expanded(
//   child: filteredComplaints.isEmpty
//       ? _buildEmptyState()
//       : ListView.builder(
//           padding: EdgeInsets.symmetric(
//             horizontal: screenWidth1,
//             vertical: screenHeight1,
//           ),
//           itemCount: filteredComplaints.length,
//           itemBuilder: (context, index) {
//             return _buildComplaintCard(filteredComplaints[index]);
//           },
//         ),
// ),

//               ],
//             ),
//             Positioned(
//               bottom: screenHeight * 0.05,
//               left: 0,
//               right: 0,
//               child: Center(
//                 child: SizedBox(
//                   width: Get.width * 0.9,
//                   child: CustomButtonWidget(
//                     buttonColor: AppColors.secondaryColor,
//                     buttonTitle: "Create Ticket",
//                     buttonTextColor: AppColors.white,
//                  onPressed: () async {
//   try {
//     await controller.fetchTenantProperties();

//     if (controller.properties.isNotEmpty) {
//       _showPropertySelectionBottomSheet(controller.properties);
//     } else {
//       Get.snackbar("No Properties", "No properties found for this user.");
//     }
//   } catch (e) {
//     Get.snackbar("Error", "Failed to fetch properties: $e");
//   }
// },



//                   ),
//                 ),
//               ),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// void _showPropertySelectionBottomSheet(List<TenantPropertyModel> properties) {
//   final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

//   Get.bottomSheet(
//     Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: AppColors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CustomTextWidget(
//             title: "Select Property",
//             fontSize: Get.height * 0.02,
//             fontWeight: FontWeight.bold,
//             color: AppColors.black,
//           ),
//           const SizedBox(height: 12),
//           ListView.builder(
//             shrinkWrap: true,
//             itemCount: properties.length,
//             itemBuilder: (context, index) {
//               final property = properties[index];
//               print("Rendering: ${property.propertyTitle}, Flat No: ${property.unitNumber}");

//               return ListTile(
//   contentPadding: EdgeInsets.zero,
//   title: CustomTextWidget(
//     title: property.propertyTitle,
//     fontSize: Get.height * 0.016,
//     color: AppColors.black,
//   ),
//   subtitle: Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       CustomTextWidget(
//         title: "ID: ${property.id}",
//         fontSize: Get.height * 0.014,
//         color: AppColors.grey,
//       ),
//       CustomTextWidget(
//         title: "Flat No: ${property.unitNumber.isNotEmpty ? property.unitNumber : 'N/A'}",
//         fontSize: Get.height * 0.014,
//         color: AppColors.grey,
//       ),
//     ],
//   ),
//   onTap: () {
//     debugPrint(
//       'Selected Property: ${property.propertyTitle}, ID: ${property.id}, unitAddressId: ${property.unitAddressId}, userId: $userId, propertyName: ${property.propertyTitle}, Flat No: ${property.unitNumber}',
//     );

//     Get.back();
//     Get.to(() => TenantsCreateTicketScreen(
//           propertyName: property.propertyTitle,
//           propertyId: property.propertyId,
//           unitAddressId: property.unitAddressId,
//           userId: userId,
//         ));
//   },
// );

//             },
//           ),
//         ],
//       ),
//     ),
//   );
// }




//   /// Builds a single ticket card
//   Widget _buildComplaintCard(Complaint complaint) {
//   return InkWell(
//     onTap: () {
//       Get.to(() => TicketDetailsScreen(complaint: complaint,
    
//       ));
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
//           kHeight(0.02),
//           Container(
//             height: Get.height * 0.001,
//             width: Get.width * 0.90,
//             color: AppColors.grey.withValues(alpha: 0.6),
//           ),
//         ],
//       ),
//     ),
//   );
// }


//   /// Builds the status chip
//   Widget _buildStatusChipFromComplaint(String statusText) {
//   Color backgroundColor;
//   Color textColor;

//   switch (statusText.toLowerCase()) {
//     case "pending":
//       backgroundColor = AppColors.primaryColor.withOpacity(0.1);
//       textColor = AppColors.primaryColor;
//       break;
//     case "rectified":
//       backgroundColor = AppColors.onlineGreen.withOpacity(0.1);
//       textColor = AppColors.onlineGreenDark;
//       break;
//     case "in progress":
//       backgroundColor = Colors.blue.withOpacity(0.1);
//       textColor = Colors.blue;
//       break;
//     case "completed":
//       backgroundColor = Colors.green.withOpacity(0.1);
//       textColor = Colors.green;
//       break;
//     default:
//       backgroundColor = AppColors.grey.withOpacity(0.1);
//       textColor = AppColors.grey;
//       break;
//   }

//   return Container(
//     padding: EdgeInsets.symmetric(
//       horizontal: screenWidth * 0.010,
//       vertical: screenHeight * 0.002,
//     ),
//     decoration: BoxDecoration(
//       color: backgroundColor,
//       borderRadius: BorderRadius.circular(8),
//     ),
//     child: CustomTextWidget(
//       title: statusText,
//       fontSize: Get.height * 0.012,
//       fontWeight: FontWeight.w600,
//       color: textColor,
//     ),
//   );
// }


    



//   /// Empty state
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.confirmation_number_outlined,
//             size: Get.height * 0.08,
//             color: AppColors.lightGrey,
//           ),
//           SizedBox(height: screenHeight1),
//           CustomTextWidget(
//             title: "No tickets found",
//             fontSize: Get.height * 0.02,
//             fontWeight: FontWeight.w600,
//             color: AppColors.black500,
//           ),
//           SizedBox(height: screenHeight05),
//           CustomTextWidget(
//             title: "Try adjusting your search criteria",
//             fontSize: Get.height * 0.016,
//             fontWeight: FontWeight.w400,
//             color: AppColors.lightGrey,
//           ),
//         ],
//       ),
//     );
//   }

//   /// Show Create Ticket Dialog
//   void _showCreateTicketDialog() {
//     final TextEditingController titleController = TextEditingController();
//     final TextEditingController descriptionController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: CustomTextWidget(
//             title: "Create New Ticket",
//             fontSize: Get.height * 0.02,
//             fontWeight: FontWeight.w600,
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: titleController,
//                 decoration: InputDecoration(
//                   hintText: "Ticket Category",
//                   hintStyle: GoogleFonts.poppins(
//                     color: AppColors.lightGrey,
//                     fontSize: Get.height * 0.016,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//               SizedBox(height: screenHeight1),
//               TextField(
//                 controller: descriptionController,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   hintText: "Describe the issue",
//                   hintStyle: GoogleFonts.poppins(
//                     color: AppColors.lightGrey,
//                     fontSize: Get.height * 0.016,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: CustomTextWidget(
//                 title: "Cancel",
//                 color: AppColors.black500,
//                 fontSize: Get.height * 0.016,
//               ),
//             ),
//             TextButton(
//               onPressed: () {
//                 if (titleController.text.isNotEmpty &&
//                     descriptionController.text.isNotEmpty) {
//                   Navigator.pop(context);
//                   _createNewComplaint(
//                       titleController.text, descriptionController.text);
//                 }
//               },
//               child: CustomTextWidget(
//                 title: "Create",
//                 color: AppColors.primaryColor,
//                 fontSize: Get.height * 0.016,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   /// Add new ticket
// void _createNewComplaint(String category, String description) {
//   final now = DateTime.now().toString();
//   final newComplaint = Complaint(
//     complaintId: 'CID-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
//     complaintNumber: 'CMP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    
//     description: description,
//     replyByTechnician: null,
//     replyByAdmin: null,
//     amountPaid: null,
//     amountPaidStatus: null,
//     date: now,
//     lastUpdated: null,
//     lastUpdatedByAdmin: null,
//     addedByAdmin: false,
//     statusText: StatusText(en: 'Pending'),
//     status: 'pending',
//     category: category,
//     subcategory: '', // You can add subcategory if needed
//     propertyName: '', // Add property name if available
//     unitNumber: '', // Add unit number if available
//     unitType: '', // Add unit type if available
//     fullAddress: '', // Add full address if available
//     flatnoId: '', // Add flat ID if available
//     images: [], // Add images if available
//     assignedTechnicians: [], // Add technicians if available
//     complaintImages: ComplaintImages(
//       tenantUploaded: [],
//       adminUploaded: [],
//       technicianUploaded: [],
//       adminTechnicianUploaded: [],
//     ),
//   );

//   setState(() {
//     complaints.insert(0, newComplaint);
//     filteredComplaints = complaints;
//   });

//   ScaffoldMessenger.of(context).showSnackBar(
//     SnackBar(
//       content: CustomTextWidget(
//         title: "Complaint created successfully!",
//         color: AppColors.white,
//         fontSize: Get.height * 0.016,
//       ),
//       backgroundColor: Colors.green,
//     ),
//   );
// }
// }



import 'package:majan/data/model/technican_ticket_view_model.dart'
    show TicketModel, TicketStatus;
import 'package:majan/data/model/tenant_summary_model.dart';
import 'package:majan/data/model/tenatpropertymodel.dart';
import 'package:majan/data/model/ticket_list_response_model.dart';
import 'package:majan/presentation/view/dashboard/controller/tenant_tickets_controller.dart';
import 'package:majan/presentation/view/dashboard/widgets/technician_view_tickets.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_create_ticket_screen.dart';
import 'package:majan/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart';
import 'package:majan/presentation/widgets/custom_elevated_button.dart';
import 'package:majan/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/notification_navigation_widget.dart';
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
  TenantSummary? tenantSummary;
  bool isLoadingSummary = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load both complaints and summary data
  Future<void> _loadData() async {
    await Future.wait([
      _loadComplaints(),
      _loadTenantSummary(),
    ]);
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

  /// Fetch tenant summary statistics
/// Fetch tenant summary statistics
Future<void> _loadTenantSummary() async {
  try {
    setState(() {
      isLoadingSummary = true;
    });

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (userId.isEmpty) {
      debugPrint("User ID is empty");
      setState(() {
        isLoadingSummary = false;
      });
      return;
    }

    debugPrint("Loading tenant summary for userId: $userId");
    
    // Call the controller method
    await controller.getSummaryForTenant(userId);
    
    // Check if we have valid data
    if (controller.technicianStats.value != null) {
      final summary = controller.technicianStats.value!;
      
      // Additional validation: check if propertyStats is not empty
      if (summary.propertyStats.isNotEmpty) {
        setState(() {
          tenantSummary = summary;
          final propertyCount = summary.propertyStats.length;
          debugPrint('Tenant summary loaded successfully: $propertyCount properties');
          isLoadingSummary = false;
        });
      } else {
        // Handle case where summary exists but has no properties
        debugPrint("Tenant summary loaded but no properties found");
        setState(() {
          tenantSummary = null; // Set to null so it doesn't display
          isLoadingSummary = false;
        });
      }
    } else {
      // Handle case where no summary was returned
      String errorMessage = controller.statsErrorMessage.value.isNotEmpty 
          ? controller.statsErrorMessage.value 
          : "No summary data available";
      debugPrint("Failed to load summary: $errorMessage");
      setState(() {
        tenantSummary = null;
        isLoadingSummary = false;
      });
    }
  } catch (e, stackTrace) {
    debugPrint("Error loading tenant summary: $e");
    debugPrint("Stack trace: $stackTrace");
    setState(() {
      tenantSummary = null;
      isLoadingSummary = false;
    });
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
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Padding(
          padding: EdgeInsets.all(screenWidth2),
          child: Stack(
            children: [
              Column(
                children: [
                  // Summary Statistics Section
                  if (!isLoadingSummary && tenantSummary != null)
                    _buildSummarySection(),
                  
                  if (isLoadingSummary)
                    _buildSummaryLoadingSection(),

                  SizedBox(height: screenHeight1),

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
      ),
    );
  }

  // /// Build summary statistics section
  // Widget _buildSummarySection() {
  //   if (tenantSummary == null || tenantSummary!.propertyStats.isEmpty) {
  //     return const SizedBox.shrink();
  //   }

  //   // Calculate total statistics across all properties
  //   int totalComplaints = 0;
  //   int totalStartedWorking = 0;
  //   int totalInProgress = 0;
  //   int totalResolved = 0;

  //   for (var property in tenantSummary!.propertyStats) {
  //     totalComplaints += int.tryParse(property.totalComplaints) ?? 0;
  //     totalStartedWorking += int.tryParse(property.startedWorking) ?? 0;
  //     totalInProgress += int.tryParse(property.inProgress) ?? 0;
  //     totalResolved += int.tryParse(property.resolved) ?? 0;
  //   }

  //   return Container(
  //     margin: EdgeInsets.only(bottom: screenHeight1),
  //     padding: EdgeInsets.all(screenWidth1),
  //     decoration: BoxDecoration(
  //       color: AppColors.white,
  //       borderRadius: BorderRadius.circular(12),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.05),
  //           blurRadius: 8,
  //           offset: const Offset(0, 2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         CustomTextWidget(
  //           title: "Ticket Summary",
  //           fontSize: Get.height * 0.018,
  //           fontWeight: FontWeight.w600,
  //           color: AppColors.black,
  //         ),
  //         SizedBox(height: screenHeight1),
          
  //         // Statistics Cards Row
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildStatCard(
  //                 "Total",
  //                 totalComplaints.toString(),
  //                 AppColors.primaryColor,
  //                 Icons.confirmation_number_outlined,
  //               ),
  //             ),
  //             SizedBox(width: screenWidth1),
  //             Expanded(
  //               child: _buildStatCard(
  //                 "Started",
  //                 totalStartedWorking.toString(),
  //                 Colors.blue,
  //                 Icons.play_circle_outline,
  //               ),
  //             ),
  //           ],
  //         ),
  //         SizedBox(height: screenHeight1),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: _buildStatCard(
  //                 "In Progress",
  //                 totalInProgress.toString(),
  //                 Colors.orange,
  //                 Icons.pending_outlined,
  //               ),
  //             ),
  //             SizedBox(width: screenWidth1),
  //             Expanded(
  //               child: _buildStatCard(
  //                 "Resolved",
  //                 totalResolved.toString(),
  //                 AppColors.onlineGreen,
  //                 Icons.check_circle_outline,
  //               ),
  //             ),
  //           ],
  //         ),

  //         // Property breakdown (if multiple properties)
  //         if (tenantSummary!.propertyStats.length > 1) ...[
  //           SizedBox(height: screenHeight1),
  //           CustomTextWidget(
  //             title: "By Property:",
  //             fontSize: Get.height * 0.014,
  //             fontWeight: FontWeight.w500,
  //             color: AppColors.black500,
  //           ),
  //           SizedBox(height: screenHeight05),
  //           ...tenantSummary!.propertyStats.map((property) => 
  //             _buildPropertyStatRow(property)
  //           ).toList(),
  //         ]
  //       ],
  //     ),
  //   );
  // }

  /// Build individual stat card
  Widget _buildStatCard(String title, String count, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(screenWidth1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: Get.height * 0.024),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: count,
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w700,
            color: color,
          ),
          CustomTextWidget(
            title: title,
            fontSize: Get.height * 0.012,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ],
      ),
    );
  }

  /// Build property stat row
  Widget _buildPropertyStatRow(PropertyStats property) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight05),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: CustomTextWidget(
              title: property.propertyName,
              fontSize: Get.height * 0.012,
              fontWeight: FontWeight.w400,
              color: AppColors.black,
              maxLines: 1,
            ),
          ),
          Expanded(
            child: CustomTextWidget(
              title: "${property.totalComplaints} total",
              fontSize: Get.height * 0.012,
              fontWeight: FontWeight.w400,
              color: AppColors.black500,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading section for summary
  Widget _buildSummaryLoadingSection() {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight1),
      padding: EdgeInsets.all(screenWidth1),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          CustomTextWidget(
            title: "Loading Summary...",
            fontSize: Get.height * 0.016,
            fontWeight: FontWeight.w500,
            color: AppColors.black500,
          ),
          SizedBox(height: screenHeight1),
          const CircularProgressIndicator(),
        ],
      ),
    );
  }

  // ... rest of your existing methods remain the same ...

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
                print("Rendering: ${property.propertyTitle}, Flat No: ${property.unitNumber}");

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: CustomTextWidget(
                    title: property.propertyTitle,
                    fontSize: Get.height * 0.016,
                    color: AppColors.black,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomTextWidget(
                        title: "ID: ${property.id}",
                        fontSize: Get.height * 0.014,
                        color: AppColors.grey,
                      ),
                      CustomTextWidget(
                        title: "Flat No: ${property.unitNumber.isNotEmpty ? property.unitNumber : 'N/A'}",
                        fontSize: Get.height * 0.014,
                        color: AppColors.grey,
                      ),
                    ],
                  ),
                  onTap: () {
                    debugPrint(
                      'Selected Property: ${property.propertyTitle}, ID: ${property.id}, unitAddressId: ${property.unitAddressId}, userId: $userId, propertyName: ${property.propertyTitle}, Flat No: ${property.unitNumber}',
                    );

                    Get.back();
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


// Add this in your _TenantsTicketsListWidgetState class

/// Build summary statistics section (updated to match technician style)
Widget _buildSummarySection() {
  if (tenantSummary == null || tenantSummary!.propertyStats.isEmpty) {
    return const SizedBox.shrink();
  }

  // Calculate totals across all properties
  final totalTickets = tenantSummary!.propertyStats.fold<int>(0, (sum, stat) {
    return sum + (int.tryParse(stat.totalComplaints) ?? 0);
  });
  
  final totalActive = tenantSummary!.propertyStats.fold<int>(0, (sum, stat) {
    final started = int.tryParse(stat.startedWorking) ?? 0;
    final inProgress = int.tryParse(stat.inProgress) ?? 0;
    return sum + started + inProgress;
  });
  
  final totalResolved = tenantSummary!.propertyStats.fold<int>(0, (sum, stat) {
    return sum + (int.tryParse(stat.resolved) ?? 0);
  });

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
          title: 'Your Tickets Summary',
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
              icon: Icons.home_work_outlined,
              value: tenantSummary!.propertyStats.length.toString(),
              label: 'Properties',
              color: AppColors.primaryColor,
            ),
            _buildStatItem(
              icon: Icons.list_alt,
              value: totalTickets.toString(),
              label: 'Total Tickets',
              color: AppColors.primaryColor,
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
        
        // Property breakdown (if multiple properties)
        if (tenantSummary!.propertyStats.length > 1) ...[
          const SizedBox(height: 12),
          const CustomTextWidget(
            title: 'By Property:',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.black500,
          ),
          const SizedBox(height: 8),
          ...tenantSummary!.propertyStats.map((property) => 
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextWidget(
                      title: property.propertyName,
                      fontSize: 12,
                      color: AppColors.black,
                    ),
                  ),
                  CustomTextWidget(
                    title: '${property.totalComplaints} tickets',
                    fontSize: 12,
                    color: AppColors.black500,
                  ),
                ],
              ),
            )
          ).toList(),
        ]
      ],
    ),
  );
}

/// Build individual stat item card
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
        Get.to(() => TicketDetailsScreen(complaint: complaint));
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

    setState(() {
      complaints.insert(0, newComplaint);
      filteredComplaints = complaints;
    });

    // Reload summary after creating new complaint
    _loadTenantSummary();

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