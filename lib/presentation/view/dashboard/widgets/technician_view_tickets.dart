import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/data/model/technician_complaints_response.dart';
import 'package:dar_al_safwa/data/model/ticket_list_response_model.dart';
import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_ticket_card_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TechnicianViewTickets extends StatefulWidget {
  const TechnicianViewTickets({super.key});

  @override
  State<TechnicianViewTickets> createState() => _TechnicianViewTicketsState();
}

class _TechnicianViewTicketsState extends State<TechnicianViewTickets> {
  final controller = Get.put(TechnicianTicketsController());

  @override
  void initState() {
    super.initState();
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      controller.fetchTickets(userId);
      controller.getAvailableTechnicians();
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.tickets.isEmpty) {
          return const Center(child: Text('No Tickets Found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.tickets.length,
          itemBuilder: (context, index) {
            final complaint = controller.tickets[index];
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
                // statusBackgroundColor: statusColors.backgroundColor,
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