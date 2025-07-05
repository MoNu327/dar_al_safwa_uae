import 'package:dar_al_safwa/presentation/view_model/periodic_text_swapper_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../core/constants/custom_size.dart';
import '../../core/theme/app_colors.dart';

class PeriodicTextSwapperWidget extends StatelessWidget {
  final String text1;
  final String text2;
  final Duration interval;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool enableFade;

  const PeriodicTextSwapperWidget({
    super.key,
    required this.text1,
    required this.text2,
    this.interval = const Duration(minutes: 1),
    this.style,
    this.textAlign,
    this.enableFade = true,
  });

  @override
  Widget build(BuildContext context) {
    // Inject controller with unique tag to support multiple instances
    final controller = Get.put(
      PeriodicTextSwitcherController(
        text1: text1,
        text2: text2,
        interval: interval,
      ),
      tag: key.toString(), // ensures unique instance per widget
    );

    return Obx(
      () => enableFade
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Align(
                alignment: Alignment.topLeft,
                child: CustomTextWidget(
                  title: controller.currentText.value,
                  key: ValueKey(controller.currentText.value),
                  color: AppColors.black,
                  fontSize: screenHeight * 0.018,
                  fontWeight: FontWeight.w600,
                ),
              ),

              // Text(
              //   controller.currentText.value,
              //   key:
              //   style: style,
              //   textAlign: textAlign,
              //   overflow: TextOverflow.ellipsis,
              // ),
            )
          : Align(
              alignment: Alignment.topLeft,
              child: CustomTextWidget(
                title: controller.currentText.value,
                color: AppColors.black,
                fontSize: screenHeight * 0.018,
                fontWeight: FontWeight.w600,
              ),
            ),

      // Text(

      //     style: style,
      //     textAlign: textAlign,
      //     overflow: TextOverflow.ellipsis,
      //   )
    );
  }
}
