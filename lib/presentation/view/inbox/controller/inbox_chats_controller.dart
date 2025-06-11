import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ChatMessage {
  final String text;
  final String sender; // 'user' or 'partner'
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
  });
}

class InboxChatsController extends GetxController {
  final RxList<ChatMessage> messages = <ChatMessage>[].obs;
  final TextEditingController messageController = TextEditingController();
  final RxString partnerName = 'John Doe'.obs;
  final RxString partnerStatus = 'Online'.obs;
  final RxString partnerImage = 'assets/images/person1.png'.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with dummy data
    loadChatHistory();
  }

  void loadChatHistory() {
    final now = DateTime.now();
    messages.addAll([
      ChatMessage(
        text: 'Hey there! How are you doing?',
        sender: 'partner',
        timestamp: now.subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        text: 'I\'m good, thanks for asking. How about you?',
        sender: 'user',
        timestamp: now.subtract(const Duration(minutes: 25)),
      ),
      ChatMessage(
          text:
              'I\'m doing well. Just wanted to check if you received the documents I sent?',
          sender: 'partner',
          timestamp: now.subtract(const Duration(minutes: 20))),
      ChatMessage(
        text:
            'Yes, I got them yesterday. I\'ll review them and get back to you by Friday.',
        sender: 'user',
        timestamp: now.subtract(const Duration(minutes: 15)),
      ),
      ChatMessage(
        text: 'That sounds perfect! Let me know if you need any clarification.',
        sender: 'partner',
        timestamp: now.subtract(const Duration(minutes: 10)),
      ),
      ChatMessage(
          text: 'Will do. Thanks for your help!',
          sender: 'user',
          timestamp: now.subtract(const Duration(minutes: 5))),
      ChatMessage(
        text: 'You\'re welcome! Have a great day.',
        sender: 'partner',
        timestamp: now.subtract(const Duration(minutes: 2)),
      )
    ]);
  }

  String formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (timestamp.isAfter(today)) {
      return DateFormat('h:mm a').format(timestamp);
    } else if (timestamp.isAfter(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    messages.insert(
        0,
        ChatMessage(
          text: text,
          sender: 'user',
          timestamp: DateTime.now(),
        ));

    messageController.clear();

    // Simulate partner reply after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      messages.insert(
          0,
          ChatMessage(
            text: 'Thanks for your message! I\'ll get back to you soon.',
            sender: 'partner',
            timestamp: DateTime.now(),
          ));
    });
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
