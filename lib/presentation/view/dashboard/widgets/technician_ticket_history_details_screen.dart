// import 'package:flutter/material.dart';
// import 'package:majan/data/model/history_ticket_model.dart';
// import 'package:majan/core/theme/app_colors.dart';
// import 'package:majan/core/constants/custom_size.dart';
// import 'package:majan/presentation/widgets/custom_text_widget.dart';

// class TechnicianTicketDetailsScreen extends StatelessWidget {
//   final TicketHistoryModel ticket;

//   const TechnicianTicketDetailsScreen({super.key, required this.ticket});

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
//           title: "Ticket Details",
//           fontSize: Get.height * 0.022,
//           fontWeight: FontWeight.w600,
//           color: AppColors.black,
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(screenWidth2),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDetailRow("Complaint Number", ticket.complaintNumber),
//             _buildDetailRow("Category", ticket.category),
//             _buildDetailRow("Description", ticket.description),
//             _buildDetailRow("Status", ticket.status),
//             _buildDetailRow("Created Date", ticket.tenantDate),
//             _buildDetailRow("Resolution Date", ticket.resolvedDate ?? "N/A"),
//             _buildDetailRow("Technician Notes", ticket.technicianNotes ?? "N/A"),
//             _buildDetailRow("Priority", ticket.priority ?? "N/A"),
//             if (ticket.imageUrl != null) ...[
//               SizedBox(height: screenHeight1),
//               CustomTextWidget(
//                 title: "Attached Image:",
//                 fontSize: Get.height * 0.016,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.black,
//               ),
//               SizedBox(height: screenHeight05),
//               Image.network(ticket.imageUrl!),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenHeight05),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CustomTextWidget(
//             title: label,
//             fontSize: Get.height * 0.014,
//             fontWeight: FontWeight.w600,
//             color: AppColors.black500,
//           ),
//           SizedBox(height: screenHeight02),
//           CustomTextWidget(
//             title: value,
//             fontSize: Get.height * 0.016,
//             fontWeight: FontWeight.w400,
//             color: AppColors.black,
//           ),
//           Divider(color: AppColors.grey.withOpacity(0.2), height: screenHeight1),
//         ],
//       ),
//     );
//   }
// }