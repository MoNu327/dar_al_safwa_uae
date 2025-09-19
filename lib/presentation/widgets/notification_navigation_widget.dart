import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:majan/core/constants/custom_size.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:majan/domain/controller/notification_controller.dart';

Widget notificationNavigation() {
  return GetBuilder<NotificationController>(
    init: NotificationController(),
    builder: (controller) {
      return InkWell(
        onTap: () {
          Get.toNamed("/notifications");
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              SizedBox(
                height: screenHeight * 0.03,
                child: Image.asset('assets/images/Notifications.png'),
              ),
              // Notification badge
              Obx(() {
                final unreadCount = controller.unreadCount.value;
                if (unreadCount > 0) {
                  return Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
      );
    },
  );
}