import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/view/home/widgets/property_search_widget.dart';
import 'package:majan/presentation/view/search/controllers/search_screen_controller.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/login_controller.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/presentation/widgets/loader_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

import '../../../controllers/network_controller.dart';
import '../../../widgets/no_internet_widegt.dart';

class SearchScreen extends StatelessWidget {
  SearchScreen({super.key});

  final SearchScreenController searchScreenController =
      Get.put(SearchScreenController());

  @override
  Widget build(BuildContext context) {
    final LocalizationController localizationController = Get.find();
    final NetworkController networkController = Get.find<NetworkController>();
    final LoginController loginController = Get.put(LoginController());
    final FirebaseAuth auth = FirebaseAuth.instance;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showExitConfirmation();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          toolbarHeight: Get.height * 0.1,
          title: Obx(() {
            return CustomTextWidget(
              title: localizationController.translate('title'),
              fontSize: Get.height * 0.025,
              color: AppColors.secondaryColor,
              fontWeight: FontWeight.w600,
            );
          }),
          actions: [
            LanguageTextButton(
                localizationController: localizationController),
            Padding(
              padding: const EdgeInsets.all(10),
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == "logout") {
                    Get.defaultDialog(
                      title: "Logout",
                      middleText: "Are you sure you want to log out?",
                      textConfirm: "Yes",
                      textCancel: "No",
                      confirmTextColor: Colors.white,
                      onConfirm: () {
                        loginController.logout();
                        Get.back();
                      },
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: "logout",
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Logout"),
                      ],
                    ),
                  ),
                ],
                child: CircleAvatar(
                  radius: screenHeight * 0.025,
                  backgroundColor: AppColors.primaryColor,
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: auth.currentUser?.photoURL ??
                          "https://i.postimg.cc/VLRdMxPK/profileimage.png",
                      useOldImageOnUrlChange: false,
                      width: screenWidth,
                      height: screenHeight,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) {
                        return const Icon(
                          Icons.error,
                          color: AppColors.primaryColor,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Obx(() {
          // Show loading indicator for search dropdown
          if (searchScreenController.isLoadingSearchDropdown.value) {
            return const Center(
              child: CustomLoaderWidget(),
            );
          }

          // Show error message for dropdown fetch failure
          if (searchScreenController.searchDropdownErrorMessage.value.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: screenHeight * 0.2,
                    child: Lottie.asset(
                      fit: BoxFit.cover,
                      "assets/lottie/NotFoundLottie.json",
                    ),
                  ),
                  kHeight(0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: CustomTextWidget(
                      title: searchScreenController.searchDropdownErrorMessage.value,
                      textAlign: TextAlign.center,
                      fontSize: screenHeight * 0.02,
                    ),
                  ),
                  kHeight(0.03),
                  // Action buttons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back button
                      ElevatedButton.icon(
                        onPressed: () {
                          searchScreenController.searchDropdownErrorMessage.value = '';
                          searchScreenController.refreshSearchDropdown();
                        },
                        icon: const Icon(Icons.arrow_back, size: 20),
                        label: CustomTextWidget(
                          title: localizationController.translate('back') ?? 'Back',
                          color: Colors.white,
                          fontSize: screenHeight * 0.018,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      // Retry button
                      ElevatedButton.icon(
                        onPressed: searchScreenController.refreshSearchDropdown,
                        icon: const Icon(Icons.refresh, size: 20),
                        label: CustomTextWidget(
                          title: localizationController.translate('retry') ?? 'Retry',
                          color: Colors.white,
                          fontSize: screenHeight * 0.018,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.05,
                            vertical: screenHeight * 0.015,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Check network connectivity
          if (!networkController.isConnected.value) {
            return NoInternetWidegt();
          }

          // Check if dropdown data is available
          final dropdownData = searchScreenController.searchDropdownResponse.value?.data;
          
          if (dropdownData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, size: 60, color: Colors.grey),
                  kHeight(0.02),
                  CustomTextWidget(
                    title: 'No search options available',
                    textAlign: TextAlign.center,
                  ),
                  kHeight(0.02),
                  ElevatedButton.icon(
                    onPressed: searchScreenController.refreshSearchDropdown,
                    icon: const Icon(Icons.refresh),
                    label: CustomTextWidget(
                      title: localizationController.translate('retry') ?? 'Retry',
                    ),
                  ),
                ],
              ),
            );
          }

          // Show loading indicator for search results
          if (searchScreenController.isLoadingSearchResults.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomLoaderWidget(),
                  kHeight(0.02),
                  CustomTextWidget(
                    title: 'Searching properties...',
                    fontSize: screenHeight * 0.018,
                    color: AppColors.secondaryColor,
                  ),
                ],
              ),
            );
          }

          // Show "No Properties Found" message
          if (searchScreenController.searchResults.isEmpty && 
              searchScreenController.searchResponse.value != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: screenHeight * 0.25,
                    child: Lottie.asset(
                      "assets/lottie/NotFoundLottie.json",
                      fit: BoxFit.contain,
                    ),
                  ),
                  kHeight(0.02),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: CustomTextWidget(
                      title: 'No properties found matching your criteria',
                      textAlign: TextAlign.center,
                      fontSize: screenHeight * 0.022,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryColor,
                    ),
                  ),
                  kHeight(0.01),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                    child: CustomTextWidget(
                      title: 'Try adjusting your search filters',
                      textAlign: TextAlign.center,
                      fontSize: screenHeight * 0.018,
                      color: Colors.grey,
                    ),
                  ),
                  kHeight(0.04),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back button
                      ElevatedButton.icon(
                        onPressed: () {
                          // Clear search results and go back to search form
                          searchScreenController.clearSearchResults();
                        },
                        icon: const Icon(Icons.arrow_back, size: 20),
                        label: CustomTextWidget(
                          title: localizationController.translate('back') ?? 'Back',
                          color: Colors.white,
                          fontSize: screenHeight * 0.018,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: screenHeight * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.04),
                      // Try Again button
                      ElevatedButton.icon(
                        onPressed: () {
                          // Clear and reset search
                          searchScreenController.clearSearchResults();
                          searchScreenController.clearSelections();
                        },
                        icon: const Icon(Icons.search, size: 20),
                        label: CustomTextWidget(
                          title: 'New Search',
                          color: Colors.white,
                          fontSize: screenHeight * 0.018,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                            vertical: screenHeight * 0.018,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }

          // Main content - Search form or results
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight3,
                horizontal: screenWidth3,
              ),
              child: Column(
                children: [
                  // Search form
                  PropertySearchCard(
                    propertyOptions: dropdownData.propertyOptions,
                    propertyTypes: dropdownData.propertyTypes,
                    propertyLocations: dropdownData.propertyLocations,
                    propertyBedsBaths: dropdownData.propertyBedsBaths,
                    propertyPrices: dropdownData.propertyPrices,
                  ),
                  kHeight(0.02),
                  
                  // Show search animation if no results yet
                  if (searchScreenController.searchResults.isEmpty)
                    Lottie.asset(
                      'assets/lottie/search.json',
                      width: screenWidth * 0.5,
                      height: screenHeight * 0.3,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                    ),
                  
                  // Show search results if available
                  if (searchScreenController.searchResults.isNotEmpty)
                    Column(
                      children: [
                        // Results count
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                          child: CustomTextWidget(
                            title: 'Found ${searchScreenController.searchResultsCount} properties',
                            fontSize: screenHeight * 0.02,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        // Display search results here
                        // Add your property list widget
                      ],
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

void showExitConfirmation() async {
  Get.defaultDialog(
    title: 'Confirm Exit',
    titleStyle: TextStyle(
      color: AppColors.secondaryColor,
      fontSize: screenHeight * 0.023,
    ),
    middleText: 'Are you sure you want to exit?',
    textConfirm: 'Yes',
    textCancel: 'No',
    confirmTextColor: AppColors.white,
    cancelTextColor: AppColors.secondaryColor,
    onConfirm: () {
      SystemNavigator.pop();
    },
  );
}