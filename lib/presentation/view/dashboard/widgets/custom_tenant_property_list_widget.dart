import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class TenantPropertyListWidget extends StatelessWidget {
  final String imageUrl;
  final String propertyName;
  final String status; // "Rent" or "Owned"
  final String location;
  final VoidCallback onTap;

  const TenantPropertyListWidget({
    super.key,
    required this.imageUrl,
    required this.propertyName,
    required this.status,
    required this.location,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: screenHeight1),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.015,
            horizontal: screenWidth3,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.black600, width: 0.5),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageUrl,
                  width: screenWidth * 0.25,
                  height: screenWidth * 0.25,
                  fit: BoxFit.cover,
                ),
              ),
              kWidth(0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      title: propertyName,
                      fontSize: screenHeight * 0.02,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryColor,
                    ),
                    kHeight(0.01),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth1,
                        vertical: screenHeight05,
                      ),
                      decoration: BoxDecoration(
                        color: status == "Rent"
                            ? AppColors.secondaryColorLight.withOpacity(0.2)
                            : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomTextWidget(
                        title: status,
                        fontSize: screenHeight * 0.014,
                        fontWeight: FontWeight.w600,
                        color: status == "Rent"
                            ? AppColors.secondaryColorLight
                            : Colors.green,
                      ),
                    ),
                    kHeight(0.01),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.black600,
                          size: screenHeight * 0.015,
                        ),
                        kWidth(0.005),
                        Flexible(
                          child: CustomTextWidget(
                            title: location,
                            fontSize: screenHeight * 0.015,
                            color: AppColors.black800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.black600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
