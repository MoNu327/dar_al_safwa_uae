import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dar_al_safwa/presentation/widgets/jwttokengenration.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../domain/services/firebase_notification.dart';

class AgentChatController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseNotificationService notificationService =
      FirebaseNotificationService();

  final TextEditingController messageController = TextEditingController();
  var chatData = RxMap<String, dynamic>();
  var agentStatus = "Online".obs;
  var isAgent = false.obs; // Add this to track user role
  var isLoading = true.obs;

  String? currentChatId;
  String? agentId;
  var agentEmail = ''.obs;
  RxInt propertyId = 0.obs;
  var propertyName = ''.obs;
  var unitId = ''.obs;

  var isSendMessageLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Initialize with default data while Firebase loads
    initializeWithDummyData();
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    agentEmail.value = args['email'] ?? '';
    propertyId.value = int.tryParse(args['propertyId'] ?? '') ?? 0;
    propertyName.value = args["propertyName"] ?? '';
    unitId.value = args["unitId"] ?? '';

    debugPrint(
        'Agent Email: ${agentEmail.value}, Property ID: ${propertyId.value}, property Name : ${propertyName.value}, Unit Id: ${unitId.value}');
    // Determine if current user is agent
    // checkAgentRole().then((_) {
    //   debugPrint('User is ${isAgent.value ? 'Agent' : 'User'}');
    //   debugPrint(
    //       'Other User Email: ${agentEmail.value}, Property ID: ${propertyId.value}');
    //   initializeChat(propertyId: propertyId.value);
    // });
    checkUserRole();
    debugPrint(chatData.toString());
  }

  Future<void> checkUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // First check if user is an agent
      final agentDoc =
          await _firestore.collection('agents').doc(user.uid).get();
      if (agentDoc.exists) {
        isAgent.value = true;
        debugPrint(
            'Agent detected - Email: ${agentEmail.value}, Property ID: ${propertyId.value}');
        await initializeAgenttoUserChat();
        return;
      }

      // If not an agent, check if regular user
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        isAgent.value = false;
        debugPrint(
            'Regular user detected - Email: ${agentEmail.value}, Property ID: ${propertyId.value}');
        await initializeChat(propertyId: propertyId.value.toString());
        return;
      }

      // If user exists in neither collection
      throw Exception('User not found in agents or users collection');
    } catch (e) {
      Get.snackbar('Error', 'Failed to determine user role: ${e.toString()}');
      isAgent.value = false; // Default to regular user if error occurs
      rethrow; // Optional: rethrow if you want calling code to handle the error
    }
  }

  void initializeWithDummyData() {
    chatData.value = {
      "agent": {
        "name": "Loading...",
        "avatar": "https://i.postimg.cc/VLRdMxPK/profileimage.png",
      },
      "user": {
        "name": "User",
        "avatar": "https://i.postimg.cc/VLRdMxPK/profileimage.png",
      },
      "property": {
        "title": "Loading property...",
        "image": "https://i.postimg.cc/VLRdMxPK/profileimage.png",
      }
    };
  }

  Future<void> initializeAgenttoUserChat() async {
    try {
      isLoading(true);
      debugPrint('[DEBUG] Starting agent-to-user chat initialization');

      // Get current agent (the one replying)
      final agent = _auth.currentUser;
      if (agent == null) {
        debugPrint('[ERROR] Agent not authenticated');
        throw Exception('Agent not authenticated');
      }
      debugPrint('[DEBUG] Current agent UID: ${agent.uid}');

      // Get the existing chat ID from arguments
      final args = Get.arguments as Map<String, dynamic>? ?? {};
      currentChatId = args['chatId'];
      debugPrint('[DEBUG] Received chatId from arguments: $currentChatId');

      if (currentChatId == null || currentChatId!.isEmpty) {
        debugPrint('[ERROR] No valid chatId provided in arguments');
        throw Exception('No chat selected to reply to');
      }

      // Get the existing chat document
      debugPrint('[DEBUG] Fetching chat document for ID: $currentChatId');
      final chatDoc =
          await _firestore.collection('chats').doc(currentChatId).get();

      if (!chatDoc.exists) {
        debugPrint('[ERROR] Chat document not found for ID: $currentChatId');
        throw Exception('Chat not found');
      }

      final chatData = chatDoc.data() as Map<String, dynamic>;
      debugPrint('[DEBUG] Retrieved chat data: ${chatData.toString()}');

      // Validate participants structure
      if (chatData['participants'] == null ||
          chatData['participants']['userId'] == null) {
        debugPrint('[ERROR] Invalid participants structure in chat data');
        throw Exception('Invalid chat data structure');
      }

      final userId = chatData['participants']['userId'];
      debugPrint('[DEBUG] Found user ID in chat: $userId');

      // Get user data
      debugPrint('[DEBUG] Fetching user data for UID: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('[ERROR] User document not found for UID: $userId');
        throw Exception('User data not found');
      }

      final userData = userDoc.data() ?? {};
      debugPrint('[DEBUG] Retrieved user data: ${userData.toString()}');

      // Get property data if available
      Map<String, dynamic> propertyData = {};
      if (chatData.containsKey('propertyId') &&
          chatData['propertyId'] != null) {
        final propertyId = chatData['propertyId'];
        debugPrint('[DEBUG] Fetching property data for ID: $propertyId');

        final propertyDoc =
            await _firestore.collection('properties').doc(propertyId).get();
        if (propertyDoc.exists) {
          propertyData = propertyDoc.data() ?? {};
          debugPrint(
              '[DEBUG] Retrieved property data: ${propertyData.toString()}');
        } else {
          debugPrint(
              '[WARNING] Property document not found for ID: $propertyId');
        }
      }

      // Update local chat data for UI
      this.chatData.value = {
        "chat_id": currentChatId,
        "property": {
          "id": chatData['propertyId'] ?? '',
          "title": propertyData['title'] ?? 'Property enquiry',
          "image": _validateImageUrl(propertyData['imageUrl']),
        },
        "user": {
          "id": userId,
          "name": userData['displayName'] ?? 'User',
          "avatar": _validateImageUrl(userData['photoURL']),
          "status": userData['status'] ?? 'offline',
          "email": userData['email'] ?? '',
        },
        "agent": {
          "id": agent.uid,
          "name": agent.displayName ?? 'Agent',
          "avatar": _validateImageUrl(agent.photoURL),
          "email": agent.email ?? '',
        },
        "last_message": chatData['lastMessage'] ?? '',
        "last_message_at": chatData['lastMessageAt']?.toDate().toString() ?? '',
        "status": chatData['status'] ?? 'active',
      };
      debugPrint('[DEBUG] Updated local chatData: ${this.chatData}');

      // Set user status
      agentStatus.value =
          (userData['status'] ?? 'offline').toString().capitalizeFirst!;
      debugPrint('[DEBUG] Set user status to: ${agentStatus.value}');

      // Start listening for new messages
      debugPrint('[DEBUG] Setting up message listener');
      _setupMessageListener();

      debugPrint('[DEBUG] Agent-to-user chat initialized successfully');
    } catch (e) {
      debugPrint('[ERROR] Failed to initialize agent-to-user chat: $e');
      Get.snackbar('Error', 'Failed to load chat: ${e.toString()}');
    } finally {
      isLoading(false);
      debugPrint('[DEBUG] Loading complete, isLoading set to false');
    }
  }

  Future<void> initializeChat({String? propertyId}) async {
    try {
      isLoading(true);

      // Get agent data
      final agentQuery = await _firestore
          .collection('agents')
          .where('email', isEqualTo: agentEmail.value)
          .limit(1)
          .get();

      if (agentQuery.docs.isEmpty) {
        throw Exception('Agent not found');
      }

      final agentData = agentQuery.docs.first.data();
      agentId = agentData['uid'];

      // Get current user data
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get property data if provided
      // Map<String, dynamic> propertyData = {};
      // if (propertyId != null) {
      //   final propertyDoc =
      //       await _firestore.collection('properties').doc(propertyId).get();
      //   if (propertyDoc.exists) {
      //     propertyData = propertyDoc.data() ?? {};
      //   }
      // }

      // Find or create chat
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants.userId', isEqualTo: user.uid)
          .where('participants.agentId', isEqualTo: agentId)
          .where('propertyId', isEqualTo: propertyId ?? '')
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        currentChatId = chatQuery.docs.first.id;
      } else {
        final newChat = await _firestore.collection('chats').add({
          'participants': {
            'userId': user.uid,
            'agentId': agentId,
          },
          'propertyId': propertyId ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'lastMessage': 'Chat started',
          'lastMessageAt': FieldValue.serverTimestamp(),
        });
        currentChatId = newChat.id;

        // Send initial greeting message
        await _sendSystemMessage(
            "Hello! You're now connected with ${agentData['displayName']}. "
            "How can I help you with  ${unitId ?? '1bhk'} , ${propertyName ?? 'this '} property?",
            agentId: agentId);
      }

      // Update chat data for UI with validated image URLs
      chatData.value = {
        "chat_id": currentChatId,
        "property": {
          "id": propertyId ?? '',
          // "title": propertyData['title'] ?? 'Property enquiry',
          // "price": propertyData['price']?.toString() ?? '',
          // "location": propertyData['location'] ?? '',
          // "image": _validateImageUrl(propertyData['imageUrl']),
        },
        "agent": {
          "id": agentId,
          "name": agentData['displayName'] ?? 'Agent',
          "avatar": _validateImageUrl(agentData['photoURL']),
          "status": agentData['status'] ?? 'online',
          "email": agentEmail.value,
        },
        "user": {
          "id": user.uid,
          "name": user.displayName ?? 'User',
          "avatar": _validateImageUrl(user.photoURL),
          "email": user.email ?? '',
        },
        "created_at": FieldValue.serverTimestamp(),
        "status": "active",
      };

      // Set agent status
      agentStatus.value =
          (agentData['status'] ?? 'online').toString().capitalizeFirst!;

      // Start listening for messages
      _setupMessageListener();
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize chat: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> _sendSystemMessage(String text, {String? agentId}) async {
    if (currentChatId == null) return;

    await _firestore.collection('chats/$currentChatId/messages').add({
      'senderId': agentId,
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'system',
    });

    await _firestore.collection('chats').doc(currentChatId).update({
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
    });
  }

  void _setupMessageListener() {
    if (currentChatId == null) return;

    _firestore
        .collection('chats/$currentChatId/messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'sender': data['senderId'] == _auth.currentUser?.uid
              ? 'user'
              : data['senderId'] == 'system'
                  ? 'system'
                  : 'agent',
          'text': data['content'],
          'timestamp': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate().toIso8601String()
              : DateTime.now().toIso8601String(),
          'read': data['read'],
        };
      }).toList();

      // Update the messages in chatData
      chatData['messages'] = messages;
      chatData.refresh();
    });
  }

  List<Map<String, dynamic>> get messages {
    if (!chatData.containsKey('messages')) return [];
    final messages = chatData['messages'] as List<dynamic>;
    return messages.map((e) => e as Map<String, dynamic>).toList();
  }

  String formatTime(String isoTime) {
    try {
      return DateFormat('h:mm a').format(DateTime.parse(isoTime));
    } catch (e) {
      return DateFormat('h:mm a').format(DateTime.now());
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.isEmpty || currentChatId == null) return;

    try {
      isSendMessageLoading(true);
      // Add message to Firestore
      await _firestore.collection('chats/$currentChatId/messages').add({
        'senderId': _auth.currentUser!.uid,
        'content': messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'text',
      });

      // Update chat last message
      await _firestore.collection('chats').doc(currentChatId).update({
        'lastMessage': messageController.text,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });

      messageController.clear();
      sendPushNotification();
      // isSendMessageLoading(false);
    } catch (e) {
      Get.snackbar('Error', 'Failed to send message');
    } finally {
      isSendMessageLoading(false);
    }
  }

  Future<void> markMessagesAsRead() async {
    if (currentChatId == null) return;

    try {
      final unreadMessages = await _firestore
          .collection('chats/$currentChatId/messages')
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: _auth.currentUser?.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> sendPushNotification() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Determine recipient ID (opposite of current user)
    final chatDoc =
        await _firestore.collection('chats').doc(currentChatId).get();
    final participants =
        chatDoc.data()?['participants'] as Map<String, dynamic>? ?? {};

//  final recipientId =
//        isAgent.value ? participants['agentId'] : participants['userId'];
    final recipientId =
        isAgent.value ? participants['userId'] : participants['agentId'];
    final sendRecipientId =
        isAgent.value ? participants['agentId'] : participants['userId'];

    if (recipientId == null) return;

    // Get recipient's FCM token
    final recipientDoc = await _firestore
        .collection(isAgent.value ? 'users' : 'agents')
        .doc(recipientId)
        .get();

    debugPrint('Recipient document: ${[
      recipientId,
      isAgent.value,
      recipientDoc.data()
    ]}');

    final sentRecipientDoc = await _firestore
        .collection(isAgent.value ? 'agents' : 'users')
        .doc(sendRecipientId)
        .get();
    debugPrint('Sent recipient document(current user/sender): ${[
      sentRecipientDoc.data(),
      sendRecipientId,
      isAgent.value,
    ]}');
    final recipientToken = recipientDoc.data()?['fcmToken'] as String?;
    debugPrint("Recipient fcmToken: $recipientToken");

    if (recipientToken == null) return;

    // Get sender name
    final senderName = currentUser.displayName ??
        (isAgent.value
            ? sentRecipientDoc.data()!['displayName'] ?? 'User'
            : sentRecipientDoc.data()!['displayName'] ?? 'Agent');
    // 1. Load service account credentials
    final serviceAccount = await _loadServiceAccount();

    // // // 2. Generate proper JWT token (server-side is better)
    // final accessToken = await getAccessToken(serviceAccount);
    // debugPrint("jwt access token $accessToken");

    // Send notification via Cloud Functions (recommended) or directly
    await _sendNotificationThroughFunctions(
      serviceAccount: serviceAccount,
      token: recipientToken,
      senderName: senderName,
      message: messageController.text,
      chatId: currentChatId!,
      recipientId: recipientId,
    );
  }

  Future<void> _sendNotificationThroughFunctions({
    required Map<String, dynamic> serviceAccount,
    required String token,
    required String senderName,
    required String message,
    required String chatId,
    required String recipientId,
  }) async {
    final dio = Dio();

    try {
      debugPrint('Sending notification with the following details:');
      debugPrint('Token: $token');
      debugPrint('Sender Name: $senderName');
      debugPrint('Message: $message');
      debugPrint('Chat ID: $chatId');
      debugPrint('Sender ID: ${_auth.currentUser?.uid}');

      final accessToken = await getAccessToken(serviceAccount);
      debugPrint('Access token obtained successfully');

      final fcmMessage = {
        'message': {
          'token': token,
          'notification': {
            'title': 'Message from $senderName',
            'body': message,
          },
          'data': {
            'chatId': chatId,
            'senderId': _auth.currentUser?.uid ?? '',
            'type': 'chat_message',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'android': {
            'priority': 'high',
            'notification': {
              'channel_id': 'chat_channel', // Match your local channel
              'visibility': 'public',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
            'headers': {
              'apns-priority': '10',
            },
          },
          // 'android': {'priority': 'high'},
          // 'apns': {
          //   'headers': {'apns-priority': '10'}
          // },
        },
      };

      final response = await dio.post(
        'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          validateStatus: (status) => status! < 500,
        ),
        data: fcmMessage,
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully');
      } else {
        debugPrint('FCM Error: ${response.statusCode} - ${response.data}');

        // Handle UNREGISTERED token
        if (response.data?['error']?['details']?[0]?['errorCode'] ==
            'UNREGISTERED') {
          debugPrint('Detected UNREGISTERED token, removing from Firestore...');
          await _removeInvalidFcmToken(recipientId);
        }

        throw Exception('Failed to send notification: ${response.data}');
      }
    } catch (e, stack) {
      debugPrint('Notification Error: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  /// Helper method to remove invalid FCM token from Firestore
  Future<void> _removeInvalidFcmToken(String userId) async {
    try {
      await _firestore
          .collection(isAgent.value ? 'users' : 'agents')
          .doc(userId)
          .update({
        'fcmToken': FieldValue.delete(),
      });
      debugPrint('Removed invalid FCM token for user: $userId');
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }
  // Future<void> _sendNotificationThroughFunctions({
  //   required Map<String, dynamic> serviceAccount,
  //   required String token,
  //   required String senderName,
  //   required String message,
  //   required String chatId,
  // }) async {
  //   final dio = Dio();

  //   try {
  //     debugPrint('Sending notification with the following details:');
  //     debugPrint('Token: $token');
  //     debugPrint('Sender Name: $senderName');
  //     debugPrint('Message: $message');
  //     debugPrint('Chat ID: $chatId');
  //     debugPrint('Sender ID: ${_auth.currentUser?.uid}');
  //     // 1. Validate service account

  //     // 2. Get fresh access token
  //     final accessToken = await getAccessToken(serviceAccount);
  //     debugPrint('Access token obtained successfully');
  //     debugPrint('New message from $senderName');

  //     // 3. Prepare FCM message
  //     final fcmMessage = {
  //       'message': {
  //         'token': token,
  //         'notification': {
  //           'title': 'New message from $senderName',
  //           'body': message,
  //         },
  //         'data': {
  //           'chatId': chatId,
  //           'senderId': _auth.currentUser?.uid ?? '',
  //           'type': 'chat_message',
  //         },
  //         'android': {'priority': 'high'},
  //         'apns': {
  //           'headers': {'apns-priority': '10'}
  //         },
  //       },
  //     };

  //     // 4. Send with proper headers
  //     final response = await dio.post(
  //       'https://fcm.googleapis.com/v1/projects/${serviceAccount['project_id']}/messages:send',
  //       options: Options(
  //         headers: {
  //           'Content-Type': 'application/json',
  //           'Authorization': 'Bearer $accessToken',
  //         },
  //         validateStatus: (status) =>
  //             status! < 500, // Don't throw for 4xx errors
  //       ),
  //       data: fcmMessage,
  //     );

  //     // 5. Handle response
  //     if (response.statusCode == 200) {
  //       debugPrint('Notification sent successfully');
  //     } else {
  //       debugPrint('FCM Error: ${response.statusCode} - ${response.data}');
  //       throw Exception('Failed to send notification: ${response.data}');
  //     }
  //   } catch (e, stack) {
  //     debugPrint('Notification Error: $e');
  //     debugPrint('Stack trace: $stack');
  //     rethrow;
  //   }
  // }

  Future<Map<String, dynamic>> _loadServiceAccount() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/lang/service-message.json',
      );
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading service account: $e');
      throw Exception('Failed to load service account credentials');
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}

// Add this helper method to validate image URLs
String _validateImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return 'https://i.postimg.cc/VLRdMxPK/profileimage.png'; // Default placeholder
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return 'https://$url'; // Add https if missing
  }
  return url;
}
