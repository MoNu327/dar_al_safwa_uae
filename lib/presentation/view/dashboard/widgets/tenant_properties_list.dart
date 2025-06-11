import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenant_property_card_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/tenant_property_controller.dart';
import 'custom_tenant_property_detail_widget.dart';

class TenantPropertiesList extends StatelessWidget {
  const TenantPropertiesList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TenantPropertyController tenantPropertyController =
        Get.put(TenantPropertyController());
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back,
            size: iconSize,
            color: AppColors.black,
          ),
        ),
        title: CustomTextWidget(
          title: 'My Properties',
          fontSize: appBarTitles,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.search,
              size: iconSize,
              color: AppColors.black,
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: EdgeInsets.all(screenWidth1),
              decoration: BoxDecoration(
                  color: AppColors.lightGrey2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.black, width: 2)),
              child: Icon(
                Icons.more_horiz,
                size: smallIconSize,
                color: AppColors.black,
              ),
            ),
          ),
          kWidth(0.01)
        ],
      ),
      body: Padding(
        // This should be aded inside the properties section of tenants
        padding: EdgeInsets.symmetric(
          horizontal: Get.width * 0.04,
          vertical: Get.height * 0.01,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Divider(
              thickness: 1,
              color: AppColors.lightGrey,
              indent: 2,
              endIndent: 2,
            ),
            kHeight(0.02),
            Expanded(
              child: Obx(() {
                if (tenantPropertyController.tenantProperties.isEmpty) {
                  return Center(
                    child: CustomTextWidget(
                      title: 'No Properties',
                      fontSize: Get.height * 0.02,
                      color: AppColors.black600,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tenantPropertyController.tenantProperties.length,
                  itemBuilder: (context, index) {
                    final property =
                        tenantPropertyController.tenantProperties[index];
                    return TenantPropertyCard(
                      imageUrl: property['imageUrl'], // Replace with your image
                      title: property['propertyName'],
                      price: '₹99 OMR/month',
                      location: property['location'],
                      expiryDate: 'Expiry on May 26, 2026',
                      sqft: '2000 sq.ft',
                      bedrooms: '2 Bedrooms',
                      isExpiringSoon: false,
                      onTap: () {
                        Get.to(
                          () => CustomTenantPropertyDetailWidget(
                            propertyId: property['id'],
                          ),
                        );
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
      // ListView(
      //   padding: EdgeInsets.all(screenWidth4),
      //   children: [
      //     kHeight(0.02),
      //     TenantPropertyCard(
      //       imageUrl: 'assets/property2.jpg', // Replace with your image
      //       title: 'Premium 2BHK Apartment',
      //       price: '₹99 OMR/month',
      //       location: 'Kochi',
      //       expiryDate: 'Expiry on May 26, 2026',
      //       sqft: '2000 sq.ft',
      //       bedrooms: '2 Bedrooms',
      //       isExpiringSoon: false,
      //     ),
      //     kHeight(0.02),
      //     TenantPropertyCard(
      //       imageUrl: 'assets/property3.jpg', // Replace with your image
      //       title: 'Premium 2BHK Apartment',
      //       price: '₹99 OMR/month',
      //       location: 'Kochi',
      //       expiryDate: 'Expiry on May 26, 2026',
      //       sqft: '2000 sq.ft',
      //       bedrooms: '2 Bedrooms',
      //       isExpiringSoon: true,
      //     ),
      //   ],
      // ),
    );
  }
}

// Property Data Model
class PropertyData {
  final String imageUrl;
  final String title;
  final String price;
  final String location;
  final String expiryDate;
  final String sqft;
  final String bedrooms;
  final bool isExpiringSoon;

  PropertyData({
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.location,
    required this.expiryDate,
    required this.sqft,
    required this.bedrooms,
    this.isExpiringSoon = false,
  });
}
