import 'package:majan/data/model/history_ticket_model.dart';
import 'package:majan/domain/controller/technician_ticket_history_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/widgets/custom_text_formfield_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/notification_navigation_widget.dart';

class TechnicianResolvedTicketsListWidget extends StatelessWidget {
  TechnicianResolvedTicketsListWidget({super.key});

  final TechnicianTicketHistoryController controller =
      Get.put(TechnicianTicketHistoryController());

  final TextEditingController _searchController = TextEditingController();
  final RxList<TicketHistoryModel> filtered = <TicketHistoryModel>[].obs;

  void _search(String query) {
    if (query.isEmpty) {
      filtered.assignAll(controller.tickets);
    } else {
      filtered.assignAll(
        controller.tickets.where((t) =>
            t.category.toLowerCase().contains(query.toLowerCase()) ||
            t.description.toLowerCase().contains(query.toLowerCase()) ||
            t.complaintNumber.toLowerCase().contains(query.toLowerCase())),
      );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: CustomTextWidget(
          title: "Resolved Tickets",
          fontSize: Get.height * 0.022,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [notificationNavigation()],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return _buildEmptyState(controller.errorMessage.value);
        }

        final List<TicketHistoryModel> listToShow =
            _searchController.text.isEmpty ? controller.tickets : filtered;

        return Padding(
          padding: EdgeInsets.all(screenWidth2),
          child: Column(
            children: [
              CustomTextFieldWidget(
                hintText: "Search resolved ticket...",
                keyboardType: TextInputType.text,
                prefixIcon: Icons.search,
                controller: _searchController,
                onChanged: _search,
              ),
              Expanded(
                child: listToShow.isEmpty
                    ? _buildEmptyState("No resolved tickets found.")
                    : ListView.builder(
                        itemCount: listToShow.length,
                        itemBuilder: (context, index) {
                          return _buildTicketCard(listToShow[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

 Widget _buildTicketCard(TicketHistoryModel ticket) {
  return GestureDetector(
    // onTap: () {
    //   Get.to(() => TicketDetailsScreen(complaint: complaint)); // Navigate with data
    // },
    child: Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight05),
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
            title: "#${ticket.complaintNumber}",
            fontSize: Get.height * 0.014,
            fontWeight: FontWeight.w600,
            color: AppColors.black800,
          ),
          SizedBox(height: screenHeight05),
          CustomTextWidget(
            title: ticket.category,
            fontSize: Get.height * 0.018,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            maxLines: 2,
          ),
          CustomTextWidget(
            title: ticket.description,
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
                title: "Last updated on ${ticket.tenantDate}",
                fontSize: Get.height * 0.014,
                fontWeight: FontWeight.w400,
                color: AppColors.black500,
              ),
              _buildStatusChip(ticket.status),
            ],
          ),
        ],
      ),
    ),
  );
}


  Widget _buildStatusChip(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case "rectified":
        bgColor = AppColors.onlineGreen.withOpacity(0.1);
        textColor = AppColors.onlineGreenDark;
        break;
      case "completed":
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        break;
      default:
        bgColor = AppColors.grey.withOpacity(0.1);
        textColor = AppColors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.010,
        vertical: screenHeight * 0.002,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomTextWidget(
        title: status,
        fontSize: Get.height * 0.012,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: Get.height * 0.08, color: AppColors.lightGrey),
          SizedBox(height: screenHeight1),
          CustomTextWidget(
            title: message,   
            fontSize: Get.height * 0.02,
            fontWeight: FontWeight.w600,
            color: AppColors.black500,
          ),
        ],
      ),
    );
  }
}
