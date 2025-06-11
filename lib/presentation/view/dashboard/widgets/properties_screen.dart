import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/controller/agent_registered_property_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
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
      backgroundColor: AppColors.whiteLight,
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
                  addPropertyButton(),
                ],
              ),
            ),

            kHeight(0.01),

            // Search Bar
            Container(
              height: Get.height * 0.05,
              margin: EdgeInsets.symmetric(horizontal: screenWidth4),
              decoration: BoxDecoration(
                color: AppColors.lightGrey2,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lightGrey.withOpacity(0.3),
                    blurRadius: 2,
                    // offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
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
                          agentPropertyController.agentProperties[index];
                      final color = agentPropertyController
                          .getStatusColor(property['status']);
                      return buildPropertyCard(
                          imageUrl: property['imageUrl'],
                          title: property['propertyName'],
                          location: property['location'],
                          status: property['status'],
                          statusColor:
                              color, // Status Color Section Must be defined
                          listedDate: property["listedDate"],
                          price: property['price']);
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
