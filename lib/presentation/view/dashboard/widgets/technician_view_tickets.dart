import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_ticket_card_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

class TechnicianViewTickets extends StatefulWidget {
  const TechnicianViewTickets({super.key});

  @override
  _TechnicianViewTicketsState createState() => _TechnicianViewTicketsState();
}

class _TechnicianViewTicketsState extends State<TechnicianViewTickets> {
  final controller = Get.put(TechnicianTicketsController());

  @override
  void initState() {
    super.initState();
    controller.fetchTickets("2kiHls8ajrhe8e96aW59fkTh7i13"); // Fetch once
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
            final ticket = controller.tickets[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: buildTicketCard(
                propertyName: ticket.propertyName,
                category: ticket.category,
                issue: ticket.subcategory,
                status: ticket.statusText.en,
                statusColor: _getStatusColor(ticket.statusText.en),
                description: ticket.description,
                date: ticket.date.split(' ').first,
                time: ticket.date.split(' ').last,
                categoryIcon: Icons.build,
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
