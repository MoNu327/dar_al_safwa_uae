  import 'package:majan/core/constants/custom_size.dart';
  import 'package:majan/core/theme/app_colors.dart';
  import 'package:majan/core/routes/app_route.dart';
  import 'package:majan/data/model/search_dropdown_model.dart';
  import 'package:majan/presentation/view/search/controllers/search_screen_controller.dart';
  import 'package:majan/presentation/widgets/custom_elevated_button.dart';
  import 'package:majan/presentation/widgets/custom_text_widget.dart';
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

      // Validate that we have data before building the card
      if (propertyOptions.isEmpty || 
          propertyTypes.isEmpty || 
          propertyLocations.isEmpty || 
          propertyBedsBaths.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(screenWidth6)),
            color: Colors.white,
            border: Border.all(
              color: AppColors.black800.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 40, color: Colors.grey),
              SizedBox(height: 10),
              CustomTextWidget(
                title: 'Search options not available',
                textAlign: TextAlign.center,
                color: Colors.grey,
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(screenWidth6)),
          color: Colors.white,
          border: Border.all(
            color: AppColors.black800.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          spacing: Get.height * 0.01,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Property Options (Tabs)
            Obx(() {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Get.width * 0.02,
                    vertical: Get.height * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whiteLight,
                    borderRadius: BorderRadius.circular(screenWidth4),
                  ),
                  child: Row(
                    children: propertyOptions.map((option) {
                      final isSelected =
                          searchController.selectedPropertyOption.value?.id ==
                              option.id;
                      return Padding(
                        padding: EdgeInsets.only(right: screenWidth * 0.015),
                        child: GestureDetector(
                          onTap: () {
                            debugPrint('Selecting property option: ${option.name.en} (ID: ${option.id})');
                            searchController.selectPropertyOption(option);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: Get.width * 0.030,
                              vertical: Get.height * 0.005,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 2,
                                color: isSelected
                                    ? AppColors.white
                                    : Colors.transparent,
                              ),
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(screenWidth3),
                            ),
                            child: CustomTextWidget(
                              title: isArabic ? option.name.ar : option.name.en,
                              color: isSelected
                                  ? AppColors.black
                                  : AppColors.darkGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            }),

            // Property Type Dropdown
            Obx(() => _buildPropertyDropdown(
                  icon: Icons.home_outlined,
                  title: localizationController.translate("property"),
                  value: searchController.selectedPropertyType.value,
                  items: propertyTypes,
                  onChanged: (value) {
                    debugPrint('Selecting property type: ${value?.name.en} (ID: ${value?.id})');
                    searchController.selectPropertyType(value);
                  },
                  isArabic: isArabic,
                )),

            // Location Dropdown
            Obx(() => _buildPropertyDropdown(
                  icon: Icons.location_on_outlined,
                  title: localizationController.translate("location"),
                  value: searchController.selectedPropertyLocation.value,
                  items: propertyLocations,
                  onChanged: (value) {
                    debugPrint('Selecting property location: ${value?.name.en} (ID: ${value?.id})');
                    searchController.selectPropertyLocation(value);
                  },
                  isArabic: isArabic,
                )),

            // Beds & Baths Dropdown
            Obx(() => _buildPropertyDropdown(
                  icon: Icons.bathtub_outlined,
                  title: localizationController.translate("beds_baths"),
                  value: searchController.selectedBedsBath.value,
                  items: propertyBedsBaths,
                  onChanged: (value) {
                    debugPrint('Selecting beds & baths: ${value?.name.en} (ID: ${value?.id})');
                    searchController.selectBedsBath(value);
                  },
                  isArabic: isArabic,
                )),

            kHeight(0.01),

            SizedBox(
              width: double.infinity,
              height: Get.height * 0.06,
              child: Obx(() => CustomButtonWidget(
                buttonShape: "rect",
                buttonTitle: localizationController.translate("search_property"),
                buttonColor: searchController.isFormComplete 
                  ? AppColors.primaryColor 
                  : Colors.grey.shade300,
                buttonTextColor: searchController.isFormComplete
                  ? AppColors.black
                  : Colors.grey.shade600,
                // In your search button onPressed handler:
onPressed: searchController.isFormComplete ? () {
  // Get the selected property type
  final selectedType = searchController.selectedPropertyType.value;
  
  // Determine if this is a commercial search based on the type name
  bool isCommercial = false;
  if (selectedType != null) {
    final typeNameEn = selectedType.name.en?.toLowerCase() ?? '';
    final typeNameAr = selectedType.name.ar?.toLowerCase() ?? '';
    
    final commercialKeywords = [
      'commercial', 'office', 'shop', 'retail', 'warehouse', 'industrial',
      'تجاري', 'مكتب', 'متجر', 'مستودع', 'صناعي'
    ];
    
    isCommercial = commercialKeywords.any((keyword) => 
      typeNameEn.contains(keyword) || 
      typeNameAr.contains(keyword)
    );
  }

  final params = <String, dynamic>{
    'property_option': searchController.selectedPropertyOption.value?.id ?? 0,
    'property_type': searchController.selectedPropertyType.value?.id ?? 0,
    'property_locations': searchController.selectedPropertyLocation.value?.id ?? 0,
    'beds_bath': searchController.selectedBedsBath.value?.id ?? 0,
    // Add explicit commercial filter
    'is_commercial': isCommercial,
    
    // Additional UI data
    'property_option_name': isArabic
        ? searchController.selectedPropertyOption.value?.name.ar
        : searchController.selectedPropertyOption.value?.name.en,
    'property_type_name': isArabic
        ? searchController.selectedPropertyType.value?.name.ar
        : searchController.selectedPropertyType.value?.name.en,
    'property_location_name': isArabic
        ? searchController.selectedPropertyLocation.value?.name.ar
        : searchController.selectedPropertyLocation.value?.name.en,
    'property_beds_bath_name': isArabic
        ? searchController.selectedBedsBath.value?.name.ar
        : searchController.selectedBedsBath.value?.name.en,
  };
  
  debugPrint('🔍 Search parameters: $params');
  Get.toNamed(AppRoute.propertyListing, arguments: params);
} : null,
              )),
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
              Icon(icon, color: AppColors.black),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButton<T>(
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black87),
                  value: items.contains(value) ? value : null, // Ensure value exists in items
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