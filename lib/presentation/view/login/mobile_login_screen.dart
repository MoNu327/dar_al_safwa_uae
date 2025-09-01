import 'package:country_code_picker/country_code_picker.dart';
import 'package:majan/core/routes/app_route.dart';
import 'package:majan/presentation/view_model/localization_controller.dart';
import 'package:majan/presentation/view_model/mobile_login_controller.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/presentation/widgets/language_text_button.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/custom_size.dart';
import '../../widgets/custom_elevated_button.dart';

class MobileLoginScreen extends StatelessWidget {
  MobileLoginScreen({super.key});

  final LocalizationController _localizationController = Get.find();
  final MobileLoginController _mobileLoginController =
      Get.put(MobileLoginController());

  @override
  Widget build(BuildContext context) {
    final screenHeight = Get.height;
    final screenWidth = Get.width;
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = screenHeight * 0.05;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - verticalPadding * 2,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: screenHeight2,
                    children: [
                      _buildHeader(),
                      const Divider(),
                      _buildTitleAndSubtitle(screenHeight),
                      _buildMobileInputField(screenWidth, screenHeight),
                      kHeight(0.01),
                      Obx(() {
                        return CustomButtonWidget(
                          childWidgetLoader: _mobileLoginController.isLoading.value,
                          buttonTextColor: AppColors.primaryColor,
                          buttonColor: AppColors.black,
                          buttonTitle: 'Send OTP',
                          onPressed: _mobileLoginController.isLoading.value
                              ? null
                              : _mobileLoginController.sendOtp,
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildBackButton(),
        LanguageTextButton(localizationController: _localizationController),
      ],
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: _mobileLoginController.navigateToBack,
      borderRadius: BorderRadius.circular(50),
      splashColor: AppColors.splashBackgroundColor,
      child: Container(
        width: 50,
        height: 50,
        decoration: const BoxDecoration(
          color: AppColors.whiteLight,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_sharp,
          color: AppColors.black800,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildTitleAndSubtitle(double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: _localizationController.translate('login_with_mobile_number'),
          color: AppColors.black,
          fontWeight: FontWeight.w500,
          fontSize: screenHeight * 0.03,
        ),
        SizedBox(height: screenHeight * 0.01),
        CustomTextWidget(
          title: _localizationController
              .translate("please_enter_your_mobile_number_correctly"),
          fontSize: screenHeight * 0.02,
          color: AppColors.lightGrey,
        ),
      ],
    );
  }

  Widget _buildMobileInputField(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextWidget(
          title: _localizationController.translate("mobile_number"),
          color: AppColors.black,
          fontSize: popularPlaceTitle,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: screenHeight * 0.005),
        Row(
          children: [
            Obx(
              () => Container(
                width: screenWidth * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.black500),
                ),
                child: CountryCodePicker(
                  initialSelection:
                      _mobileLoginController.selectedCountryCode.value.isEmpty
                          ? '+968' // Default to Oman if no selection
                          : _mobileLoginController.selectedCountryCode.value,
                  onChanged: _mobileLoginController.changeCountryCode,
                  // Only these countries will be shown
                  countryFilter: const ['OM', 'AE', 'US'],
                  // UI configurations
                  hideSearch: true,
                  showDropDownButton: true,
                  padding: EdgeInsets.zero,
                  showFlag: true,
                  showFlagDialog: true,
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false,
                  flagWidth: screenWidth * 0.05,
                  headerText: 'Select Country Code',
                  headerTextStyle: GoogleFonts.poppins(
                    color: AppColors.black,
                    fontSize: screenHeight * 0.01,
                  ),
                  textStyle: GoogleFonts.poppins(
                    color: AppColors.black,
                    fontSize: screenHeight * 0.012,
                  ),
                  headerAlignment: MainAxisAlignment.spaceBetween,
                  textOverflow: TextOverflow.clip,
                ),
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Expanded(
              child: TextField(
                controller: _mobileLoginController.mobileNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: _localizationController.translate('mobile_number'),
                  hintStyle: GoogleFonts.poppins(
                    color: AppColors.lightGrey,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.015,
                    horizontal: screenWidth * 0.05,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.lightGrey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryColor),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.redColor,
                      width: 1.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.redColor,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}