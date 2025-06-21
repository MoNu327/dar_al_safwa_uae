import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';

class ApprovalPendingPage extends StatelessWidget {
  const ApprovalPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: Get.width * 0.03, vertical: Get.height * 0.05),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                  'assets/lottie/approval_pending.json', // Replace with your Lottie file path
                  width: Get.height * 0.15,
                  height: Get.height * 0.16,
                  fit: BoxFit.contain,
                  repeat: true,
                  reverse: true),
              kHeight(0.02),
              CustomTextWidget(
                title: "Your account is pending approval",
                fontSize: popularPlaceTitle,
                fontWeight: FontWeight.bold,
                textAlign: TextAlign
                    .center, // Add this if CustomTextWidget supports it
              ),
              kHeight(0.015),
              CustomTextWidget(
                title: "Please wait for the admin to approve your account.",
                fontSize: tagTitle,
                textAlign: TextAlign
                    .center, // Add this if CustomTextWidget supports it
              ),
            ],
          ),
        ),
      ),
    );
  }
}
