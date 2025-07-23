import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/model/technican_ticket_view_model.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_ticket_details_screen.dart' show TicketDetailsScreen;
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenants_tickets_list_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/constants/custom_size.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_text_widget.dart';
import 'technician_rectify_ticket_screen.dart';

Widget buildTicketCard({
  required String propertyName,
  required String category,
  required String issue,
  required String status,
  required Color statusColor,
  required String description,
  required String date,
  required String time,
  required IconData categoryIcon,
  required List<String> images,
  required TicketModel ticket,
  required String complaintId,
  required String mobile,
  required String name,
   // Add this line to accept the ticket object
}) {
  return InkWell(
    onTap: () {},
    child: Container(
      padding: EdgeInsets.all(Get.width * 0.04),
      decoration: BoxDecoration(
        color: AppColors.whiteLight,
        borderRadius: BorderRadius.circular(screenWidth4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Property Name and Category/Issue
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    title: propertyName,
                    fontSize: screenHeight * 0.018,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  SizedBox(height: Get.height * 0.005),
                  CustomTextWidget(
                    title: '$category • $issue',
                    fontSize: screenHeight * 0.014,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                  SizedBox(height: Get.height * 0.010),
                  // Status Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: Get.width * 0.025,
                      vertical: Get.height * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: CustomTextWidget(
                      title: status,
                      fontSize: screenHeight * 0.012,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(width: Get.width * 0.02),
            Row(
  children: [
    if (images.isNotEmpty)
      Container(
        margin: EdgeInsets.only(right: Get.width * 0.01),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: images.first, // Display only the first image
            width: Get.width * 0.14,
            height: Get.width * 0.14,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppColors.black.withOpacity(0.1),
            ),
            errorWidget: (context, url, error) => Container(
              color: AppColors.black.withOpacity(0.1),
              child: Icon(
                Icons.image,
                color: AppColors.black.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ),
  ],
),

            ],
          ),

          SizedBox(height: Get.height * 0.010),

          // Description
          CustomTextWidget(
            maxLines: 2,
            title: description ?? "No Desciption Available",
            fontSize: screenHeight * 0.014,
            color: AppColors.black.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
          SizedBox(height: Get.height * 0.015),

          // Date and Time
          Row(
            children: [
              Icon(
                HugeIcons.strokeRoundedCalendar01,
                size: 16,
                color: AppColors.black.withOpacity(0.5),
              ),
              SizedBox(width: Get.width * 0.015),
              CustomTextWidget(
                title: '$date • $time',
                fontSize: 12,
                color: AppColors.black.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
          SizedBox(height: Get.height * 0.02),

          // Bottom Row with Images and Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: CustomButtonWidget(
                  buttonHeight: screenHeight * 0.040,
                  buttonTitle: 'View Details',
                  onPressed: () {
                Get.to( TicketDetailsScreen(ticket: ticket,));

                  },
                  buttonShape: 'rect',
                  borderColor: AppColors.darkGrey.withOpacity(0.2),
                  buttonColor: AppColors.white,
                  fontSize: screenHeight * 0.014,
                  buttonTextColor: AppColors.black,
                ),
              ),
              SizedBox(width: Get.width * 0.02),
              Expanded(
  child: CustomButtonWidget(
    buttonHeight: screenHeight * 0.040,
    buttonTitle: 'Reply',
    onPressed: () {
  Get.to(
    () => RectifyTicketsScreen(
      complaintId: complaintId, // Pass the complaintId
    ),
  );
},

    buttonShape: 'rect',
    borderColor: AppColors.darkGrey.withValues(alpha: 0.2),
    buttonColor: AppColors.white,
    fontSize: tagTitle,
    buttonTextColor: AppColors.black,
  ),
),

            ],
          ),
        ],
      ),
    ),
  );
}
