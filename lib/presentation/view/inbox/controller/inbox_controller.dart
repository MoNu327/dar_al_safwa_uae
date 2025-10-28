
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:majan/core/theme/app_colors.dart';
import 'package:majan/presentation/view/property_details/controller/property_details_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/routes/app_route.dart';

class ChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  final RxList<Map<String, dynamic>> conversations = <Map<String, dynamic>>[].obs;
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

      final agentDoc = await _firestore.collection('agents').doc(user.uid).get();
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
        final agentDoc = await _firestore.collection('agents').doc(otherUserId).get();
        debugPrint("agent doc is: ${agentDoc.data()}");
        if (agentDoc.exists) return agentDoc.data() ?? {};
      } else {
        // Then try agents collection
        final userDoc = await _firestore.collection('users').doc(otherUserId).get();
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

  // FIXED: Enhanced navigateToAgentChat method with proper validation
  // In your ChatController, update the navigateToAgentChat method:

Future<void> navigateToAgentChat(
  String agentEmail, {
  String? propertyId,
  required String chatId,
  String? unitId,
  String? propertyName,
  String? userName, // Add this parameter to accept the user name
}) async {
  try {
    // First, check if the chat exists
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      Get.snackbar("Error", "Chat not found",
          backgroundColor: AppColors.error);
      return;
    }

    // Get user data from the chat
    final chatData = chatDoc.data() as Map<String, dynamic>?;
    final participants = chatData?['participants'] as Map<String, dynamic>?;
    final userId = participants?['userId'] as String?;

    if (userId == null) {
      Get.snackbar("Error", "User ID not found in chat data",
          backgroundColor: AppColors.error);
      return;
    }

    // Verify user exists - but if not, we'll still proceed with the available data
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userExists = userDoc.exists;

    if (!userExists) {
      debugPrint('⚠️ User document not found for ID: $userId');
      // We'll still proceed but show a warning or use the provided userName
    }

    // Navigate to chat with all required data
    Get.toNamed(
      AppRoute.agent,
      arguments: {
        'email': agentEmail,
        'propertyId': propertyId,
        'chatId': chatId,
        'unitId': unitId,
        'propertyName': propertyName,
        'userId': userId,
        'userName': userName, // Pass the known user name
        'userExists': userExists, // Pass whether user document exists
      },
    );
  } catch (e) {
    debugPrint('❌ Error in navigateToAgentChat: $e');
    Get.snackbar("Error", "Failed to open chat: ${e.toString()}",
        backgroundColor: AppColors.error);
  }
}
}