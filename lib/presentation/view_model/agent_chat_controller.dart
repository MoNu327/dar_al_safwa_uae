import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:majan/presentation/view/agent/customer_followup.dart';
import 'package:majan/presentation/widgets/jwttokengenration.dart';
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
      FirebaseNotificationService(navigatorKey: Get.key);

  final TextEditingController messageController = TextEditingController();
  var chatData = RxMap<String, dynamic>();
  var agentStatus = "Online".obs;
  var isAgent = false.obs;
  var isLoading = true.obs;

  String? currentChatId;
  String? agentId;
  var agentEmail = ''.obs;
  RxString propertyId = ''.obs;
  var propertyName = ''.obs;
  var unitId = ''.obs;

  var isSendMessageLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    initializeWithDummyData();
    final args = Get.arguments as Map<String, dynamic>? ?? {};

    // ✅ Get arguments including chatId
    currentChatId = args['chatId'];
    agentEmail.value = args['email'] ?? '';
    propertyId.value = args['propertyId'] ?? "";
    propertyName.value = args["propertyName"] ?? '';
    unitId.value = args["unitId"] ?? '';

    debugPrint('🚀 AgentChatController initialized with:');
    debugPrint('   Chat ID: $currentChatId');
    debugPrint('   Agent Email: ${agentEmail.value}');
    debugPrint('   Property ID: ${propertyId.value}');
    debugPrint('   Property Name: ${propertyName.value}');
    debugPrint('   Unit ID: ${unitId.value}');

    checkUserRole();
  }

 void handleCustomerFollowUp() {
  Get.to(() => CustomerFollowUpScreen());
}

  Future<void> checkUserRole() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user is an agent
      final agentDoc = await _firestore.collection('agents').doc(user.uid).get();
      if (agentDoc.exists) {
        isAgent.value = true;
        debugPrint('🎭 Agent detected');
        await initializeAgenttoUserChat();
        return;
      }

      // Check if regular user
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        isAgent.value = false;
        debugPrint('👤 Regular user detected');
        await initializeChatFromExisting();
        return;
      }

      throw Exception('User not found in agents or users collection');
    } catch (e) {
      Get.snackbar('Error', 'Failed to determine user role: ${e.toString()}');
      isAgent.value = false;
      rethrow;
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

  // ✅ New method for users - uses existing chat with unitId
  Future<void> initializeChatFromExisting() async {
    try {
      isLoading(true);
      debugPrint('🔍 Initializing chat from existing document...');

      if (currentChatId == null || currentChatId!.isEmpty) {
        debugPrint('❌ No chatId provided, falling back to legacy method');
        await initializeChat(propertyId: propertyId.value.toString());
        return;
      }

      // Get the existing chat document
      final chatDoc = await _firestore.collection('chats').doc(currentChatId).get();
      
      if (!chatDoc.exists) {
        debugPrint('❌ Chat document not found, creating new one');
        await initializeChat(propertyId: propertyId.value.toString());
        return;
      }

      final chatDataFromFirestore = chatDoc.data() as Map<String, dynamic>;
      debugPrint('📄 Retrieved chat data from Firestore:');
      debugPrint('   unitId: ${chatDataFromFirestore['unitId']}');
      debugPrint('   propertyName: ${chatDataFromFirestore['propertyName']}');
      debugPrint('   propertyId: ${chatDataFromFirestore['propertyId']}');

      // ✅ Update local unitId from Firestore if it exists
      if (chatDataFromFirestore['unitId'] != null) {
        unitId.value = chatDataFromFirestore['unitId'].toString();
        debugPrint('✅ Updated local unitId to: ${unitId.value}');
      }

      // Get current user
      final user = _auth.currentUser!;
      
      // Get agent data
      final agentQuery = await _firestore
          .collection('agents')
          .where('email', isEqualTo: agentEmail.value)
          .limit(1)
          .get();

      Map<String, dynamic> agentData = {};
      if (agentQuery.docs.isNotEmpty) {
        agentData = agentQuery.docs.first.data();
        agentId = agentQuery.docs.first.id;
      }

      // Get property data if available
      Map<String, dynamic> propertyData = {};
      final propertyIdFromChat = chatDataFromFirestore['propertyId'];
      if (propertyIdFromChat != null && propertyIdFromChat.toString().isNotEmpty) {
        final propertyDoc = await _firestore
            .collection('properties')
            .doc(propertyIdFromChat.toString())
            .get();
        if (propertyDoc.exists) {
          propertyData = propertyDoc.data() ?? {};
        }
      }

      // Update chat data for UI
      chatData.value = {
        "chat_id": currentChatId,
        "unitId": unitId.value, // ✅ Include unitId in chatData
        "property": {
          "id": propertyIdFromChat?.toString() ?? '',
          "title": chatDataFromFirestore['propertyName'] ?? 
                   propertyData['title'] ?? 
                   'Property enquiry',
          "image": _validateImageUrl(propertyData['imageUrl']),
        },
        "agent": {
          "id": agentId ?? '',
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
        "created_at": chatDataFromFirestore['createdAt'],
        "status": chatDataFromFirestore['status'] ?? "active",
      };

      // Set agent status
      agentStatus.value = (agentData['status'] ?? 'online').toString().capitalizeFirst!;

      // Start listening for messages
      _setupMessageListener();
      
      debugPrint('✅ Chat initialized successfully with unitId: ${unitId.value}');
    } catch (e) {
      debugPrint('❌ Error initializing chat from existing: $e');
      Get.snackbar('Error', 'Failed to initialize chat: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  Future<void> initializeAgenttoUserChat() async {
    try {
      isLoading(true);
      debugPrint('🎭 Starting agent-to-user chat initialization');

      final agent = _auth.currentUser;
      if (agent == null) throw Exception('Agent not authenticated');

      if (currentChatId == null || currentChatId!.isEmpty) {
        throw Exception('No chat selected to reply to');
      }

      // Get the existing chat document
      final chatDoc = await _firestore.collection('chats').doc(currentChatId).get();
      if (!chatDoc.exists) throw Exception('Chat not found');

      final chatDataFromFirestore = chatDoc.data() as Map<String, dynamic>;
      debugPrint('📄 Agent retrieved chat data:');
      debugPrint('   unitId: ${chatDataFromFirestore['unitId']}');
      debugPrint('   propertyName: ${chatDataFromFirestore['propertyName']}');

      // ✅ Update local unitId from Firestore
      if (chatDataFromFirestore['unitId'] != null) {
        unitId.value = chatDataFromFirestore['unitId'].toString();
        debugPrint('✅ Agent updated local unitId to: ${unitId.value}');
      }

      // Validate participants
      if (chatDataFromFirestore['participants'] == null ||
          chatDataFromFirestore['participants']['userId'] == null) {
        throw Exception('Invalid chat data structure');
      }

      final userId = chatDataFromFirestore['participants']['userId'];
      
      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) throw Exception('User data not found');

      final userData = userDoc.data() ?? {};

      // Get property data if available
      Map<String, dynamic> propertyData = {};
      if (chatDataFromFirestore.containsKey('propertyId') &&
          chatDataFromFirestore['propertyId'] != null) {
        final propertyId = chatDataFromFirestore['propertyId'];
        final propertyDoc = await _firestore.collection('properties').doc(propertyId).get();
        if (propertyDoc.exists) {
          propertyData = propertyDoc.data() ?? {};
        }
      }

      // Update local chat data for UI
      this.chatData.value = {
        "chat_id": currentChatId,
        "unitId": unitId.value, // ✅ Include unitId
        "property": {
          "id": chatDataFromFirestore['propertyId'] ?? '',
          "title": chatDataFromFirestore['propertyName'] ?? 
                   propertyData['title'] ?? 
                   'Property enquiry',
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
        "last_message": chatDataFromFirestore['lastMessage'] ?? '',
        "last_message_at": chatDataFromFirestore['lastMessageAt']?.toDate().toString() ?? '',
        "status": chatDataFromFirestore['status'] ?? 'active',
      };

      // Set user status
      agentStatus.value = (userData['status'] ?? 'offline').toString().capitalizeFirst!;

      // Start listening for messages
      _setupMessageListener();

      debugPrint('✅ Agent chat initialized successfully with unitId: ${unitId.value}');
    } catch (e) {
      debugPrint('❌ Failed to initialize agent chat: $e');
      Get.snackbar('Error', 'Failed to load chat: ${e.toString()}');
    } finally {
      isLoading(false);
    }
  }

  // ✅ Enhanced legacy method with unitId support
  Future<void> initializeChat({String? propertyId}) async {
    try {
      isLoading(true);
      debugPrint('🔄 Using legacy chat initialization...');

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
      agentId = agentQuery.docs.first.id;

      // Get current user data
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Find existing chat with unitId
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants.userId', isEqualTo: user.uid)
          .where('participants.agentId', isEqualTo: agentId)
          .where('propertyId', isEqualTo: propertyId ?? '')
          .where('unitId', isEqualTo: unitId.value) // ✅ Include unitId in query
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        currentChatId = chatQuery.docs.first.id;
        debugPrint('✅ Found existing chat with unitId: ${unitId.value}');
      } else {
        // Create new chat with unitId
        final newChatData = {
          'participants': {
            'userId': user.uid,
            'agentId': agentId,
            'agentEmail': agentEmail.value, // ✅ Store agent email
          },
          'propertyId': propertyId ?? '',
          'propertyName': propertyName.value, // ✅ Store property name
          'unitId': unitId.value, // ✅ Store unitId
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'active',
          'lastMessage': 'Chat started',
          'lastMessageAt': FieldValue.serverTimestamp(),
        };

        debugPrint('🆕 Creating new chat with data: $newChatData');

        final newChat = await _firestore.collection('chats').add(newChatData);
        currentChatId = newChat.id;

        // Send initial greeting message with unitId info
        await _sendSystemMessage(
            "Hello! You're now connected with ${agentData['displayName']}. "
            "How can I help you with ${unitId.value.isNotEmpty ? 'Unit ${unitId.value}' : 'this unit'} "
            "in ${propertyName.value.isNotEmpty ? propertyName.value : 'this property'}?",
            agentId: agentId);

        debugPrint('✅ Created new chat with unitId: ${unitId.value}');
      }

      // Update chat data for UI
      chatData.value = {
        "chat_id": currentChatId,
        "unitId": unitId.value, // ✅ Include unitId
        "property": {
          "id": propertyId ?? '',
          "title": propertyName.value.isNotEmpty ? propertyName.value : 'Property enquiry',
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
      agentStatus.value = (agentData['status'] ?? 'online').toString().capitalizeFirst!;

      // Start listening for messages
      _setupMessageListener();
      
      debugPrint('✅ Legacy chat initialization completed with unitId: ${unitId.value}');
    } catch (e) {
      debugPrint('❌ Legacy chat initialization failed: $e');
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

      final messageToSend = messageController.text;
      messageController.clear();
      sendPushNotification();
      
      debugPrint('✅ Message sent successfully for unitId: ${unitId.value}');
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      Get.snackbar('Error', 'Failed to send message');
    } finally {
      isSendMessageLoading(false);
    }
  }

  // ✅ Add method to get unitId for external access
  String getCurrentUnitId() {
    return unitId.value;
  }

  // ✅ Add method to get chat details including unitId
  Map<String, dynamic> getChatDetails() {
    return {
      'chatId': currentChatId,
      'unitId': unitId.value,
      'propertyId': propertyId.value,
      'propertyName': propertyName.value,
      'agentEmail': agentEmail.value,
    };
  }

  // Rest of your existing methods remain the same...
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

    final chatDoc = await _firestore.collection('chats').doc(currentChatId).get();
    final participants = chatDoc.data()?['participants'] as Map<String, dynamic>? ?? {};

    final recipientId = isAgent.value ? participants['userId'] : participants['agentId'];
    final sendRecipientId = isAgent.value ? participants['agentId'] : participants['userId'];

    if (recipientId == null) return;

    final recipientDoc = await _firestore
        .collection(isAgent.value ? 'users' : 'agents')
        .doc(recipientId)
        .get();

    final sentRecipientDoc = await _firestore
        .collection(isAgent.value ? 'agents' : 'users')
        .doc(sendRecipientId)
        .get();

    final recipientToken = recipientDoc.data()?['fcmToken'] as String?;

    if (recipientToken == null) return;

    final senderName = currentUser.displayName ??
        (isAgent.value
            ? sentRecipientDoc.data()!['displayName'] ?? 'User'
            : sentRecipientDoc.data()!['displayName'] ?? 'Agent');

    final serviceAccount = await _loadServiceAccount();

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
      final accessToken = await getAccessToken(serviceAccount);

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
              'channel_id': 'chat_channel',
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

        if (response.data?['error']?['details']?[0]?['errorCode'] == 'UNREGISTERED') {
          await _removeInvalidFcmToken(recipientId);
        }

        throw Exception('Failed to send notification: ${response.data}');
      }
    } catch (e, stack) {
      debugPrint('Notification Error: $e');
      rethrow;
    }
  }

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
    return 'https://i.postimg.cc/VLRdMxPK/profileimage.png';
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    return 'https://$url';
  }
  return url;
}