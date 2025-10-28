import 'package:majan/core/constants/custom_size.dart';
import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:majan/presentation/widgets/custom_text_widget.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../../../controllers/network_controller.dart';
import '../../../view_model/agent_chat_controller.dart';
import '../../../widgets/no_internet_widegt.dart';

class AgentChatScreen extends StatelessWidget {
  final AgentChatController controller = Get.put(AgentChatController());
  final NetworkController networkController = Get.find<NetworkController>();
  AgentChatScreen({super.key});

  Future<bool> _onWillPop() async {
    debugPrint("🔙 AgentChatScreen: Back button pressed");
    
    // Cleanup controller before going back
    controller.cleanup();
    
    // Refresh property details when going back
    if (Get.isRegistered<PropertyDetailsController>()) {
      debugPrint("🔄 AgentChatScreen: Triggering property refresh");
      final propertyController = Get.find<PropertyDetailsController>();
      
      // Use a slight delay to ensure navigation completes first
      Future.delayed(const Duration(milliseconds: 100), () {
        propertyController.refreshPropertyDetails();
      });
    } else {
      debugPrint("⚠️ AgentChatScreen: PropertyDetailsController not found");
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() {
            final agent = !controller.isAgent.value
                ? controller.chatData['agent'] ?? {}
                : controller.chatData['user'] ?? {};
            return Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.white,
                  backgroundImage: NetworkImage(agent['avatar']?.toString() ??
                      'https://via.placeholder.com/150'),
                  radius: 20,
                ),
                SizedBox(width: Get.width * 0.01),
                Column(
                  spacing: screenHeight05,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      title: agent['name']?.toString() ?? 'Agent',
                      color: AppColors.black,
                      fontSize: Get.height * 0.02,
                      fontWeight: FontWeight.w600,
                    ),
                    Obx(
                      () => CustomTextWidget(
                        title: controller.agentStatus.value,
                        color: AppColors.onlineGreen,
                        fontSize: Get.height * 0.013,
                      ),
                    )
                  ],
                )
              ],
            );
          }),
          actions: [
            Obx(() {
              if (controller.isAgent.value) {
                return Padding(
                  padding: EdgeInsets.only(right: screenWidth2),
                  child: ElevatedButton(
                    onPressed: () {
                      controller.handleCustomerFollowUp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth2,
                        vertical: screenHeight05,
                      ),
                    ),
                    child: CustomTextWidget(
                      title: 'Customer Follow-up',
                      fontSize: Get.height * 0.013,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }
            }),
          ],
        ),
        body: Obx(() {
          if (controller.hasError.value) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 16),
                  CustomTextWidget(
                    title: 'Failed to load chat data',
                    color: AppColors.black,
                    fontSize: Get.height * 0.018,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.retryFailedOperations(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                    ),
                    child: CustomTextWidget(
                      title: 'Retry',
                      color: AppColors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // Trigger refresh when going back
                      if (Get.isRegistered<PropertyDetailsController>()) {
                        final propertyController = Get.find<PropertyDetailsController>();
                        propertyController.refreshPropertyDetails();
                      }
                      Get.back();
                    },
                    child: CustomTextWidget(
                      title: 'Go Back',
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          if (controller.isLoading.value) {
            return Center(
              child: LoadingAnimationWidget.twistingDots(
                leftDotColor: AppColors.secondaryColor,
                rightDotColor: AppColors.primaryColor,
                size: 30,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Container(
                  color: AppColors.white,
                  child: ListView.builder(
                    reverse: true,
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth3,
                      vertical: screenHeight2,
                    ),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final message = controller.messages[index];
                      return ChatBubble(
                        message: message['text']?.toString() ?? '',
                        isUser: message['sender'] == 'user',
                        time: controller
                            .formatTime(message['timestamp']?.toString() ?? ''),
                      );
                    },
                  ),
                ),
              ),
              _buildMessageInput(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth2,
        vertical: screenHeight1,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: Get.width * 0.03),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: screenHeight * 0.25,
                        ),
                        child: TextField(
                          controller: controller.messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message',
                            contentPadding: EdgeInsets.only(left: screenWidth1),
                            border: InputBorder.none,
                          ),
                          maxLines: null,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          SizedBox(width: Get.width * 0.02),
          Obx(() => CircleAvatar(
                backgroundColor: AppColors.splashBackgroundColor,
                child: IconButton(
                  icon: controller.isSendMessageLoading.value
                      ? LoadingAnimationWidget.twistingDots(
                          leftDotColor: AppColors.white,
                          rightDotColor: AppColors.secondaryColor,
                          size: 20,
                        )
                      : const Icon(Icons.send),
                  onPressed: controller.isSendMessageLoading.value
                      ? null
                      : () => controller.sendMessage(),
                ),
              )),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String time;
  final AgentChatController controller = Get.find();

  ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Get.height * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Obx(() {
              final agent = !controller.isAgent.value
                  ? controller.chatData['agent'] ?? {}
                  : controller.chatData['user'] ?? {};
              return CircleAvatar(
                backgroundImage: NetworkImage(agent['avatar']?.toString() ??
                    'https://via.placeholder.com/150'),
                radius: 16,
              );
            }),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isUser ? 60 : 8,
                right: isUser ? 8 : 60,
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Get.width * 0.01,
                vertical: Get.height * 0.01,
              ),
              decoration: BoxDecoration(
                color:
                    isUser ? AppColors.splashBackgroundColor : AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  CustomTextWidget(
                    title: message,
                    color: AppColors.black,
                    fontSize: Get.height * 0.015,
                    maxLines: null,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                  CustomTextWidget(
                    title: time,
                    fontSize: Get.height * 0.01,
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Obx(() {
              final user = !controller.isAgent.value
                  ? controller.chatData['user']
                  : controller.chatData['agent'] ?? {};
              return CircleAvatar(
                backgroundImage: NetworkImage(user['avatar']?.toString() ??
                    'https://via.placeholder.com/150'),
                radius: 16,
              );
            })
        ],
      ),
    );
  }
}