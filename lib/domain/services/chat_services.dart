import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all conversations for current user
  Stream<QuerySnapshot> getConversations() {
    if (currentUserId == null) throw Exception('User not authenticated');

    return _firestore
        .collection('chats')
        .where('participants.userId', isEqualTo: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('Error fetching conversations: $error');
      throw error;
    });
  }

  // Get all conversations for current agent
  Stream<QuerySnapshot> getAgentConversations() {
    if (currentUserId == null) throw Exception('Agent not authenticated');

    return _firestore
        .collection('chats')
        .where('participants.agentId', isEqualTo: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .handleError((error) {
      print('Error fetching agent conversations: $error');
      throw error;
    });
  }

  // Mark conversation as read
  Future<void> markAsRead(String chatId) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      print('Error marking as read: $e');
      throw e;
    }
  }

  // Get the other participant's data
  Future<Map<String, dynamic>> getOtherParticipantData(
      Map<String, dynamic> participants) async {
    try {
      final otherUserId = participants['userId'] == currentUserId
          ? participants['agentId']
          : participants['userId'];

      // Try to get from users collection first
      final userDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      if (userDoc.exists) return userDoc.data()!;

      // If not found in users, try agents collection
      final agentDoc =
          await _firestore.collection('agents').doc(otherUserId).get();
      if (agentDoc.exists) return agentDoc.data()!;

      return {
        'displayName': 'Unknown User',
        'avatarUrl': '',
        'email': '',
      };
    } catch (e) {
      print('Error getting participant data: $e');
      return {
        'displayName': 'Error loading user',
        'avatarUrl': '',
        'email': '',
      };
    }
  }

  // Get property data if available
  Future<Map<String, dynamic>> getPropertyData(String? propertyId) async {
    if (propertyId == null || propertyId.isEmpty) {
      return {};
    }

    try {
      final doc =
          await _firestore.collection('properties').doc(propertyId).get();
      return doc.data() ?? {};
    } catch (e) {
      print('Error getting property data: $e');
      return {};
    }
  }
}
