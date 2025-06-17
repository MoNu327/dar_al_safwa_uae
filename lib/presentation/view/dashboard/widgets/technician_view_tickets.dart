import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import 'technician_ticket_card_widget.dart';

class TechnicianViewTickets extends StatelessWidget {
  const TechnicianViewTickets({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.black,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: const CustomTextWidget(
          title: 'View Tickets',
          fontSize: 18,
          color: AppColors.black,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              HugeIcons.strokeRoundedNotification01,
              color: AppColors.black,
              size: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(Get.width * 0.04),
        child: ListView(
          children: [
            buildTicketCard(
              propertyName: 'Skyline Residency Tower B',
              category: 'Plumbing',
              issue: 'Pipe Leakage',
              status: 'Execution',
              statusColor: AppColors.error,
              description:
                  "There's a leakage in the kitchen sink area. Needs Urgent repair.",
              date: 'May 22, 2025',
              time: '10:30 AM',
              categoryIcon: HugeIcons.strokeRoundedPipeline,
              images: [
                'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=200&h=200&fit=crop',
                'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=200&h=200&fit=crop',
              ],
            ),
            SizedBox(height: Get.height * 0.02),
            buildTicketCard(
              propertyName: 'Hillcrest Apartment',
              category: 'Electrical',
              issue: 'Power Outage',
              status: 'In Progress',
              statusColor: AppColors.warning,
              description: 'The lights in the lobby are not working.',
              date: 'May 21, 2025',
              time: '02:15 PM',
              categoryIcon: HugeIcons.strokeRoundedElectricHome01,
              images: [
                'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=200&h=200&fit=crop',
                'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=200&h=200&fit=crop',
              ],
            ),
          ],
        ),
      ),
    );
  }
}
