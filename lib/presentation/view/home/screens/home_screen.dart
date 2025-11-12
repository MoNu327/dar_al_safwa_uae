import 'package:cached_network_image/cached_network_image.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/controllers/network_controller.dart';
import 'package:majan/presentation/view/home/controllers/home_screen_controller.dart';
import 'package:majan/presentation/view/home/widgets/custom_list_widget.dart';
import 'package:majan/presentation/view/home/widgets/custom_location_dropdwon.dart';
import 'package:majan/presentation/view/home/widgets/property_slider_widget.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/widgets/no_internet_widegt.dart';
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
  
  // Initialize search controller early and wait for it to be ready
  final SearchScreenController searchScreenController = Get.put(SearchScreenController());
  final HomeScreenController homeScreenController = Get.put(HomeScreenController());
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
            onRefresh: () async {
              // Refresh both home content and search dropdown
              await Future.wait([
                homeScreenController.refreshAll(),
                searchScreenController.refreshSearchDropdown(),
              ]);
            },
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

                      // Search Card with proper loading and error handling
                      Obx(() {
                        if (searchScreenController.isLoadingSearchDropdown.value) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(screenWidth6)),
                              color: Colors.white,
                              border: Border.all(
                                color: AppColors.black800.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: const Center(child: CustomLoaderWidget()),
                          );
                        }

                        if (searchScreenController.searchDropdownErrorMessage.value.isNotEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(screenWidth6)),
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 40),
                                SizedBox(height: 10),
                                CustomTextWidget(
                                  title: searchScreenController.searchDropdownErrorMessage.value,
                                  color: Colors.red,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                ElevatedButton(
                                  onPressed: () => searchScreenController.refreshSearchDropdown(),
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        final searchData = searchScreenController.searchDropdownResponse.value?.data;
                        
                        if (searchData == null) {
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
                            child: CustomTextWidget(
                              title: 'No search data available',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return PropertySearchCard(
                          propertyOptions: searchData.propertyOptions,
                          propertyTypes: searchData.propertyTypes,
                          propertyLocations: searchData.propertyLocations,
                          propertyBedsBaths: searchData.propertyBedsBaths,
                          propertyPrices: searchData.propertyPrices,
                        );
                      }),

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
                      
                      // Popular properties section
                      SizedBox(
                        child: Obx(() {
                          debugPrint(homeScreenController.popularErrorMessage.value);
                          
                          if (homeScreenController.popularErrorMessage.value.isNotEmpty) {
                            return CustomTextWidget(
                              title: homeScreenController.popularErrorMessage.value,
                              fontSize: tagTitle,
                            );
                          }

                          final popularProperties = homeScreenController.popularProperties.value?.data ?? [];
                          debugPrint("Popular properties count: ${popularProperties.length}");
                          
                          if (popularProperties.isEmpty) {
                            return CustomTextWidget(
                              title: "No popular properties available",
                              fontSize: tagTitle,
                            );
                          }

                          final isArabic = Get.locale?.languageCode == 'ar';

                          return // Alternative approach with better touch handling:

GridView.builder(
  physics: const NeverScrollableScrollPhysics(),
  shrinkWrap: true,
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 10,
    mainAxisSpacing: 10,
    childAspectRatio: calculateChildAspectRatio(),
  ),
  itemCount: popularProperties.length,
  itemBuilder: (context, index) {
    final property = popularProperties[index];
    final isArabic = Get.locale?.languageCode == 'ar';
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        child: Listener( // Use Listener for more reliable touch detection
          onPointerDown: (details) {
            debugPrint("Pointer down on popular property: ${property?.id}");
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              debugPrint("Tapped popular property: ${property?.id}");
              
              if (property?.id == null) {
                debugPrint("Property ID is null");
                return;
              }
              
              bool isCommercial = _isPropertyCommercial(property);
              final propertyTitle = isArabic
                  ? property.propertyTitle?.ar ?? property.propertyTitle?.en ?? ''
                  : property.propertyTitle?.en ?? property.propertyTitle?.ar ?? '';
              
              debugPrint("Navigating to property details...");
              
              try {
                Get.toNamed('/propertyDetails', arguments: {
                  'propertyType': property.propertyType,
                  'propertyId': property.id,
                  'unitId': property.id ?? 0,
                  'unitType': isCommercial ? 1 : 0,
                  'propertyTitle': propertyTitle,
                  'propertyData': {
                    'title': property.propertyTitle,
                    'image': property.propertyImage,
                    'price': property.propertyPrice,
                    'deal': property.propertyDeal,
                  }
                });
              } catch (e) {
                debugPrint("Navigation error: $e");
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: CustomGridViewWidget(
                imageUrl: property.propertyImage ?? '',
                title: isArabic
                    ? property.propertyTitle?.ar ?? ''
                    : property.propertyTitle?.en ?? '',
               price: getFormattedPriceWithAnnually(property.propertyPrice, isArabic),
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
            ),
          ),
        ),
      ),
    );
  },
);
                        }),
                      ),

                      // Featured properties title
                      Obx(() {
                        return CustomTextWidget(
                          fontWeight: FontWeight.w700,
                          fontSize: Get.height * 0.02,
                          title: localizationController
                              .translate('featured_properties'),
                        );
                      }),

                    // Featured properties section - Fixed
