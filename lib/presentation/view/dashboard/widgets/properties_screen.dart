import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/agent_registered_property_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/notification_navigation_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'property_card.dart';

class PropertiesScreen extends StatelessWidget {
  const PropertiesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AgentRegisteredPropertyController agentPropertyController =
        Get.put(AgentRegisteredPropertyController());
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth4,
                vertical: screenHeight2,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Icon(
                      Icons.arrow_back,
                      color: AppColors.black,
                      size: iconSize,
                    ),
                  ),
                  kWidth(0.03),
                  Expanded(
                      child: CustomTextWidget(
                    title: 'Property List',
                    fontSize: appBarTitles,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  )),
                  notificationNavigation(),
                  // addPropertyButton(),
                ],
              ),
            ),

            kHeight(0.01),

            // Search Bar
            Container(
              height: Get.height * 0.05,
              margin: EdgeInsets.symmetric(horizontal: screenWidth4),
              decoration: BoxDecoration(
                color: AppColors.whiteLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.lightGrey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(screenWidth4)),
                  disabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: AppColors.lightGrey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(screenWidth4)),
                  fillColor: AppColors.darkGrey,
                  hintText: 'Search property by name, location...',
                  hintStyle: TextStyle(
                    color: AppColors.darkGrey,
                    fontSize: tagTitle,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.darkGrey,
                    size: iconSize * 0.8,
                  ),
                  suffixIcon: Icon(
                    Icons.tune,
                    color: AppColors.darkGrey,
                    size: iconSize * 0.8,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: screenWidth4,
                    vertical: screenHeight2,
                  ),
                ),
              ),
            ),

            kHeight(0.03),

            // Property Cards

            Expanded(
              child: Obx(() {
                if (agentPropertyController.agentProperties.isEmpty) {
                  return Center(
                    child: CustomTextWidget(
                      title: 'No Properties Registered',
                      fontSize: Get.height * 0.02,
                      color: AppColors.black600,
                    ),
                  );
                }

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth4,
                  ),
                  child: ListView.builder(
                    itemCount: agentPropertyController.agentProperties.length,
                    itemBuilder: (context, index) {
                      final property =
                          agentPropertyController.filteredProperties[index];
                      final statusText = agentPropertyController
                          .getFormattedStatus(property.status);
                      final color =
                          agentPropertyController.getStatusColor(statusText);
                      return buildPropertyCard(
                        onTap: () {
                          Get.toNamed(
                            '/propertyDetails',
                            arguments: {
                              "propertyId":
                                  int.tryParse(property.propertyId!) ?? 0,
                            },
                          );
                        },

                        imageUrl: property.image ??
                            "https://via.placeholder.com/300x200.png?text=No+Image+Available", // You'll need to add imageUrl to your model if needed
                        title: property.title ?? "No Title",
                        location: agentPropertyController
                            .getLocalizedAddress(property.address),
                        status: statusText,
                        statusColor: color,
                        // statusBackgroundColor: color.withOpacity(0.1),
                        listedDate: property.assignedDate ?? 'N/A',
                        price: agentPropertyController
                            .getFormattedPrice(property.price),
                      );
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget addPropertyButton() {
    return InkWell(
      onTap: () {
        Get.toNamed('/addProperties');
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth3,
          vertical: screenHeight1,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: Get.height * 0.020,
              child: Image.asset("assets/images/add_property.png"),
            ),
            kWidth(0.01),
            Text(
              'Add Property',
              style: TextStyle(
                fontSize: tagTitle,
                color: AppColors.secondaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
