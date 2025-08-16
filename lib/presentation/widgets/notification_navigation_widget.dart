import 'package:majan/core/constants/custom_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

Widget notificationNavigation() {
  return InkWell(
    onTap: () {
      // Get.toNamed("/notifications");
    },
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        height: screenHeight * 0.03,
        child: Image.asset('assets/images/Notifications.png'),
      ),
    ),
  );
}
