import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

Widget notificationNavigation() {
  return InkWell(
    onTap: () {
      // Get.toNamed("/notifications");
    },
    child: SizedBox(
      height: screenHeight * 0.03,
      child: Image.asset('assets/images/Notifications.png'),
    ),
  );
}
