// inbox_chat_screen.dart
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/inbox/controller/inbox_chats_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InboxChatScreen extends StatelessWidget {
  final String chatPartnerName;
  final String chatPartnerImage;

  InboxChatScreen({
    super.key,
    required this.chatPartnerName,
    required this.chatPartnerImage,
  });

  final InboxChatsController inboxChatsController =
      Get.put(InboxChatsController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: buildMessageList(),
          ),
          buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Get.back(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(chatPartnerImage),
            radius: 16,
          ),
          SizedBox(width: screenWidth1),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextWidget(
                title: chatPartnerName,
                color: AppColors.black,
                fontSize: screenHeight * 0.02,
                fontWeight: FontWeight.bold,
              ),
              Obx(() => CustomTextWidget(
                    title: inboxChatsController.partnerStatus.value,
                    color: AppColors.onlineGreen,
                    fontSize: screenHeight * 0.013,
                  )),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: showMoreOptions,
        ),
      ],
    );
  }

  Widget buildMessageList() {
    return Container(
      color: AppColors.white,
      child: Obx(() {
        return ListView.builder(
          reverse: true,
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth2,
            vertical: screenHeight1,
          ),
          itemCount: inboxChatsController.messages.length,
          itemBuilder: (context, index) {
            final message = inboxChatsController.messages[index];
            return ChatBubble(
              message: message.text,
              isUser: message.sender == 'user',
              time: inboxChatsController.formatTime(message.timestamp),
              isRead: message.isRead,
            );
          },
        );
      }),
    );
  }

  Widget buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth2,
        vertical: screenHeight1,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
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
              decoration: BoxDecoration(
                color: AppColors.lightGrey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: inboxChatsController.messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        contentPadding: EdgeInsets.only(left: screenWidth2),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: AppColors.lightGrey),
                    onPressed: showAttachmentOptions,
                  ),
                ],
              ),
            ),
          ),
          kWidth(0.01),
          CircleAvatar(
            backgroundColor: AppColors.splashBackgroundColor,
            child: IconButton(
              icon: const Icon(Icons.send),
              onPressed: inboxChatsController.sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void showMoreOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.all(screenWidth2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Mute notifications'),
              onTap: () {
                Get.back();
                // Implement mute functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block user'),
              onTap: () {
                Get.back();
                // Implement block functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Delete chat'),
              onTap: () {
                Get.back();
                // Implement delete functionality
              },
            ),
          ],
        ),
      ),
    );
  }

  void showAttachmentOptions() {
    Get.bottomSheet(
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        padding: EdgeInsets.all(screenWidth2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Get.back();
                // Implement gallery functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Get.back();
                // Implement camera functionality
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Get.back();
                // Implement document functionality
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final String time;
  final bool isRead;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.time,
    this.isRead = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/person1.png'),
            ),
          Flexible(
            child: Container(
                margin: EdgeInsets.only(
                  left: isUser ? screenWidth * 0.2 : screenWidth1,
                  right: isUser ? screenWidth1 : screenWidth * 0.2,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth2,
                  vertical: screenHeight1,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppColors.splashBackgroundColor
                      : AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      title: message,
                      color: AppColors.black,
                      fontSize: screenHeight * 0.016,
                    ),
                    SizedBox(height: screenHeight05),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextWidget(
                          title: time,
                          color: AppColors.lightGrey,
                          fontSize: screenHeight * 0.012,
                        ),
                        if (isUser) SizedBox(width: screenWidth1),
                        if (isUser)
                          Icon(
                            isRead ? Icons.done_all : Icons.done,
                            size: screenHeight * 0.016,
                            color: isRead
                                ? AppColors.blueColor
                                : AppColors.lightGrey,
                          ),
                      ],
                    ),
                  ],
                )),
          ),
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/images/avatar.jpg'),
            ),
        ],
      ),
    );
  }
}
