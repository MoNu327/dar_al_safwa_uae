// import 'package:dar_al_safwa/core/constants/custom_size.dart';
// import 'package:dar_al_safwa/core/theme/app_colors.dart';
// import 'package:dar_al_safwa/presentation/view/inbox/controller/inbox_controller.dart';
// import 'package:dar_al_safwa/presentation/view/inbox/widgets/inbox_chats_view_screen_widget.dart';
// import 'package:dar_al_safwa/presentation/view_model/localization_controller.dart';
// import 'package:dar_al_safwa/presentation/view_model/login_controller.dart';
// import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
// import 'package:dar_al_safwa/presentation/widgets/language_text_button.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get/get_core/src/get_main.dart';

// class InboxScreen extends StatelessWidget {
//   InboxScreen({super.key});

//   final InboxController inboxController = Get.put(InboxController());

//   @override
//   Widget build(BuildContext context) {
//     final LocalizationController localizationController = Get.find();
//     final LoginController loginController = Get.put(LoginController());

//     return Scaffold(
//       appBar: AppBar(
//         automaticallyImplyLeading: false,
//         toolbarHeight: Get.height * 0.1,
//         title: Obx(() {
//           return CustomTextWidget(
//             title: localizationController.translate('title'),
//             fontSize: Get.height * 0.025,
//             color: AppColors.secondaryColor,
//             fontWeight: FontWeight.w600,
//           );
//         }),
//         actions: [
//           LanguageTextButton(localizationController: localizationController),
//           Padding(
//             padding: const EdgeInsets.all(10),
//             child: PopupMenuButton<String>(
//               onSelected: (value) {
//                 if (value == "logout") {
//                   Get.defaultDialog(
//                     title: "Logout",
//                     middleText: "Are you sure you want to log out?",
//                     textConfirm: "Yes",
//                     textCancel: "No",
//                     confirmTextColor: Colors.white,
//                     onConfirm: () {
//                       loginController.logout();
//                       Get.back();
//                     },
//                   );
//                 }
//               },
//               itemBuilder: (context) => [
//                 const PopupMenuItem(
//                   value: "logout",
//                   child: Row(
//                     children: [
//                       Icon(Icons.logout, color: Colors.red),
//                       SizedBox(width: 10),
//                       Text("Logout"),
//                     ],
//                   ),
//                 ),
//               ],
//               child: const CircleAvatar(
//                 radius: 20,
//                 backgroundImage: AssetImage('assets/images/person.png'),
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.symmetric(
//             horizontal: screenWidth2,
//           ),
//           child: Column(
//             children: [
//               Padding(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: screenWidth2,
//                   vertical: screenHeight1,
//                 ),
//                 child: TextField(
//                   decoration: InputDecoration(
//                     hintText: 'Search messages',
//                     prefixIcon: const Icon(Icons.search),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide.none,
//                     ),
//                     filled: true,
//                     fillColor: AppColors.lightGrey.withOpacity(0.1),
//                   ),
//                 ),
//               ),
//               Obx(() => ListView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     itemCount: inboxController.messages.length,
//                     itemBuilder: (context, index) {
//                       final message = inboxController.messages[index];
//                       return InkWell(
//                         onTap: () {
//                           Get.to(() => InboxChatScreen(
//                                 chatPartnerName: message.chatPartnerName,
//                                 chatPartnerImage: message.imageUrl,
//                               ));
//                         },
//                         child: Container(
//                           margin: EdgeInsets.symmetric(
//                             horizontal: screenWidth2,
//                             vertical: screenHeight05,
//                           ),
//                           decoration: BoxDecoration(
//                             color: message.isRead
//                                 ? AppColors.white
//                                 : AppColors.splashBackgroundColor,
//                             borderRadius: BorderRadius.circular(10),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.withOpacity(0.2),
//                                 spreadRadius: 1,
//                                 blurRadius: 3,
//                                 offset: const Offset(0, 1),
//                               ),
//                             ],
//                           ),
//                           child: ListTile(
//                             leading: CircleAvatar(
//                               radius: 25,
//                               backgroundImage: AssetImage(message.imageUrl),
//                             ),
//                             title: Text(
//                               message.chatPartnerName,
//                               style: TextStyle(
//                                 fontWeight: message.isRead
//                                     ? FontWeight.normal
//                                     : FontWeight.bold,
//                               ),
//                             ),
//                             subtitle: Text(
//                               message.lastMessage,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 fontWeight: message.isRead
//                                     ? FontWeight.normal
//                                     : FontWeight.bold,
//                                 color:
//                                     message.isRead ? Colors.grey : Colors.black,
//                               ),
//                             ),
//                             trailing: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               crossAxisAlignment: CrossAxisAlignment.end,
//                               children: [
//                                 Text(
//                                   message.time,
//                                   style: TextStyle(
//                                     fontSize: screenHeight * 0.012,
//                                     color: Colors.grey,
//                                     fontWeight: message.isRead
//                                         ? FontWeight.normal
//                                         : FontWeight.bold,
//                                   ),
//                                 ),
//                                 if (!message.isRead)
//                                   Container(
//                                     margin: EdgeInsets.only(top: screenHeight1),
//                                     width: screenWidth2,
//                                     height: screenHeight2,
//                                     decoration: const BoxDecoration(
//                                       color: AppColors.secondaryColor,
//                                       shape: BoxShape.circle,
//                                     ),
//                                   ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   )),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:dar_al_safwa/core/constants/custom_size.dart';
import 'package:dar_al_safwa/core/theme/app_colors.dart';
import 'package:dar_al_safwa/presentation/view/inbox/controller/inbox_controller.dart';
import 'package:dar_al_safwa/presentation/widgets/custom_text_widget.dart';
import 'package:dar_al_safwa/presentation/widgets/no_internet_widegt.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/network_controller.dart';
import '../../../widgets/notification_navigation_widget.dart';
import '../../../widgets/signup_warning_screen.dart';
import '../../search/screens/search_screen.dart';

class InboxScreen extends StatelessWidget {
  final ChatController controller = Get.put(ChatController());
  final NetworkController networkController = Get.find<NetworkController>();
  InboxScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          showExitConfirmation();
        }
      },
      child: SafeArea(
        child: Scaffold(
          appBar: AppBar(
            surfaceTintColor: AppColors.white,
            backgroundColor: AppColors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Obx(
              () => CustomTextWidget(
                title: controller.isAgent.value
                    ? 'Messages'
                    : 'Messages', // Agent Inbox, My Inbox
                color: AppColors.black,
                fontSize: appBarTitles,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: controller.refreshConversations,
                icon: const Icon(
                  Icons.refresh,
                  color: AppColors.secondaryColor,
                ),
              ),
              notificationNavigation(),
              kWidth(0.04)
            ],
          ),
          body: Obx(() {
            if (networkController.isConnected.value) {
              return _buildBody();
            } else {
              return NoInternetWidegt();
            }
          }),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (controller.auth.currentUser == null) {
      return SignupWarningScreen();
    }
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            color: AppColors.secondaryColor,
          ),
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(child: Text(controller.errorMessage.value));
      }

      if (controller.conversations.isEmpty) {
        return const Center(child: Text('No conversations yet'));
      }

      return RefreshIndicator(
        onRefresh: controller.refreshConversations,
        child: ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth1,
            vertical: screenHeight2,
          ),
          itemCount: controller.conversations.length,
          itemBuilder: (context, index) {
            final chat = controller.conversations[index];
            final otherUser = chat['otherUser'] as Map<String, dynamic>;
            final unreadCount = (chat['unreadCount']
                    as Map?)?[controller.auth.currentUser?.uid] ??
                0;

            return Column(
              children: [
                Container(
                  margin: EdgeInsets.symmetric(vertical: screenHeight * 0.001),
                  padding: EdgeInsets.symmetric(
                      // vertical: screenHeight1,
                      // horizontal: screenWidth1,
                      ),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 35,
                      backgroundImage: otherUser['photoURL'] != null &&
                              otherUser['photoURL'].isNotEmpty
                          ? NetworkImage(otherUser['photoURL'])
                          : null,
                      child: otherUser['photoURL'] == null ||
                              otherUser['photoURL'].isEmpty
                          ? Text(
                              otherUser['displayName']?.substring(0, 1) ?? '?')
                          : null,
                    ),

                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CustomTextWidget(
                          title: otherUser['displayName'] ?? 'Unknown',
                          color: AppColors.black,
                          fontSize: screenHeight * 0.018,
                          fontWeight: FontWeight.w600,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CustomTextWidget(
                              title:
                                  "🕦 ${_formatTime(chat['lastMessageAt']?.toDate())}",
                              color: AppColors.darkGrey,
                              fontSize: screenHeight * 0.014,
                            ),
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    subtitle: CustomTextWidget(
                      title: chat['lastMessage'] ?? 'No messages',
                      color: AppColors.black600,
                      fontWeight: FontWeight.w500,
                      fontSize: tagTitle,
                      maxLines: 2,
                    ),
                    // trailing:
                    // ... other properties ...
                    onTap: () {
                      final agentEmail = otherUser['email'] ??
                          ''; // Get email from otherUser data
                      final propertyName = chat['propertyId'] ??
                          'Unknown Property'; // Get property name
                      final chatId = chat['id'] ?? '';
                      debugPrint('Chat ID: $chatId');
                      controller.navigateToAgentChat(agentEmail,
                          propertyId: propertyName, chatId: chatId);
                    },
                  ),
                ),
                Divider(
                  thickness: 1,
                  color: AppColors.lightGrey,
                  indent: 20,
                  endIndent: 20,
                )
              ],
            );
          },
        ),
      );
    });
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (time.isAfter(today)) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (time.isAfter(yesterday)) {
      return 'Yesterday';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
