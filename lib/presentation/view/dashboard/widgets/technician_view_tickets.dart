import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';
import 'technician_ticket_card_widget.dart';

class TechnicianViewTickets extends StatelessWidget {
  TechnicianViewTickets({super.key});

  final controller = Get.put(TechnicianTicketsController());

  @override
  Widget build(BuildContext context) {
    // Fetch tickets on load
    controller.fetchTickets("wM26u5uv7MNiisePl803uYTYDNL2"); // Replace with dynamic user ID

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
            final ticket = controller.tickets[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: buildTicketCard(
                propertyName: ticket.propertyName,
                category: ticket.category,
                issue: ticket.subcategory,
                status: ticket.statusText,
                statusColor: _getStatusColor(ticket.statusText),
                description: ticket.description,
                date: ticket.date.split(' ').first,
                time: ticket.date.split(' ').last,
                categoryIcon: Icons.build, // Can map dynamically
                images: ticket.images,
                ticket: ticket,
              ),
            );
          },
        );
      }),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return AppColors.warning;
      case "completed":
        return Colors.green;
      case "execution":
        return AppColors.error;
      default:
        return AppColors.black;
    }
  }
}
