import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/dashboard/widgets/tenant_property_card_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
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
                border: Border.all(color: AppColors.black, width: 2),
              ),
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
                if (tenantPropertyController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tenantPropertyController.errorMessage.isNotEmpty) {
                  return Center(
                    child: CustomTextWidget(
                      title: tenantPropertyController.errorMessage.value,
                      fontSize: Get.height * 0.02,
                      color: Colors.red,
                    ),
                  );
                }

                if (tenantPropertyController.properties.isEmpty) {
                  return Center(
                    child: CustomTextWidget(
                      title: 'No Properties Found',
                      fontSize: Get.height * 0.02,
                      color: AppColors.black600,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: tenantPropertyController.properties.length,
                  itemBuilder: (context, index) {
                    final property =
                        tenantPropertyController.properties[index];

                    return Padding(
                      padding: EdgeInsets.only(bottom: Get.height * 0.02),
                      child: TenantPropertyCard(
                        imageUrl: property.propertyImageUrl,
                        title: property.propertyTitle,
                        price: property.rentAmount,
                        location: '${property.cityName}, ${property.stateName}',
                        expiryDate: property.expiryStatus,
                        sqft: property.unitAreaFormatted,
                        bedrooms: property.unitTypeName,
                        unit_address_id: property.unitAddressId,
                        unit_type:property.unitTypeName,
                        isExpiringSoon: property.expiryStatus
                            .toLowerCase()
                            .contains('expires'),
                      onTap: () {
  Get.to(() => CustomTenantPropertyDetailWidget(
        propertyId: property.id, cityName: '', // int
  ));
},



                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
