import 'package:flutter/material.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ChatService.dart';
import '../../widgets/product_owner_drawer.dart';

class TeamOverviewScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const TeamOverviewScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<TeamOverviewScreen> createState() => _TeamOverviewScreenState();
}

class _TeamOverviewScreenState extends State<TeamOverviewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isLoading = true;

  // Project members data
  Map<String, dynamic>? _scrumMaster;
  List<Map<String, dynamic>> _teamMembers = [];
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  Future<void> _loadTeamMembers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch fresh project data directly from Firestore
      final projectId = widget.project['id'];
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();

      if (!projectDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Use fresh project data for loading team members
      final freshProjectData = {
        'id': projectId,
        ...projectDoc.data() as Map<String, dynamic>
      };

      // Get member IDs from both old and new structures using the fresh data
      List<String> memberIds = [];

      // Check if project has the old structure
      if (freshProjectData.containsKey('members') && freshProjectData['members'] != null) {
        List<dynamic> oldMemberIds = freshProjectData['members'];
        memberIds.addAll(oldMemberIds.cast<String>());
      }

      // Get all role arrays from the new structure
      List<String> scrumMasterIds = [];
      List<String> teamMemberIds = [];
      List<String> clientIds = [];
      String? productOwnerId;

      if (freshProjectData.containsKey('roles') && freshProjectData['roles'] != null) {
        // Extract Scrum Masters
        if (freshProjectData['roles'].containsKey('scrumMasters')) {
          scrumMasterIds = (freshProjectData['roles']['scrumMasters'] as List<dynamic>).cast<String>();
          memberIds.addAll(scrumMasterIds);
        }

        // Extract Team Members
        if (freshProjectData['roles'].containsKey('teamMembers')) {
          teamMemberIds = (freshProjectData['roles']['teamMembers'] as List<dynamic>).cast<String>();
          memberIds.addAll(teamMemberIds);
        }

        // Extract Clients
        if (freshProjectData['roles'].containsKey('clients')) {
          clientIds = (freshProjectData['roles']['clients'] as List<dynamic>).cast<String>();
          memberIds.addAll(clientIds);
        }

        // Extract Product Owner
        if (freshProjectData['roles'].containsKey('productOwner')) {
          productOwnerId = freshProjectData['roles']['productOwner'];
          if (productOwnerId != null) {
            memberIds.add(productOwnerId);
          }
        }
      }

      // Remove duplicates
      memberIds = memberIds.toSet().toList();

      if (memberIds.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch user data for each member
      List<Map<String, dynamic>> allMembers = [];

      for (String memberId in memberIds) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(memberId)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          allMembers.add({
            'id': userDoc.id,
            ...userDoc.data()!,
          });
        }
      }

      // Categorize members by role
      List<Map<String, dynamic>> scrumMasters = [];
      List<Map<String, dynamic>> teamMembers = [];
      List<Map<String, dynamic>> clients = [];
      Map<String, dynamic>? productOwner;

      // Process one role at a time, prioritizing roles in this order:
      // 1. Product Owner, 2. Team Members, 3. Clients, 4. Scrum Masters

      // First assign Product Owner
      if (productOwnerId != null) {
        productOwner = allMembers.firstWhere(
              (member) => member['id'] == productOwnerId,
          orElse: () => <String, dynamic>{},
        );
      }

      // Next assign Team Members
      for (var memberId in teamMemberIds) {
        final memberData = allMembers.firstWhere(
              (member) => member['id'] == memberId,
          orElse: () => <String, dynamic>{},
        );

        if (memberData.isNotEmpty && memberData['id'] != productOwnerId) {
          teamMembers.add(memberData);
        }
      }

      // Next assign Clients
      for (var memberId in clientIds) {
        final memberData = allMembers.firstWhere(
              (member) => member['id'] == memberId,
          orElse: () => <String, dynamic>{},
        );

        if (memberData.isNotEmpty &&
            memberData['id'] != productOwnerId &&
            !teamMembers.any((tm) => tm['id'] == memberData['id'])) {
          clients.add(memberData);
        }
      }

      // Finally assign Scrum Masters
      for (var memberId in scrumMasterIds) {
        final memberData = allMembers.firstWhere(
              (member) => member['id'] == memberId,
          orElse: () => <String, dynamic>{},
        );

        if (memberData.isNotEmpty &&
            memberData['id'] != productOwnerId &&
            !teamMembers.any((tm) => tm['id'] == memberData['id']) &&
            !clients.any((c) => c['id'] == memberData['id'])) {
          scrumMasters.add(memberData);
        }
      }

      setState(() {
        _scrumMaster = scrumMasters.isNotEmpty ? scrumMasters.first : null;
        _teamMembers = teamMembers;
        _clients = clients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading team members: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final memberId = member['id'];
      final projectId = widget.project['id'];
      final projectDoc = await FirebaseFirestore.instance.collection('projects').doc(projectId).get();
      final projectData = projectDoc.data() as Map<String, dynamic>?;

      if (projectData == null) {
        throw Exception("Project data not found");
      }

      // Determine which data structure to update
      if (projectData.containsKey('roles') && projectData['roles'] != null) {
        // New structure - find which role the member has
        Map<String, dynamic> roles = Map<String, dynamic>.from(projectData['roles']);
        String? roleToUpdate;

        // Check each role array for the member
        if (roles.containsKey('productOwner') && roles['productOwner'] == memberId) {
          roleToUpdate = 'productOwner';
        } else if (roles.containsKey('scrumMasters') &&
            (roles['scrumMasters'] as List<dynamic>).contains(memberId)) {
          roleToUpdate = 'scrumMasters';
        } else if (roles.containsKey('teamMembers') &&
            (roles['teamMembers'] as List<dynamic>).contains(memberId)) {
          roleToUpdate = 'teamMembers';
        } else if (roles.containsKey('clients') &&
            (roles['clients'] as List<dynamic>).contains(memberId)) {
          roleToUpdate = 'clients';
        }

        if (roleToUpdate != null) {
          if (roleToUpdate == 'productOwner') {
            // Special case for product owner (it's not an array)
            await FirebaseFirestore.instance
                .collection('projects')
                .doc(projectId)
                .update({
              'roles.productOwner': FieldValue.delete(),
            });
          } else {
            // For role arrays (scrumMasters, teamMembers, clients)
            await FirebaseFirestore.instance
                .collection('projects')
                .doc(projectId)
                .update({
              'roles.$roleToUpdate': FieldValue.arrayRemove([memberId]),
            });
          }
        }
      }

      // Also remove from the legacy members array if it exists
      if (projectData.containsKey('members') && projectData['members'] != null) {
        await FirebaseFirestore.instance
            .collection('projects')
            .doc(projectId)
            .update({
          'members': FieldValue.arrayRemove([memberId]),
        });
      }

      // Refresh the project service to update the local state
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.refreshProjects();

      // Reload the team members
      await _loadTeamMembers();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member['name']} has been removed from the project'),
          backgroundColor: const Color(0xFF004AAD),
        ),
      );
    } catch (e) {
      print('Error removing member: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing member: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  // Confirm removal dialog
  Future<void> _showRemoveConfirmationDialog(Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member['name']} from this project?'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _removeMember(member);
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  Future<void> _sendMessageToMember(Map<String, dynamic> member) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to send messages'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening chat with ${member['name']}...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // Get or create direct chat
      final chatService = Provider.of<ChatService>(context, listen: false);
      final chatId = await chatService.getOrCreateDirectChat(
        currentUser.uid,
        member['id'],
      );

      // Navigate to chat screen
      Navigator.pushNamed(
        context,
        '/POChat',
        arguments: {
          'chatId': chatId,
          'name': member['name'] ?? 'Unknown',
          'role': _getMemberRole(member),
          'avatar': member['name']?.toString().substring(0, 1).toUpperCase() ?? 'U',
        },
      );
    } catch (e) {
      print('Error opening chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Helper method to determine member role
  String _getMemberRole(Map<String, dynamic> member) {
    if (_scrumMaster != null && _scrumMaster!['id'] == member['id']) {
      return 'Scrum Master';
    } else if (_teamMembers.any((tm) => tm['id'] == member['id'])) {
      return 'Team Member';
    } else if (_clients.any((c) => c['id'] == member['id'])) {
      return 'Client';
    }
    return 'Team Member';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: MyProjectsScreen.primaryColor,
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat),
            color: Color(0xFF004AAD),
            onPressed: () {
              Navigator.pushNamed(context, '/POChat_list');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFE3EFFF)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF004AAD)))
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button and Title Row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(0),
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Team Overview',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Project Name
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: Text(
                    widget.project['name'] ?? 'Project Name',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Scrum Master Card
                if (_scrumMaster != null) ...[
                  _buildScrumMasterCard(_scrumMaster!),
                  const SizedBox(height: 20),
                ],

                // Team Members Section
                if (_teamMembers.isNotEmpty) ...[
                  _buildTeamMembersSection(),
                  const SizedBox(height: 20),
                ],

                // Clients Section
                if (_clients.isNotEmpty) ...[
                  _buildClientsSection(),
                ],

                // No team members message
                if (_scrumMaster == null && _teamMembers.isEmpty && _clients.isEmpty)
                  _buildNoTeamMembersMessage(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFDFDFD),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF004AAD),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins-SemiBold',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins-SemiBold',
          fontWeight: FontWeight.bold,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time_filled_rounded),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildScrumMasterCard(Map<String, dynamic> scrumMaster) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrum Master Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Profile picture or avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0E0E0),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        scrumMaster['name'].toString().substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Name and role
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scrumMaster['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const Text(
                        'Scrum Master',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Action buttons row
              Row(
                children: [
                  // Message button
                  IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFF004AAD)),
                    onPressed: () => _sendMessageToMember(scrumMaster),
                  ),
                  // Remove button
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _showRemoveConfirmationDialog(scrumMaster),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Contact Info Section
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF313131),
            ),
          ),
          const SizedBox(height: 8),

          // Email in a row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scrumMaster['email'] ?? 'No email provided',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Team Members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF313131),
          ),
        ),
        const SizedBox(height: 12),
        ...(_teamMembers.map((member) => _buildMemberCard(member)).toList()),
      ],
    );
  }

  Widget _buildClientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Clients',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF313131),
          ),
        ),
        const SizedBox(height: 12),
        ...(_clients.map((client) => _buildMemberCard(client)).toList()),
      ],
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFE0E0E0),
          child: Text(
            member['name'].toString().substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF666666),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member['name'] ?? 'Unknown',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF313131),
          ),
        ),
        subtitle: Text(
          member['email'] ?? 'No email provided',
          style: const TextStyle(
            color: Color(0xFF666666),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message button
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF004AAD)),
              onPressed: () => _sendMessageToMember(member),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _showRemoveConfirmationDialog(member),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTeamMembersMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(
            Icons.group_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No Team Members Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF313131),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add team members to this project',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/addMembers');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Members'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004AAD),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}