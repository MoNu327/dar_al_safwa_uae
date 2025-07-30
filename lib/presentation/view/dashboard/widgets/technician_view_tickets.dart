import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/data/model/technician_complaints_response.dart';
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
            // ✅ Your list holds Complaint items
            final Complaint complaint = controller.tickets[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: buildTicketCard(
                // Use only fields available on Complaint
                complaintId: complaint.complaintId ?? '',
                propertyName: '', // Not available on Complaint (see Option B)
                category: complaint.category ?? '',
                issue: complaint.subcategory ?? '',
                status: complaint.displayStatus,        // from your getter
                statusColor: complaint.statusColor,     // from your getter
                description: complaint.description ?? '',
                date: complaint.formattedDate,          // from your getter
                categoryIcon: Icons.build,

                // Not on Complaint (these live in ComplaintResponseData) — pass safe fallbacks
                images: const <String>[],
                mobile: '',
                name: 'Technician',
                time: complaint.createdAt ?? '', 

                // ⚠️ Avoid passing `ticket:` if your card expects TicketModel.
                // Remove or adapt card’s parameter to accept Complaint if needed.
              ),
            );
          },
        );
      }),
    );
  }
}
