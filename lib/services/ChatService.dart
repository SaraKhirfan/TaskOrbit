// File: lib/services/ChatService.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get chatList => _chatList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or get existing chat between users
  Future<String?> createOrGetDirectChat(String otherUserId, String otherUserName) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if chat already exists
      final existingChat = await _firestore
          .collection('chats')
          .where('chatType', isEqualTo: 'direct')
          .where('participants', arrayContains: currentUserId)
          .get();

      for (var doc in existingChat.docs) {
        List<dynamic> participants = doc.data()['participants'];
        if (participants.contains(otherUserId)) {
          return doc.id;
        }
      }

      // Create new chat if doesn't exist
      final chatData = {
        'participants': [currentUserId, otherUserId],
        'chatType': 'direct',
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final chatRef = await _firestore.collection('chats').add(chatData);
      return chatRef.id;
    } catch (e) {
      print('Error creating/getting chat: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Create project group chat
  Future<String?> createProjectChat(String projectId, String projectName, List<String> memberIds) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final chatData = {
        'participants': memberIds,
        'chatType': 'project',
        'projectId': projectId,
        'chatName': '$projectName Team Chat',
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdBy': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      final chatRef = await _firestore.collection('chats').add(chatData);
      return chatRef.id;
    } catch (e) {
      print('Error creating project chat: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update your sendMessage method in ChatService
  Future<bool> sendMessage(String chatId, String messageText) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return false;

      // Get current user's name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userData = userDoc.data();
      final senderName = userData?['name'] ?? 'Unknown User';

      // Get chat participants to update unread counts
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      final chatData = chatDoc.data();
      final participants = List<String>.from(chatData?['participants'] ?? []);

      // Create unread count map (exclude sender)
      Map<String, int> unreadCounts = {};
      for (String participantId in participants) {
        if (participantId != currentUser.uid) {
          unreadCounts[participantId] = 1; // New message for each participant except sender
        }
      }

      // Add the message
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'message': messageText,
        'senderId': currentUser.uid,
        'senderName': senderName,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Update chat document with last message and unread counts
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': unreadCounts,
      });

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  // Get messages stream for a chat
  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        // Convert timestamp to DateTime if needed
        if (data['timestamp'] != null) {
          data['timestamp'] = (data['timestamp'] as Timestamp).toDate();
        }

        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getChatListStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final currentUserId = currentUser.uid;

        String chatName = 'Unknown';
        String role = '';
        String avatar = 'U';

        if (doc.id.startsWith('direct_')) {
          // This is a direct chat - get the other participant's info
          if (data['participantData'] != null) {
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere(
                  (id) => id != currentUserId,
              orElse: () => '',
            );

            if (otherUserId.isNotEmpty && data['participantData'][otherUserId] != null) {
              chatName = data['participantData'][otherUserId]['name'] ?? 'Unknown';
              avatar = chatName.isNotEmpty ? chatName[0].toUpperCase() : 'U';
            }
          }
        } else if (doc.id.startsWith('group_')) {
          // This is a group chat
          chatName = data['name'] ?? 'Group Chat';
          role = 'Group Chat';
          avatar = 'G'; // Use 'G' for group chats
        } else {
          // Fallback for other chat types
          chatName = data['name'] ?? 'Chat';
          avatar = chatName[0].toUpperCase();
        }

        return {
          'id': doc.id,
          'name': chatName,
          'role': role,
          'avatar': avatar,
          'lastMessage': data['lastMessage'] ?? '',
          'lastMessageTime': data['lastMessageTime']?.toDate() ?? DateTime.now(),
          'unreadCount': data['unreadCount'] ?? 0,
        };
      }).toList();
    });
  }
  // Get unread message count for a chat
  Future<int> _getUnreadCount(String chatId) async {
    try {
      if (currentUserId == null) return 0;

      final messagesSnapshot = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isNotEqualTo: currentUserId)
          .get();

      int unreadCount = 0;
      for (var doc in messagesSnapshot.docs) {
        List<dynamic> readBy = doc.data()['readBy'] ?? [];
        if (!readBy.contains(currentUserId)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  // Get user info by ID
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData['avatar'] = _getInitials(userData['name'] ?? 'U');
        return userData;
      }
      return null;
    } catch (e) {
      print('Error getting user info: $e');
      return null;
    }
  }

  // Get project members for group chat creation
  Future<List<Map<String, dynamic>>> getProjectMembers(String projectId) async {
    try {
      final projectDoc = await _firestore.collection('projects').doc(projectId).get();
      if (!projectDoc.exists) return [];

      List<dynamic> memberIds = projectDoc.data()?['members'] ?? [];
      List<Map<String, dynamic>> members = [];

      for (String memberId in memberIds) {
        final memberInfo = await getUserInfo(memberId);
        if (memberInfo != null) {
          memberInfo['userId'] = memberId;
          members.add(memberInfo);
        }
      }

      return members;
    } catch (e) {
      print('Error getting project members: $e');
      return [];
    }
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    List<String> nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
  }
// Add this method to your ChatService class
  Future<void> createGroupChat({
    required String groupName,
    required List<String> participants,
    required Map<String, dynamic> participantData,
    required String projectId,
  }) async {
    try {
      final chatId = 'group_${DateTime.now().millisecondsSinceEpoch}';

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .set({
        'name': groupName,
        'participants': participants,
        'participantData': participantData,
        'type': 'group',
        'projectId': projectId,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      });
    } catch (e) {
      print('Error creating group chat: $e');
      rethrow;
    }
  }

  Future<String> getOrCreateDirectChat(String userId1, String userId2) async {
    try {
      // Create a consistent chat ID by sorting user IDs
      final participants = [userId1, userId2]..sort();
      final chatId = 'direct_${participants[0]}_${participants[1]}';

      // Check if chat already exists
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      if (!chatDoc.exists) {
        // Get user data for both participants
        final user1Doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId1)
            .get();

        final user2Doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId2)
            .get();

        final user1Data = user1Doc.data();
        final user2Data = user2Doc.data();

        // Create new direct chat with participant info
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .set({
          'participants': participants,
          'participantData': {
            userId1: {
              'name': user1Data?['name'] ?? 'Unknown User',
              'email': user1Data?['email'] ?? '',
            },
            userId2: {
              'name': user2Data?['name'] ?? 'Unknown User',
              'email': user2Data?['email'] ?? '',
            },
          },
          'type': 'direct',
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return chatId;
    } catch (e) {
      print('Error creating direct chat: $e');
      rethrow;
    }
  }
  // Add this method to your ChatService class
  Future<void> deleteChat(String chatId) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Delete all messages in the chat
      final messagesQuery = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .get();

      for (final messageDoc in messagesQuery.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the chat document
      batch.delete(FirebaseFirestore.instance.collection('chats').doc(chatId));

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }

  Stream<int> getUnreadMessageCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var chatDoc in snapshot.docs) {
        final chatData = chatDoc.data();
        final unreadCount = chatData['unreadCount'] ?? 0;

        // If unreadCount is a map (per user), get count for current user
        if (unreadCount is Map) {
          totalUnread += (unreadCount[currentUser.uid] ?? 0) as int;
        } else if (unreadCount is int) {
          totalUnread += unreadCount;
        }
      }
      return totalUnread;
    });
  }
  // Add this to your ChatService
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Reset unread count for current user
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'unreadCount.${currentUser.uid}': 0,
      });
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }
}