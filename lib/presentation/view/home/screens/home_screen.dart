import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/presentation/controllers/network_controller.dart';
import 'package:dar_al_safwa/presentation/view/home/controllers/home_screen_controller.dart';
import 'package:dar_al_safwa/presentation/view/home/widgets/custom_list_widget.dart';
import 'package:dar_al_safwa/presentation/view/home/widgets/custom_location_dropdwon.dart';
import 'package:dar_al_safwa/presentation/view/home/widgets/property_slider_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/language_text_button.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/widgets/no_internet_widegt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../view_model/localization_controller.dart';
import '../../../view_model/login_controller.dart';
import '../../../widgets/loader_widget.dart';
import '../../../widgets/notification_navigation_widget.dart';
import '../../search/controllers/search_screen_controller.dart';
import '../../search/screens/search_screen.dart';
import '../widgets/custom_grid_widget.dart';
import '../widgets/property_search_widget.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final LocalizationController localizationController = Get.find();
  final LoginController loginController = Get.put(LoginController());
  final NetworkController networkController = Get.find<NetworkController>();
  final RxBool showPropertySearchCard = false.obs;
  final SearchScreenController searchScreenController =
      Get.put(SearchScreenController());

  final HomeScreenController homeScreenController =
      Get.put(HomeScreenController());
  final FirebaseAuth auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(() {
                  return Row(
                    children: [
                      CustomTextWidget(
                        title: localizationController.translate('title'),
                        fontSize: Get.height * 0.025,
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                      LanguageTextButton(
                          localizationController: localizationController),
                    ],
                  );
                }),
                CustomLocationDropdown()
              ],
            ),
            actions: [
              notificationNavigation(),
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
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: homeScreenController.refreshAll,
            child: Obx(() {
              // Show loader when loading or no internet
              if (homeScreenController.isLoading.value ||
                  !networkController.isConnected.value) {
                return Center(
                  child: !networkController.isConnected.value
                      ? NoInternetWidegt()
                      : const CustomLoaderWidget(),
                );
              }
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    spacing: Get.height * 0.01,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        return CustomTextWidget(
                          fontStyle: FontStyle.italic,
                          title: localizationController.translate('welcome'),
                        );
                      }),

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
                      kHeight(0.01),
                      // Banner Slider
                      Obx(() {
                        if (homeScreenController.errorMessage.isNotEmpty) {
                          return ErrorWidget(
                              homeScreenController.errorMessage.value);
                        }
                        return PropertyBannerSlider(
                          banners:
                              homeScreenController.banners.value?.data ?? [],
                        );
                      }),

                      // popular properties
                      Obx(() {
                        return CustomTextWidget(
                          fontWeight: FontWeight.w700,
                          fontSize: Get.height * 0.02,
                          title: localizationController
                              .translate('popular_properties'),
                        );
                      }),
                      SizedBox(child: Obx(() {
                        debugPrint(
                            homeScreenController.popularErrorMessage.value);
                        if (homeScreenController
                            .popularErrorMessage.value.isNotEmpty) {
                          return CustomTextWidget(
                            title:
                                homeScreenController.popularErrorMessage.value,
                            fontSize: tagTitle,
                          );
                        }

                        final popularProperties = homeScreenController
                                .popularProperties.value?.data ??
                            [];
                        final isArabic = Get.locale?.languageCode == 'ar';

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: calculateChildAspectRatio(),
                          ),
                          itemCount: popularProperties.length,
                          itemBuilder: (context, index) {
                            final property = popularProperties[index];
                            return GestureDetector(
                              onTap: () {
                                Get.toNamed('/propertyDetails',
                                    arguments: {'propertyId': property.id});
                              },
                              child: CustomGridViewWidget(
                                imageUrl: property.propertyImage ?? '',
                                title: isArabic
                                    ? property.propertyTitle?.ar ?? ''
                                    : property.propertyTitle?.en ?? '',
                                price: isArabic
                                    ? property.propertyPrice?.formatted?.ar ??
                                        ''
                                    : property.propertyPrice?.formatted?.en ??
                                        '',
                                propertyDeal: isArabic
                                    ? property.propertyDeal?.ar ?? ''
                                    : property.propertyDeal?.en ?? '',
                                propertyType: isArabic
                                    ? property.propertyType?.ar ?? ''
                                    : property.propertyType?.en ?? '',
                                location: isArabic
                                    ? property.propertyLocation?.ar ?? ''
                                    : property.propertyLocation?.en ?? '',
                                address: isArabic
                                    ? property.propertyAddress?.ar ?? ''
                                    : property.propertyAddress?.en ?? '',
                              ),
                            );
                          },
                        );
                      })),

                      // featured properties
                      Obx(() {
                        return CustomTextWidget(
                          fontWeight: FontWeight.w700,
                          fontSize: Get.height * 0.02,
                          title: localizationController
                              .translate('featured_properties'),
                        );
                      }),

                      Obx(() {
                        // if (homeScreenController.isLoadingFeatured.value) {
                        //   return const Center(child: CustomLoaderWidget());
                        // }

                        if (homeScreenController
                            .featuredErrorMessage.value.isNotEmpty) {
                          return CustomTextWidget(
                            title:
                                homeScreenController.popularErrorMessage.value,
                            fontSize: tagTitle,
                          );
                        }
                        // if (homeScreenController
                        //     .featuredErrorMessage.value.isEmpty) {
                        //   return CustomTextWidget(
                        //     title:
                        //         homeScreenController.popularErrorMessage.value,
                        //     fontSize: tagTitle,
                        //   );
                        // }

                        final featuredProperties = homeScreenController
                                .featuredProperties.value?.data ??
                            [];

                        final isArabic = Get.locale?.languageCode == 'ar';

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: featuredProperties.length,
                          itemBuilder: (context, index) {
                            final property = featuredProperties[index];

                            return GestureDetector(
                              onTap: () {
                                Get.toNamed('/propertyDetails',
                                    arguments: {'propertyId': property.id});
                              },
                              child: CustomListWidget(
                                imageUrl: property.image ?? '',
                                title: localizationController
                                    .translate('title_price'),
                                price: isArabic
                                    ? property.price?.formatted?.ar ?? ''
                                    : property.price?.formatted?.en ?? '',
                                propertyDeal: isArabic
                                    ? property.dealType?.ar ?? ''
                                    : property.dealType?.en ?? '',
                                subtitle: isArabic
                                    ? property.title?.ar ?? ''
                                    : property.title?.en ?? '',
                                type: isArabic
                                    ? property.type?.ar ?? ''
                                    : property.type?.en ?? '',
                                location: isArabic
                                    ? property.location?.ar ?? ''
                                    : property.location?.en ?? '',
                                bedrooms: property.bedrooms ?? 0,
                                bathrooms: property.bathrooms ?? 0,
                                area: isArabic
                                    ? property.area?.ar ?? ''
                                    : property.area?.en ?? '',
                              ),
                            );
                          },
                        );
                      })
                    ],
                  ),
                ),
              );
            }),
          ),
        ));
  }
}