// Featured properties section
Obx(() {
  if (homeScreenController.featuredErrorMessage.value.isNotEmpty) {
    return CustomTextWidget(
      title: homeScreenController.featuredErrorMessage.value,
      fontSize: tagTitle,
    );
  }

  final featuredProperties = homeScreenController.featuredProperties.value?.data ?? [];
  final isArabic = Get.locale?.languageCode == 'ar';

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: featuredProperties.length,
    itemBuilder: (context, index) {
      final property = featuredProperties[index];

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          debugPrint("Tapped featured property: ${property?.id}");
          
          if (property?.id == null) return;
          
          bool isCommercial = _isPropertyCommercial(property);
          final propertyTitle = isArabic
              ? property.title?.ar ?? property.title?.en ?? ''
              : property.title?.en ?? property.title?.ar ?? '';
          
          Get.toNamed('/propertyDetails', arguments: {
            'propertyId': property.id,
            'unitId': property.id ?? 0,
            'unitType': isCommercial ? 1 : 0,
            'propertyTitle': propertyTitle,
            'propertyData': {
              'title': property.title,
              'image': property.image,
              'price': property.price,
              'deal': property.dealType,
              'type': property.type,
              'location': property.location,
              'bedrooms': property.bedrooms,
              'bathrooms': property.bathrooms,
              'area': property.area,
            }
          });
        },
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(8),
            child: CustomListWidget(
              imageUrl: property.image ?? '',
              title: localizationController.translate('title_price'),
              // ✅ FIXED: Use the helper method instead
              price: getFormattedPriceWithAnnually(property.price, isArabic),
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
          ),
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

  // Helper function to determine if a property is commercial
  // You can modify this logic based on your property data structure
  
bool _isPropertyCommercial(dynamic property) {
  try {
    // First safely check for type information in either field
    final dynamic typeData = (property is Map) 
        ? (property['type'] ?? property['propertyType'])
        : (property.type ?? property.propertyType);
    
    if (typeData != null) {
      final typeEn = (typeData is Map)
          ? (typeData['en']?.toString().toLowerCase() ?? '')
          : (typeData.en?.toString().toLowerCase() ?? '');
          
      final typeAr = (typeData is Map)
          ? (typeData['ar']?.toString().toLowerCase() ?? '')
          : (typeData.ar?.toString().toLowerCase() ?? '');
      
      final commercialKeywords = [
        'commercial', 'office', 'shop', 'retail', 'warehouse', 'industrial',
        'تجاري', 'مكتب', 'متجر', 'مستودع', 'صناعي'
      ];
      
      return commercialKeywords.any((keyword) => 
        typeEn.contains(keyword) || 
        typeAr.contains(keyword)
      );
    }
    
    // Fallback to other commercial indicators
    final isCommercial = (property is Map)
        ? property['isCommercial']
        : property.isCommercial;
        
    if (isCommercial != null) {
      return isCommercial == true;
    }
    
    final categoryId = (property is Map)
        ? property['categoryId']
        : property.categoryId;
        
    if (categoryId != null) {
      final commercialCategoryIds = [2, 3, 4]; // Adjust these IDs as needed
      return commercialCategoryIds.contains(categoryId);
    }
  } catch (e) {
    debugPrint("Error checking commercial status: $e");
  }
  
  // Default to residential
  return false;
}
// Add this helper method to your HomeScreen class to add "annually" label to prices

String getFormattedPriceWithAnnually(dynamic priceData, bool isArabic) {
  if (priceData == null) return '';
  
  // Try to get the formatted price first
  String? formattedPrice = isArabic 
      ? priceData.formatted?.ar 
      : priceData.formatted?.en;
  
  // If formatted price exists and is not empty, add annually label
  if (formattedPrice != null && formattedPrice.isNotEmpty) {
    return isArabic 
        ? '$formattedPrice / سنوياً' 
        : '$formattedPrice / annually';
  }
  
  // Fallback to raw price with manual formatting
  if (priceData.raw != null) {
    final rawPrice = priceData.raw;
    // Format the number with commas for thousands
    final formatted = rawPrice.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
    
    // Add currency symbol and annually label based on language
    return isArabic 
        ? '$formatted ر.ع / سنوياً' 
        : 'AED $formatted / annually';
  }
  
  return '';
}

}