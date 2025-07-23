import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart';
import 'package:dar_al_safwa/domain/controller/technician_tickets_controller.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/technician_ticket_card_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
   final String? userId = FirebaseAuth.instance.currentUser?.uid;
if (userId != null) {
  controller.fetchTickets(userId); // Fetch once
}
 // Fetch once
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
            debugPrint('Ticket: ${ticket.complaintId}');
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: buildTicketCard(
                
                complaintId: ticket.complaintId ?? '',
                propertyName: ticket.propertyName ?? '',
              category: ticket.category  ?? '',
                issue: ticket.subcategory  ?? '',
                status: ticket.statusText?.en  ?? '',
                statusColor: _getStatusColor(ticket.statusText?.en  ?? ''),
                description: ticket.description  ?? '',
     date: DateTime.now().toString(),

                categoryIcon: Icons.build,
                images: ticket.images ?? [],
                ticket: TicketModel(complaintId: ticket.complaintId ?? "", complaintNumber: ticket.complaintNumber ?? "", category: ticket.category ?? "", subcategory: ticket.subcategory ?? "", description: ticket.description ?? "", reply:  ticket.reply ?? "", amountPaid:  "N/A" ?? "0", amountPaidStatus: "", status: TicketStatus.pending, lastUpdated: "", images: ticket.images ?? []), mobile: '', name: '', time: ''  // property: ,
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
