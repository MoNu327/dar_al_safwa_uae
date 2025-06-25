import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CustomBottomSheet extends StatelessWidget {
  final String totalPrice;
  final String period;
  final VoidCallback? onWhatsAppPressed;
  final VoidCallback? onCallPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final double height;

  const CustomBottomSheet({
    Key? key,
    this.totalPrice = "3000 OMR",
    this.period = "month",
    this.onWhatsAppPressed,
    this.onCallPressed,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.black,
    this.buttonColor = const Color(0xFF25D366),
    this.height = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("Building CustomBottomSheet with height: $height"); // Debug

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(screenWidth4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Price Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Total Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),

                    CustomTextWidget(
                      title: '$totalPrice / $period',
                      color: AppColors.secondaryColor,
                      fontSize: H18,
                      fontWeight: FontWeight.w600,
                    )
                    // Text(
                    //   '$totalPrice / $period',
                    //   style: TextStyle(
                    //     fontSize: 18,
                    //     fontWeight: FontWeight.bold,
                    //     color: textColor,
                    //   ),
                    //   overflow: TextOverflow.ellipsis,
                    // ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.message,
                    backgroundColor: AppColors.primaryColor,
                    onPressed: onWhatsAppPressed ??
                        () {
                          print("WhatsApp pressed - no callback provided");
                        },
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    icon: Icons.phone,
                    backgroundColor: AppColors.primaryColor,
                    onPressed: onCallPressed ??
                        () {
                          print("Call pressed - no callback provided");
                        },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          print("Button pressed: $icon"); // Debug
          onPressed();
        },
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: AppColors.black,
            size: 24,
          ),
        ),
      ),
    );
  }
}
