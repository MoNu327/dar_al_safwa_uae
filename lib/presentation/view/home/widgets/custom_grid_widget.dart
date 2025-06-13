// import 'package:dar_al_safwa/core/constants/custom_size.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// import '../../../../core/theme/app_colors.dart';
// import '../../../widgets/custom_text_widget.dart';
// import 'custom_stack_box.dart';

// class CustomGridViewWidget extends StatelessWidget {
//   const CustomGridViewWidget({
//     super.key,
//     required this.imageUrl,
//     required this.title,
//     required this.price,
//     required this.propertyDeal,
//     required this.propertyType,
//     required this.location,
//     required this.bedrooms,
//     required this.bathrooms,
//     this.area,
//   });
//   final String imageUrl;
//   final String title;
//   final String price;
//   final String propertyDeal;
//   final String propertyType;
//   final String location;
//   final String bedrooms;
//   final String bathrooms;
//   final String? area;

//   @override
//   Widget build(BuildContext context) {
//     final isArabic = Get.locale?.languageCode == 'ar';

//     return Container(
//       padding: EdgeInsets.symmetric(
//         vertical: screenHeight * 0.015,
//         horizontal: screenWidth2,
//       ),
//       clipBehavior: Clip.antiAlias,
//       decoration: ShapeDecoration(
//         color: Colors.white,
//         shape: RoundedRectangleBorder(
//           side: const BorderSide(width: 0.80, color: Color(0x331C1C1C)),
//           borderRadius: BorderRadius.circular(16),
//         ),
//         shadows: const [
//           BoxShadow(
//             color: Color(0x199E9E9E),
//             blurRadius: 7,
//             offset: Offset(0, 3),
//             spreadRadius: 0,
//           ),
//           BoxShadow(
//             color: Color(0x169E9E9E),
//             blurRadius: 12,
//             offset: Offset(0, 12),
//             spreadRadius: 0,
//           ),
//           BoxShadow(
//             color: Color(0x0C9E9E9E),
//             blurRadius: 17,
//             offset: Offset(0, 28),
//             spreadRadius: 0,
//           ),
//           BoxShadow(
//             color: Color(0x029E9E9E),
//             blurRadius: 20,
//             offset: Offset(0, 49),
//             spreadRadius: 0,
//           ),
//           BoxShadow(
//             color: Color(0x009E9E9E),
//             blurRadius: 22,
//             offset: Offset(0, 77),
//             spreadRadius: 0,
//           )
//         ],
//       ),
//       child: Column(
//         spacing: Get.height * 0.002,
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               Container(
//                 width: double.infinity,
//                 height: Get.height * 0.14,
//                 clipBehavior: Clip.antiAlias,
//                 decoration: ShapeDecoration(
//                   image: DecorationImage(
//                     image: NetworkImage(imageUrl),
//                     fit: BoxFit.cover,
//                   ),
//                   color: AppColors.primaryColor,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//                 child: Align(
//                   alignment: Alignment.bottomRight,
//                   child: Padding(
//                     padding: const EdgeInsets.all(5),
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       spacing: 5,
//                       children: [
//                         CustomStackBoxWidget(
//                           title: propertyDeal,
//                         ),
//                         CustomStackBoxWidget(
//                           title: propertyType,
//                         )
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//               // Align(
//               //   alignment: Alignment.topRight,
//               //   child: IconButton(
//               //     icon: const Icon(Icons.favorite_border),
//               //     color: AppColors.white,
//               //     onPressed: () {
//               //       // Handle favorite button press
//               //     },
//               //   ),
//               // ),
//             ],
//           ),
//           CustomTextWidget(
//             title: "$price / ",
//             color: AppColors.secondaryColor,
//           ),
//           CustomTextWidget(
//             title: title,
//             maxLines: 2,
//           ),
//           SizedBox(
//             width: double.infinity,
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               mainAxisAlignment: MainAxisAlignment.start,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Icon(
//                   Icons.location_on,
//                   size: 12,
//                   color: AppColors.secondaryColor,
//                 ),
//                 Flexible(
//                   child: CustomTextWidget(
//                     title: location,
//                     fontSize: Get.height * 0.012,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../widgets/custom_text_widget.dart';
import 'custom_stack_box.dart';

class CustomGridViewWidget extends StatelessWidget {
  CustomGridViewWidget({
    super.key,
    required this.address,
    required this.propertyType,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.propertyDeal,
    required this.location,
  });
  final String imageUrl;
  final String title;
  final String price;
  final String propertyDeal;
  final String propertyType;
  final String location;
  final String address;
  final isArabic = Get.locale?.languageCode == 'ar';
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: Get.height * 0.015,
          horizontal: Get.width * 0.025,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 0.80, color: Color(0x331C1C1C)),
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            // Your existing shadows...
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final String cleanImageUrl = (imageUrl.trim().isNotEmpty &&
                    Uri.tryParse(imageUrl)?.isAbsolute == true)
                ? imageUrl.trim()
                : "https://i.postimg.cc/Y90PCDgF/no-image-icon-6.png";
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: screenHeight1,
              children: [
                // Image Section (65% of available height)
                SizedBox(
                  height: constraints.maxHeight * 0.65,
                  width: double.infinity,
                  child: Container(
                    width: double.infinity,
                    height: constraints.maxHeight * 0.55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      // Add color to see if container is properly sized
                      // color: Colors.grey.withOpacity(0.1), // Debug only
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            useOldImageOnUrlChange: false,
                            imageUrl: cleanImageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorWidget: (context, url, error) {
                              debugPrint(
                                  "Failed to load image: $url - Error: $error");
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  "assets/images/prefixed.jpg",
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              );
                            },
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: EdgeInsets.all(Get.width * 0.01),
                            child: Wrap(
                              spacing: Get.width * 0.01,
                              runSpacing: Get.width * 0.01,
                              children: [
                                CustomStackBoxWidget(
                                    title: propertyDeal ?? "N/A"),
                                CustomStackBoxWidget(
                                    title: propertyType ?? "N/A"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Content Section (70% of available height)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price and Section
                      CustomTextWidget(
                        title: price ?? "N/A",
                        fontSize: H18,
                        color: AppColors.secondaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                      // Property Title
                      CustomTextWidget(
                        title: title ?? "N/A",
                        fontSize: tagTitle,
                        fontWeight: FontWeight.w600,
                      ),

                      // Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: screenWidth1,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: screenHeight * 0.014,
                            color: AppColors.secondaryColor,
                          ),
                          Expanded(
                            child: CustomTextWidget(
                              title: address ?? "N/A",
                              fontSize: detailContentTitle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Helper function to calculate dynamic aspect ratio
double calculateChildAspectRatio() {
  final screenWidth = Get.width;
  final screenHeight = Get.height;

  // Base aspect ratio for phones
  double aspectRatio = 0.75;

  // Adjust for tablets
  if (screenWidth > 600) {
    aspectRatio = 0.7;
  }

  // Adjust for landscape
  if (screenWidth > screenHeight) {
    aspectRatio = 1.1;
  }

  return aspectRatio;
}
