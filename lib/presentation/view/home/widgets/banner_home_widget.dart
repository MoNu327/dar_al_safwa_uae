import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../view_model/localization_controller.dart';

class HomeBannerWidget extends StatelessWidget {
  HomeBannerWidget({super.key});

  final LocalizationController localizationController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: screenHeight * 0.13,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
            child: Container(
              width: double.infinity,
              height: screenHeight * 0.1,
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: Get.width * 0.35,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: screenWidth * 0.03,
                      ),
                      child: Stack(
                        children: List<Widget>.generate(4, (index) {
                          return Positioned(
                            top: 0,
                            bottom: 0,
                            left: index * screenWidth * 0.06,
                            child: CircleAvatar(
                              radius: screenWidth * 0.06,
                              backgroundImage: index < 3
                                  ? const AssetImage("assets/images/person.png")
                                  : null,
                              backgroundColor:
                                  index < 3 ? Colors.transparent : Colors.white,
                              child: index == 3
                                  ? CustomTextWidget(
                                      title: '+100',
                                      color: AppColors.secondaryColor,
                                      fontSize: Get.height * 0.014,
                                      fontWeight: FontWeight.w600,
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: screenWidth2, left: screenWidth2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextWidget(
                            title: 'Trusted by Clients,',
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: Get.height * 0.018,
                          ),
                          CustomTextWidget(
                            title: 'Driven by Excellence.',
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: Get.height * 0.018,
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: screenHeight * 0.003,
          right: screenWidth * 0.06,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth3,
              vertical: screenHeight05,
            ),
            decoration: BoxDecoration(
              color: AppColors.onlineGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CustomTextWidget(
                  title: localizationController.translate('Verified'),
                  fontSize: Get.height * 0.013,
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
                kWidth(0.01),
                Icon(
                  Icons.verified,
                  color: AppColors.white,
                  size: Get.height * 0.015,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
