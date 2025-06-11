import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/core/routes/app_route.dart';
import 'package:dar_al_safwa/data/model/search_dropdown_model.dart';
import 'package:dar_al_safwa/presentation/view/search/controllers/search_screen_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_elevated_button.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../view_model/localization_controller.dart';

class PropertySearchCard extends StatelessWidget {
  final List<PropertyOption> propertyOptions;
  final List<PropertyType> propertyTypes;
  final List<PropertyLocation> propertyLocations;
  final List<PropertyBedsBath> propertyBedsBaths;

  const PropertySearchCard({
    super.key,
    required this.propertyOptions,
    required this.propertyTypes,
    required this.propertyLocations,
    required this.propertyBedsBaths,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = Get.find<SearchScreenController>();
    final localizationController = Get.find<LocalizationController>();
    final bool isArabic = Get.locale?.languageCode == 'ar';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).toInt()),
            blurRadius: 15,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        spacing: Get.height * 0.01,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Property Options (Tabs)
          Obx(() {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: propertyOptions.map((option) {
                  final isSelected =
                      searchController.selectedPropertyOption.value?.id ==
                          option.id;
                  return Padding(
                    padding: EdgeInsets.only(right: screenWidth * 0.015),
                    child: GestureDetector(
                      onTap: () =>
                          searchController.selectPropertyOption(option),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: Get.width * 0.015,
                          vertical: Get.height * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.amber.shade200
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CustomTextWidget(
                          title: isArabic ? option.name.ar : option.name.en,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // Property Type Dropdown
          Obx(() => _buildPropertyDropdown(
                icon: Icons.home,
                title: localizationController.translate("property"),
                value: searchController.selectedPropertyType.value,
                items: propertyTypes,
                onChanged: searchController.selectPropertyType,
                isArabic: isArabic,
              )),

          // Location Dropdown
          Obx(() => _buildPropertyDropdown(
                icon: Icons.location_on,
                title: localizationController.translate("location"),
                value: searchController.selectedPropertyLocation.value,
                items: propertyLocations,
                onChanged: searchController.selectPropertyLocation,
                isArabic: isArabic,
              )),

          // Beds & Baths Dropdown
          Obx(() => _buildPropertyDropdown(
                icon: Icons.bathtub,
                title: localizationController.translate("beds_baths"),
                value: searchController.selectedBedsBath.value,
                items: propertyBedsBaths,
                onChanged: searchController.selectBedsBath,
                isArabic: isArabic,
              )),

          SizedBox(
            width: double.infinity,
            height: Get.height * 0.06,
            child: CustomButtonWidget(
              buttonShape: "rect",
              buttonTitle: localizationController.translate("search_property"),
              buttonColor: AppColors.black,
              onPressed: () {
                if (searchController.isFormComplete) {
                  final params = {
                    'property_option':
                        searchController.selectedPropertyOption.value?.id,
                    'property_type':
                        searchController.selectedPropertyType.value?.id,
                    'property_location':
                        searchController.selectedPropertyLocation.value?.id,
                    'property_beds_bath':
                        searchController.selectedBedsBath.value?.id,

                    // Add the names
                    'property_option_name': isArabic
                        ? searchController.selectedPropertyOption.value?.name.ar
                        : searchController
                            .selectedPropertyOption.value?.name.en,
                    'property_type_name': isArabic
                        ? searchController.selectedPropertyType.value?.name.ar
                        : searchController.selectedPropertyType.value?.name.en,
                    'property_location_name': isArabic
                        ? searchController
                            .selectedPropertyLocation.value?.name.ar
                        : searchController
                            .selectedPropertyLocation.value?.name.en,
                    'property_beds_bath_name': isArabic
                        ? searchController.selectedBedsBath.value?.name.ar
                        : searchController.selectedBedsBath.value?.name.en,
                  };
                  debugPrint('Search parameters: $params');
                  Get.toNamed(AppRoute.propertyListing, arguments: params);
                } else {
                  Get.snackbar(
                    localizationController.translate("snackbar_title"),
                    localizationController.translate("snackbar_message"),
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                    icon: const Icon(Icons.warning, color: Colors.white),
                    duration: const Duration(seconds: 3),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyDropdown<T>({
    required IconData icon,
    required String title,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required bool isArabic,
  }) {
    return DropdownButtonHideUnderline(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButton<T>(
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                value: value,
                hint: Text(title),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      _getLocalizedName(item, isArabic),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
                underline: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLocalizedName(dynamic item, bool isArabic) {
    if (item is PropertyType) return isArabic ? item.name.ar : item.name.en;
    if (item is PropertyLocation) return isArabic ? item.name.ar : item.name.en;
    if (item is PropertyBedsBath) return isArabic ? item.name.ar : item.name.en;
    return '';
  }
}
