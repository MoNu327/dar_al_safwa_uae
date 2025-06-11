// import 'package:get/get.dart';

// class InboxMessage {
//   final String chatPartnerName;
//   final String lastMessage;
//   final String time;
//   final String imageUrl;
//   final bool isRead;

//   InboxMessage({
//     required this.chatPartnerName,
//     required this.lastMessage,
//     required this.time,
//     required this.imageUrl,
//     this.isRead = false,
//   });
// }

// class InboxController extends GetxController {
//   final RxList<InboxMessage> messages = <InboxMessage>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     messages.addAll([
//       InboxMessage(
//         chatPartnerName: 'John Doe',
//         lastMessage: 'Hey, how are you doing?',
//         time: '10:30 AM',
//         imageUrl: 'assets/images/person1.png',
//       ),
//       InboxMessage(
//         chatPartnerName: 'Sarah Smith',
//         lastMessage: 'Meeting at 2 PM tomorrow',
//         time: 'Yesterday',
//         imageUrl: 'assets/images/person1.png',
//         isRead: true,
//       ),
//       InboxMessage(
//         chatPartnerName: 'Tech Support',
//         lastMessage: 'Your issue has been resolved',
//         time: 'Monday',
//         imageUrl: 'assets/images/avatar.jpg',
//         isRead: true,
//       ),
//       InboxMessage(
//         chatPartnerName: 'Marketing Team',
//         lastMessage: 'New campaign launch next week',
//         time: '05/20/2023',
//         imageUrl: 'assets/images/avatar.jpg',
//       ),
//       InboxMessage(
//         chatPartnerName: 'Alex Johnson',
//         lastMessage: 'Please review the documents',
//         time: '05/18/2023',
//         imageUrl: 'assets/images/avatar.jpg',
//         isRead: true,
//       ),
//     ]);
//   }
// }
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_route.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final RxList<Map<String, dynamic>> conversations =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isAgent = false.obs;
  final RxString errorMessage = ''.obs;
  StreamSubscription? _conversationsSubscription;

  @override
  void onInit() {
    super.onInit();
    _checkUserType();
  }

  @override
  void onClose() {
    _conversationsSubscription?.cancel();
    super.onClose();
  }

  Future<void> _checkUserType() async {
    try {
      final user = auth.currentUser;
      if (user == null) return;

      final agentDoc =
          await _firestore.collection('agents').doc(user.uid).get();
      isAgent.value = agentDoc.exists;
      _fetchConversations();
    } catch (e) {
      errorMessage.value = 'Error checking user type: ${e.toString()}';
      isLoading.value = false;
    }
  }

  Future<void> _fetchConversations() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final user = auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Cancel previous subscription if exists
      _conversationsSubscription?.cancel();
      debugPrint("agent value is: ${isAgent.value}");
      final query = isAgent.value
          ? _firestore
              .collection('chats')
              .where('participants.agentId', isEqualTo: user.uid)
          : _firestore
              .collection('chats')
              .where('participants.userId', isEqualTo: user.uid);

      _conversationsSubscription = query
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .listen((snapshot) async {
        final updatedConversations = <Map<String, dynamic>>[];

        for (final doc in snapshot.docs) {
          final data = doc.data();
          final otherUser = await _getOtherUserData(data['participants']);

          debugPrint("other user is: $otherUser");

          updatedConversations.add({
            'id': doc.id,
            ...data,
            'otherUser': otherUser,
          });
        }

        conversations.value = updatedConversations;
        debugPrint("conversations user is: ${conversations.value}");
        isLoading.value = false;
      }, onError: (error) {
        errorMessage.value = 'Error loading conversations: $error';
        isLoading.value = false;
      });
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Error setting up listener: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> _getOtherUserData(
      Map<String, dynamic> participants) async {
    try {
      final currentUserId = auth.currentUser?.uid;
      if (currentUserId == null) return {};

      final otherUserId = participants['userId'] == currentUserId
          ? participants['agentId']
          : participants['userId'];

      // Try users collection first
      if (participants['userId'] == currentUserId) {
        final agentDoc =
            await _firestore.collection('agents').doc(otherUserId).get();
        debugPrint("agent doc is: ${agentDoc.data()}");
        if (agentDoc.exists) return agentDoc.data() ?? {};
      } else {
        // Then try agents collection
        final userDoc =
            await _firestore.collection('users').doc(otherUserId).get();
        debugPrint("user doc is: ${userDoc.data()}");
        if (userDoc.exists) return userDoc.data() ?? {};
      }

      return {
        'displayName': 'Unknown',
        'avatarUrl': '',
        'email': '',
      };
    } catch (e) {
      return {
        'displayName': 'Error loading user',
        'avatarUrl': '',
        'email': '',
      };
    }
  }

  Future<void> refreshConversations() async {
    await _fetchConversations();
  }

  // In your PropertyDetailsController
  void navigateToAgentChat(String agentEmail,
      {String? propertyId, String? chatId}) {
    Get.toNamed(
      AppRoute.agent,
      arguments: {
        'email': agentEmail,
        'propertyId': propertyId ?? "Riverview Retreat",
        'chatId': chatId,
      }, // Pass the agent's email as argument
    );
  }
}
