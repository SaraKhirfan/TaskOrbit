// File: lib/screens/Product_Owner/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ChatService.dart';

class SMChatScreen extends StatefulWidget {
  const SMChatScreen({Key? key}) : super(key: key);

  @override
  State<SMChatScreen> createState() => _SMChatScreenState();
}

class _SMChatScreenState extends State<SMChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 0;

  // Chat arguments
  Map<String, dynamic> chatArgs = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatArgs = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};

    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatArgs['chatId'] != null) {
        Provider.of<ChatService>(context, listen: false)
            .markMessagesAsRead(chatArgs['chatId']);
      }
    });
  }
  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Poppins-SemiBold',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
  }

  void _sendMessage() {
    if (_messageController.text.trim().isNotEmpty && chatArgs['chatId'] != null) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.sendMessage(chatArgs['chatId'], _messageController.text.trim()).then((success) {
        if (success) {
          _messageController.clear();
          _scrollToBottom();
        } else {
          // Show error message if needed
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFFFDFDFD),
        foregroundColor: Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF004AAD),
              child: Text(
                chatArgs['avatar'] ?? 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatArgs['name'] ?? 'Chat',
                    style: TextStyle(
                      color: Color(0xFF313131),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    chatArgs['role'] ?? '',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Messages list with Firebase Stream
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: chatArgs['chatId'] != null
                  ? Consumer<ChatService>(
                builder: (context, chatService, child) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: chatService.getMessagesStream(chatArgs['chatId']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF004AAD),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, color: Colors.grey, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'Error loading messages',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 48),
                              SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start the conversation!',
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      // Auto-scroll to bottom when new messages arrive
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _scrollToBottom();
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.all(16),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final message = snapshot.data![index];
                          message['isMe'] = message['senderId'] == chatService.currentUserId;
                          message['sender'] = message['isMe'] ? 'You' : message['senderName'];

                          // For group chats, use first letter of sender's name for avatar
                          if (chatArgs['chatId']?.startsWith('group_') ?? false) {
                            if (message['isMe']) {
                              message['avatar'] = 'ME';
                            } else {
                              final senderName = message['senderName'] ?? 'Unknown';
                              message['avatar'] = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';
                            }
                          } else {
                            // For direct chats, use the original avatar logic
                            message['avatar'] = message['isMe'] ? 'ME' : (chatArgs['avatar'] ?? 'U');
                          }

                          return _buildMessageBubble(message);
                        },
                      );
                    },
                  );
                },
              )
                  : Center(
                child: Text(
                  'Chat not found',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
            ),
          ),

          // Message input
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF004AAD),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Home", 0),
            _buildNavItem(Icons.assignment, "Project", 1),
            _buildNavItem(Icons.schedule, "Schedule", 2),
            _buildNavItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isMe = message['isMe'] ?? false;
    final timestamp = message['timestamp'] as DateTime;
    final timeString = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

    // Check if this is a group chat
    final isGroupChat = chatArgs['chatId']?.startsWith('group_') ?? false;
    final senderName = message['senderName'] ?? 'Unknown User';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF004AAD),
              child: Text(
                message['avatar'] ?? 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Show sender name for group chats (only for other users' messages)
                if (isGroupChat && !isMe) ...[
                  Padding(
                    padding: EdgeInsets.only(
                      left: isMe ? 0 : 8,
                      right: isMe ? 8 : 0,
                      bottom: 4,
                    ),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF004AAD),
                      ),
                    ),
                  ),
                ],
                // Message bubble
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isMe ? Color(0xFF004AAD) : Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 20 : 4),
                      topRight: Radius.circular(isMe ? 4 : 20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : Color(0xFF313131),
                      fontSize: 14,
                    ),
                  ),
                ),
                // Timestamp
                Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    left: isMe ? 0 : 8,
                    right: isMe ? 8 : 0,
                  ),
                  child: Text(
                    timeString,
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF004AAD),
              child: Text(
                'ME',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}