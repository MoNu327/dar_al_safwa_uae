import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LanguageTextButton extends StatelessWidget {
  const LanguageTextButton({
    super.key,
    required this.localizationController,
  });

  final LocalizationController localizationController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return TextButton(
        onPressed: () async {
          String newLang =
              localizationController.currentLocale.value.languageCode == 'en'
                  ? 'ar'
                  : 'en';
          await localizationController.loadTranslations(newLang);
          Get.updateLocale(Locale(newLang));
        },
        child: Row(
          spacing: 2,
          mainAxisSize: MainAxisSize.min, // Adjust width to fit content
          children: [
            CustomTextWidget(
                color: AppColors.secondaryColorLight,
                fontWeight: FontWeight.w500,
                title:
                    localizationController.currentLocale.value.languageCode ==
                            'en'
                        ? 'English'
                        : 'العربية'),
            const Icon(
              Icons.language,
              color: AppColors.secondaryColorLight,
            ),
          ],
        ),
      );
    });
  }
}
