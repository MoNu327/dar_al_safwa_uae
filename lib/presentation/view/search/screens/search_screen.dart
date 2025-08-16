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
                          // size: radius ?? screenHeight5,
                        );
                      },
                    )),
                  ),
                ),
              ),
            ],
          ),
          body: Obx(() {
            if (searchScreenController.isLoadingSearchDropdown.value) {
              return const Center(
                child: CustomLoaderWidget(),
              );
            }

            // if (searchScreenController
            //     .searchDropdownErrorMessage.value.isEmpty) {
            //   return Center(
            //     child: Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: [
            //         SizedBox(
            //             height: screenHeight * 0.3,
            //             child: Lottie.asset(
            //                 fit: BoxFit.cover,
            //                 "assets/lottie/NotFoundLottie.json")),
            //         kHeight(0.01),
            //         CustomTextWidget(
            //           title: searchScreenController
            //               .searchDropdownErrorMessage.value,
            //         ),
            //         ElevatedButton(
            //             onPressed: searchScreenController.refreshSearchDropdown,
            //             child: CustomTextWidget(
            //               title: localizationController.translate('retry'),
            //             ))
            //       ],
            //     ),
            //   );
            // }

            if (searchScreenController
                .searchDropdownErrorMessage.value.isNotEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: screenHeight * 0.2,
                        child: Lottie.asset(
                            fit: BoxFit.cover,
                            "assets/lottie/NotFoundLottie.json")),
                    kHeight(0.01),
                    CustomTextWidget(
                      title: searchScreenController
                          .searchDropdownErrorMessage.value,
                    ),
                    ElevatedButton(
                        onPressed: searchScreenController.refreshSearchDropdown,
                        child: CustomTextWidget(
                          title: localizationController.translate('retry'),
                        ))
                  ],
                ),
              );
            }

            return !networkController.isConnected.value
                ? NoInternetWidegt()
                : SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: screenHeight3,
                        horizontal: screenWidth3,
                      ),
                      child: Column(
                        children: [
                          PropertySearchCard(
                            propertyOptions: searchScreenController
                                    .searchDropdownResponse
                                    .value
                                    ?.data
                                    .propertyOptions ??
                                [],
                            propertyTypes: searchScreenController
                                    .searchDropdownResponse
                                    .value
                                    ?.data
                                    .propertyTypes ??
                                [],
                            propertyLocations: searchScreenController
                                    .searchDropdownResponse
                                    .value
                                    ?.data
                                    .propertyLocations ??
                                [],
                            propertyBedsBaths: searchScreenController
                                    .searchDropdownResponse
                                    .value
                                    ?.data
                                    .propertyBedsBaths ??
                                [],
                          ),
                          Lottie.asset(
                            'assets/lottie/search.json',
                            width: screenWidth * 0.5,
                            height: screenHeight * 0.3,
                            fit: BoxFit.contain,
                            repeat: true,
                            animate: true,
                          )
                        ],
                      ),
                    ),
                  );
          })),
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
      });
}
