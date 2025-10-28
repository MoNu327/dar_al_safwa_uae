import 'package:majan/core/constants/custom_size.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../core/theme/app_colors.dart';

class CustomLoaderWidget extends StatelessWidget {
  const CustomLoaderWidget({super.key, this.size});
  final double? size;

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.stretchedDots(
      // leftDotColor: AppColors.secondaryColor,
      // rightDotColor: AppColors.primaryColor,
      color: AppColors.secondaryColor,
      size: size ?? screenHeight4,
    );
  }
}
