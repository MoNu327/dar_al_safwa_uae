import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/custom_size.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/custom_elevated_button.dart';
import '../property_details/controller/property_details_controller.dart';

class MobileNumberUpdatePage extends StatefulWidget {
  final bool navigateToChat;
  final String? unitId;
  final String? propertyName;
  final String? agentEmail;
  final bool navigateToCall;

  final String phone;

  final String propertyId;

  const MobileNumberUpdatePage({
    Key? key,
    required this.phone,
    required this.propertyId,
    this.navigateToChat = false,
    this.navigateToCall = false,
    this.unitId,
    this.propertyName,
    this.agentEmail,
  }) : super(key: key);


  @override
  State<MobileNumberUpdatePage> createState() => _MobileNumberUpdatePageState();
}

class _MobileNumberUpdatePageState extends State<MobileNumberUpdatePage> {
  final TextEditingController mobileController = TextEditingController();
  final RxBool isLoading = false.obs;

  Future<void> _handleSave() async {
    final mobile = mobileController.text.trim();
    // if (mobile.isEmpty || mobile.length < 8) {
    //   Get.snackbar("Invalid", "Please enter a valid mobile number");
    //   return;
    // }

    isLoading.value = true;
    final controller = Get.find<PropertyDetailsController>();
    await controller.saveMobileNumber(mobile: mobile, phone: widget.phone, propertyId: widget.propertyId);
    isLoading.value = false;

    // Return to previous screen with updated data
    // Get.back(result: {
    //   'mobile': mobile,
    //   'propertyId': widget.propertyId,
    //   'phone': widget.phone,
    //   'navigateToChat': widget.navigateToChat,
    //   'navigateToCall': widget.navigateToCall,
    //   'unitId': widget.unitId,
    //   'propertyName': widget.propertyName,
    //   'agentEmail': widget.agentEmail,
    // });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(title: const Text("Update Mobile Number"),
      backgroundColor: AppColors.white,),
      body:
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.topLeft,
              child: Text(
                " Mobile number is required to proceed.*",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Enter your mobile number:",
                style: TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Mobile Number',
              ),
            ),

            const SizedBox(height: 40),

            Center(
              child: CustomButtonWidget(
                buttonTitle: "Save",
                onPressed: isLoading.value ? null : _handleSave,
                childWidgetLoader: isLoading.value,
                buttonColor: AppColors.secondaryColor,
                buttonTextColor: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                buttonShape: "rect",
                buttonHeight: screenHeight * 0.06,
                buttonWidth: screenWidth * 0.4,

              ),
            ),
          ],
        )),
      ),
    );
  }
}
