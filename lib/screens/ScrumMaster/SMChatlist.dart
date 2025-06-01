// File: lib/screens/Product_Owner/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/product_owner_drawer.dart';
import '../../services/ChatService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_drawer.dart';
import '../Product_Owner/my_projects_screen.dart';

class SMChatListScreen extends StatefulWidget {
  const SMChatListScreen({Key? key}) : super(key: key);

  @override
  State<SMChatListScreen> createState() => _SMChatListScreenState();
}

class _SMChatListScreenState extends State<SMChatListScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
  }
// Method to show create group chat dialog
  Future<void> _showCreateGroupChatDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => CreateGroupChatDialog(),
    );

    if (result != null) {
      await _createGroupChat(
        result['groupName'],
        result['selectedMembers'],
        result['projectId'],
      );
    }
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

// Method to create group chat
  Future<void> _createGroupChat(
      String groupName,
      List<Map<String, dynamic>> selectedMembers,
      String projectId,
      ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create participant list (include current user)
      List<String> participants = [currentUser.uid];
      participants.addAll(selectedMembers.map((member) => member['id'] as String));

      // Create participant data map
      Map<String, dynamic> participantData = {};

      // Add current user data
      final currentUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (currentUserDoc.exists) {
        participantData[currentUser.uid] = {
          'name': currentUserDoc.data()?['name'] ?? 'Current User',
          'email': currentUserDoc.data()?['email'] ?? '',
        };
      }

      // Add selected members data
      for (var member in selectedMembers) {
        participantData[member['id']] = {
          'name': member['name'],
          'email': member['email'] ?? '',
        };
      }

      // Create group chat document
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.createGroupChat(
        groupName: groupName,
        participants: participants,
        participantData: participantData,
        projectId: projectId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group chat "$groupName" created successfully'),
          backgroundColor: Color(0xFF004AAD),
        ),
      );
    } catch (e) {
      print('Error creating group chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating group chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
  // Add this method to delete a chat
  Future<void> _deleteChat(Map<String, dynamic> chat) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.deleteChat(chat['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chat with ${chat['name']} deleted'),
          backgroundColor: Color(0xFF004AAD),
        ),
      );
    } catch (e) {
      print('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting chat'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Add this method to show delete confirmation
  Future<void> _showDeleteConfirmationDialog(Map<String, dynamic> chat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text('Are you sure you want to delete the chat with ${chat['name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteChat(chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F3),
      key: _scaffoldKey,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Settings"),
      drawer: SMDrawer(selectedItem: 'Settings'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateGroupChatDialog,
        backgroundColor: Color(0xFF004AAD),
        child: Icon(Icons.group_add, color: Colors.white),
        tooltip: 'Create Group Chat',
      ),
      body: Column(
        children: [
          // Back button and title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Chats',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
              ],
            ),
          ),

          // Chat list with Firebase Stream
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: chatService.getChatListStream(),
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
                              'Error loading chats',
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
                              'No chats available',
                              style: TextStyle(color: Colors.grey, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final chat = snapshot.data![index];
                        return _buildChatListItem(chat);
                      },
                    );
                  },
                );
              },
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

  Widget _buildChatListItem(Map<String, dynamic> chat) {
    // Handle timestamp conversion
    DateTime timestamp;
    if (chat['lastMessageTime'] is DateTime) {
      timestamp = chat['lastMessageTime'];
    } else {
      timestamp = DateTime.now(); // Fallback
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/POChat',
              arguments: {
                'chatId': chat['id'],
                'name': chat['name'] ?? 'Unknown',
                'role': chat['role'] ?? '',
                'avatar': chat['avatar'] ?? 'U',
              },
            );
          },
          // Add long press to delete
          onLongPress: () => _showDeleteConfirmationDialog(chat),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar (removed online indicator as requested)
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF004AAD),
                  child: Text(
                    chat['avatar'] ?? 'U',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                SizedBox(width: 16),

                // Chat info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                _formatTimestamp(timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: (chat['unreadCount'] ?? 0) > 0
                                      ? Color(0xFF004AAD)
                                      : Color(0xFF999999),
                                  fontWeight: (chat['unreadCount'] ?? 0) > 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              SizedBox(width: 8),
                              // Delete button (visible on hover/interaction)
                              PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Color(0xFF999999),
                                  size: 18,
                                ),
                                onSelected: (value) {
                                  if (value == 'delete') {
                                    _showDeleteConfirmationDialog(chat);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Delete Chat',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        chat['role'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              chat['lastMessage'] ?? 'No messages yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: (chat['unreadCount'] ?? 0) > 0
                                    ? Color(0xFF313131)
                                    : Color(0xFF666666),
                                fontWeight: (chat['unreadCount'] ?? 0) > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((chat['unreadCount'] ?? 0) > 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFF004AAD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat['unreadCount'].toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CreateGroupChatDialog extends StatefulWidget {
  @override
  _CreateGroupChatDialogState createState() => _CreateGroupChatDialogState();
}

class _CreateGroupChatDialogState extends State<CreateGroupChatDialog> {
  final TextEditingController _groupNameController = TextEditingController();
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _projectMembers = [];
  List<Map<String, dynamic>> _selectedMembers = [];
  String? _selectedProjectId;
  bool _isLoadingProjects = true;
  bool _isLoadingMembers = false;

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
  }

  Future<void> _loadUserProjects() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Get projects where current user is product owner
      final projectsQuery = await FirebaseFirestore.instance
          .collection('projects')
          .where('roles.productOwner', isEqualTo: currentUser.uid)
          .get();

      List<Map<String, dynamic>> projects = [];
      for (var doc in projectsQuery.docs) {
        projects.add({
          'id': doc.id,
          ...doc.data(),
        });
      }

      setState(() {
        _projects = projects;
        _isLoadingProjects = false;
      });
    } catch (e) {
      print('Error loading projects: $e');
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  Future<void> _loadProjectMembers(String projectId) async {
    setState(() {
      _isLoadingMembers = true;
      _projectMembers = [];
      _selectedMembers = [];
    });

    try {
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) return;

      final projectData = projectDoc.data()!;
      List<String> memberIds = [];

      // Get all member IDs from the project
      if (projectData.containsKey('roles') && projectData['roles'] != null) {
        final roles = projectData['roles'];

        if (roles['scrumMasters'] != null) {
          memberIds.addAll(List<String>.from(roles['scrumMasters']));
        }
        if (roles['teamMembers'] != null) {
          memberIds.addAll(List<String>.from(roles['teamMembers']));
        }
        if (roles['clients'] != null) {
          memberIds.addAll(List<String>.from(roles['clients']));
        }
      }

      // Remove current user from the list
      final currentUser = FirebaseAuth.instance.currentUser;
      memberIds.removeWhere((id) => id == currentUser?.uid);

      // Fetch user data for each member
      List<Map<String, dynamic>> members = [];
      for (String memberId in memberIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();

        if (userDoc.exists) {
          members.add({
            'id': userDoc.id,
            ...userDoc.data()!,
          });
        }
      }

      setState(() {
        _projectMembers = members;
        _isLoadingMembers = false;
      });
    } catch (e) {
      print('Error loading project members: $e');
      setState(() {
        _isLoadingMembers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Group Chat'),
      contentPadding: EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9, // Responsive width
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Max height
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name input
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(height: 16),

              // Project selection
              Text(
                'Select Project:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF313131),
                ),
              ),
              SizedBox(height: 8),

              if (_isLoadingProjects)
                Center(child: CircularProgressIndicator())
              else if (_projects.isEmpty)
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'No projects found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true, // This fixes the overflow
                      hint: Text('Choose a project'),
                      value: _selectedProjectId,
                      items: _projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project['id'],
                          child: Text(
                            project['name'] ?? 'Unnamed Project',
                            overflow: TextOverflow.ellipsis, // Handle long names
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedProjectId = value;
                          });
                          _loadProjectMembers(value);
                        }
                      },
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Members selection
              if (_selectedProjectId != null) ...[
                Text(
                  'Select Members:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF313131),
                  ),
                ),
                SizedBox(height: 8),

                if (_isLoadingMembers)
                  Center(child: CircularProgressIndicator())
                else if (_projectMembers.isEmpty)
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No members found in this project',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _projectMembers.length,
                      itemBuilder: (context, index) {
                        final member = _projectMembers[index];
                        final isSelected = _selectedMembers
                            .any((selected) => selected['id'] == member['id']);

                        return Container(
                          decoration: BoxDecoration(
                            border: index > 0
                                ? Border(top: BorderSide(color: Colors.grey.shade200))
                                : null,
                          ),
                          child: CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              member['name'] ?? 'Unknown',
                              style: TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              member['email'] ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedMembers.add(member);
                                } else {
                                  _selectedMembers.removeWhere(
                                        (selected) => selected['id'] == member['id'],
                                  );
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                if (_selectedMembers.isNotEmpty) ...[
                  SizedBox(height: 8),
                  Text(
                    '${_selectedMembers.length} member(s) selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF004AAD),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _canCreateGroup() ? () {
            Navigator.pop(context, {
              'groupName': _groupNameController.text.trim(),
              'selectedMembers': _selectedMembers,
              'projectId': _selectedProjectId,
            });
          } : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF004AAD),
            foregroundColor: Colors.white,
          ),
          child: Text('Create'),
        ),
      ],
    );
  }

  bool _canCreateGroup() {
    return _groupNameController.text.trim().isNotEmpty &&
        _selectedProjectId != null &&
        _selectedMembers.isNotEmpty;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
}