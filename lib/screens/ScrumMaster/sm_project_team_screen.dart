// File: lib/screens/Scrum_Master/sm_project_team_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../widgets/sm_drawer.dart';

class SMProjectTeamScreen extends StatefulWidget {
  final Map<String, dynamic>? projectData;
  static const Color primaryColor = Color(0xFF004AAD);

  const SMProjectTeamScreen({Key? key, this.projectData}) : super(key: key);

  @override
  State<SMProjectTeamScreen> createState() => _SMProjectTeamScreenState();
}

class _SMProjectTeamScreenState extends State<SMProjectTeamScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; // Projects tab in bottom nav
  bool _isLoading = true;

  // Project members data
  Map<String, dynamic>? _productOwner;
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
      // Get member IDs from both old and new structures
      List<String> memberIds = [];
      String? productOwnerId;

      // Check if project has the old structure
      if (widget.projectData?.containsKey('members') == true &&
          widget.projectData?['members'] != null) {
        List<dynamic> oldMemberIds = widget.projectData!['members'];
        memberIds.addAll(oldMemberIds.cast<String>());
      }

      // Check if project has the new role-based structure
      if (widget.projectData?.containsKey('roles') == true &&
          widget.projectData?['roles'] != null) {

        // Extract Product Owner - store separately to identify them later
        if (widget.projectData!['roles'].containsKey('productOwner')) {
          productOwnerId = widget.projectData!['roles']['productOwner'];
          if (productOwnerId != null) {
            memberIds.add(productOwnerId);
          }
        }

        // Extract Team Members
        if (widget.projectData!['roles'].containsKey('teamMembers')) {
          List<dynamic> teamMemberIds = widget.projectData!['roles']['teamMembers'];
          memberIds.addAll(teamMemberIds.cast<String>());
        }

        // Extract Clients
        if (widget.projectData!['roles'].containsKey('clients')) {
          List<dynamic> clientIds = widget.projectData!['roles']['clients'];
          memberIds.addAll(clientIds.cast<String>());
        }
      }

      // Remove duplicates
      memberIds = memberIds.toSet().toList();

      if (memberIds.isEmpty) {
        // If still no members, check the createdBy field for Product Owner
        if (widget.projectData?.containsKey('createdBy') == true &&
            widget.projectData?['createdBy'] != null) {
          final creatorId = widget.projectData!['createdBy'];
          memberIds.add(creatorId);
          productOwnerId = creatorId; // Mark the creator as Product Owner
        }
      }

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

      // Categorize members based on roles in the project
      Map<String, dynamic>? productOwner;
      List<Map<String, dynamic>> teamMembers = [];
      List<Map<String, dynamic>> clients = [];

      // Use the new roles structure if available
      if (widget.projectData?.containsKey('roles') == true &&
          widget.projectData?['roles'] != null) {

        for (var member in allMembers) {
          final memberId = member['id'];

          // Check which role this member has in the project
          if (productOwnerId == memberId) {
            productOwner = member;
          }
          else if (widget.projectData!['roles'].containsKey('teamMembers') &&
              widget.projectData!['roles']['teamMembers'].contains(memberId)) {
            teamMembers.add(member);
          }
          else if (widget.projectData!['roles'].containsKey('clients') &&
              widget.projectData!['roles']['clients'].contains(memberId)) {
            clients.add(member);
          }
        }
      } else {
        // Fallback to using the role field in user documents
        for (var member in allMembers) {
          final role = member['role'];

          if (role == 'Product_Owner' || role == 'Product Owner') {
            productOwner = member;
          } else if (role == 'Team Member') {
            teamMembers.add(member);
          } else if (role == 'Client') {
            clients.add(member);
          }
        }
      }

      // If still no product owner but we have a createdBy field, use it
      if (productOwner == null && widget.projectData?.containsKey('createdBy') == true) {
        final creatorId = widget.projectData!['createdBy'];

        // Find if we already have the creator in our members list
        var creatorMember = allMembers.firstWhere(
                (member) => member['id'] == creatorId,
            orElse: () => <String, dynamic>{}
        );

        if (creatorMember.isNotEmpty) {
          productOwner = creatorMember;
        } else {
          // Fetch creator data if not already loaded
          final creatorDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(creatorId)
              .get();

          if (creatorDoc.exists && creatorDoc.data() != null) {
            productOwner = {
              'id': creatorId,
              ...creatorDoc.data()!,
              'role': 'Product Owner', // Force the role
            };
          }
        }
      }

      setState(() {
        _productOwner = productOwner;
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

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/scrumMasterProfile');
  }

  void _sendMessageToMember(Map<String, dynamic> member) {
    // Implement chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${member['name']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Build the Product Owner card (updated to match TeamOverviewScreen style)
  Widget _buildProductOwnerCard(Map<String, dynamic> productOwner) {
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
          // Product Owner Header
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
                        productOwner['name'].toString().substring(0, 1).toUpperCase(),
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
                        productOwner['name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const Text(
                        'Product Owner',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chat, color: Color(0xFF004AAD)),
                    onPressed: () => _sendMessageToMember(productOwner),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Contact info
          Row(
            children: [
              const Icon(Icons.email_outlined, color: Color(0xFF666666), size: 16),
              const SizedBox(width: 8),
              Text(
                productOwner['email'] ?? 'No email provided',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the Team Members section (updated to match TeamOverviewScreen style)
  Widget _buildTeamMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.group, color: Color(0xFF004AAD)),
            const SizedBox(width: 8),
            const Text(
              'Team Members',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004AAD),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
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
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _teamMembers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = _teamMembers[index];
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Profile picture or avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          member['name'].toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            member['email'] ?? 'No email provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    IconButton(
                      icon: const Icon(Icons.chat, color: Color(0xFF004AAD)),
                      onPressed: () => _sendMessageToMember(member),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build the Clients section (updated to match TeamOverviewScreen style)
  Widget _buildClientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.business, color: Color(0xFF004AAD)),
            const SizedBox(width: 8),
            const Text(
              'Clients',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004AAD),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
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
          child: ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _clients.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final client = _clients[index];
              return Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Profile picture or avatar
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          client['name'].toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Name and email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            client['email'] ?? 'No email provided',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    IconButton(
                      icon: const Icon(Icons.chat, color: Color(0xFF004AAD)),
                      onPressed: () => _sendMessageToMember(client),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build the no team members message (unchanged)
  Widget _buildNoTeamMembersMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.group_off,
            size: 64,
            color: Color(0xFF004AAD),
          ),
          const SizedBox(height: 16),
          const Text(
            'No team members found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF313131),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This project doesn\'t have any team members yet.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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
            color: SMProjectTeamScreen.primaryColor,
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat),
            color: SMProjectTeamScreen.primaryColor,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: SMProjectTeamScreen.primaryColor,
            onPressed: () {},
          ),
        ],
      ),
      drawer: const SMDrawer(selectedItem: 'My Projects'),
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
                    widget.projectData?['name'] ?? 'Project Name',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Product Owner Card
                if (_productOwner != null) ...[
                  _buildProductOwnerCard(_productOwner!),
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
                if (_productOwner == null && _teamMembers.isEmpty && _clients.isEmpty)
                  _buildNoTeamMembersMessage(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}