import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/data/model/location_dropdown_model.dart';
import 'package:majan/presentation/view/home/controllers/home_screen_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomLocationDropdown extends StatelessWidget {
  CustomLocationDropdown({super.key});

  final HomeScreenController homeScreenController =
      Get.find<HomeScreenController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Handle loading state
      if (homeScreenController.isLoadingLocations.value) {
        return const CupertinoActivityIndicator(radius: 8);
      }

      // Handle error state
      if (homeScreenController.locationErrorMessage.isNotEmpty) {
        return Tooltip(
          message: homeScreenController.locationErrorMessage.value,
          child: Icon(
            Icons.error_outline,
            size: screenHeight * 0.02,
            color: Colors.red,
          ),
        );
      }

      // Handle empty state
      if (homeScreenController.locations.isEmpty) {
        return Icon(
          Icons.location_off_outlined,
          size: screenHeight * 0.02,
          color: AppColors.lightGrey,
        );
      }

      // Normal state with locations
      return DropdownButtonHideUnderline(
        child: DropdownButton<LocationDropdownModel>(
          value: homeScreenController.locations.firstWhereOrNull(
            (loc) => loc.id == homeScreenController.selectedLocation.value?.id,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: screenHeight * 0.03,
            color: AppColors.black,
          ),
          elevation: 0,
          style: GoogleFonts.lato(
            fontSize: screenHeight * 0.016,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          onChanged: homeScreenController.changeLocation,
          isDense: true,
          items: homeScreenController.locations
              .map((LocationDropdownModel location) {
            return DropdownMenuItem<LocationDropdownModel>(
              value: location,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: screenHeight * 0.015,
                    color: AppColors.black,
                  ),
                  kWidth(0.005),
                  Text(location.getName(Get.locale?.languageCode ?? 'en')),
                ],
              ),
            );
          }).toList(),
        ),
      );
    });
  }
}
