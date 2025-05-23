import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/widgets/drawer_header.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:task_orbit/services/AuthService.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/FirestoreService.dart';
import '../../widgets/product_owner_drawer.dart';

class AddMembersScreen extends StatefulWidget {
  const AddMembersScreen({Key? key}) : super(key: key);

  @override
  State<AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends State<AddMembersScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedTabIndex = 0; // 0 for Add, 1 for Pending
  bool _isLoading = false;
  bool _isSearching = false;
  Map<String, dynamic>? _searchResult;

  // Form controllers
  final TextEditingController _projectIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _invitationMessageController =
  TextEditingController();

  // Dropdowns
  String? _selectedProject;
  String? _selectedRole;

  // Available roles
  final List<String> _roles = ['Scrum Master', 'Team Member', 'Client'];

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color errorColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    print("AddMembersScreen initialized");
    _loadProjects();
    _selectedRole = _roles.isNotEmpty ? _roles[0] : null;
  }

  @override
  void dispose() {
    _projectIdController.dispose();
    _emailController.dispose();
    _invitationMessageController.dispose();
    super.dispose();
  }

  // Load user's projects
  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.refreshProjects();

      if (mounted && projectService.projects.isNotEmpty) {
        setState(() {
          // Get the name or title from the first project
          final firstProject = projectService.projects[0];
          _selectedProject = firstProject['name'] ?? firstProject['title'] ?? 'Unnamed Project';
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    try {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.cancelInvitation(invitationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invitation cancelled successfully'),
          backgroundColor: primaryColor,
        ),
      );
      // Refresh the list
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling invitation: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }
  // Open email client to send invitation and create a record in Firebase
  Future<void> _sendEmailInvitation() async {
    if (!_validateForm()) return;
    if (_selectedProject == null || _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project and role'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    // Get current user
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to send invitations'),
          backgroundColor: errorColor,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final emailRecipient = _emailController.text.trim();
      final recipientName = _getNameFromEmail(emailRecipient);
      final invitationMessage = _invitationMessageController.text.trim();
      final projectName = _selectedProject!;
      final role = _selectedRole!;
      final inviterName = user.displayName ?? 'TaskOrbit team member';

      // Get project ID from project service
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final projectIndex = projectService.projects.indexWhere(
              (p) => (p['name'] ?? p['title'] ?? '') == _selectedProject
      );

      if (projectIndex == -1) {
        throw Exception('Project not found');
      }

      final projectId = projectService.projects[projectIndex]['id'];

      // Create invitation in Firestore
      await FirebaseFirestore.instance.collection('invitations').add({
        'email': emailRecipient.toLowerCase(),
        'projectId': projectId,
        'projectName': projectName,
        'role': role,
        'status': 'pending',
        'invitedBy': user.uid,
        'inviterName': inviterName,
        'invitedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 7)),
        ),
        'message': invitationMessage,
      });

      // Launch email client
      final subject = 'Invitation to join TaskOrbit project: $projectName';
      final body = '''
Dear $recipientName,

You have been invited to join the TaskOrbit project "$projectName" as a $role by $inviterName.

${invitationMessage.isNotEmpty ? 'Message: $invitationMessage\n\n' : ''}

To accept this invitation, please create an account on TaskOrbit using this email address: $emailRecipient

Best regards,
TaskOrbit Team
''';

      final Uri emailLaunchUri = Uri(
        scheme: 'mailto',
        path: emailRecipient,
        query: _encodeQueryParameters({
          'subject': subject,
          'body': body,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (!await launchUrl(emailLaunchUri)) {
        throw Exception('Could not open email client');
      }

      // Clear inputs after successful email launch
      setState(() {
        _searchResult = null;
        _emailController.clear();
        _invitationMessageController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email invitation sent successfully'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending invitation: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  // Extract name from email
  String _getNameFromEmail(String email) {
    if (email.isEmpty) return 'Unknown';

    // Extract the part before @ and capitalize first letter
    String namePart = email.split('@')[0];
    return namePart.isNotEmpty
        ? '${namePart[0].toUpperCase()}${namePart.substring(1)}'
        : 'Unknown';
  }

  // Validate email
  bool _validateEmailInput() {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an email address'),
          backgroundColor: errorColor,
        ),
      );
      return false;
    }

    if (!_emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: errorColor,
        ),
      );
      return false;
    }

    return true;
  }

  // Validate form
  bool _validateForm() {
    String? errorMessage;

    if (_emailController.text.isEmpty) {
      errorMessage = "Please enter member's email";
    } else if (!_emailController.text.contains('@')) {
      errorMessage = "Please enter a valid email address";
    }

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
      return false;
    }

    return true;
  }
  Future<void> _searchUser() async {
    if (!_validateEmailInput()) return;
    setState(() {
      _isSearching = true;
      _searchResult = null; // Reset previous search result
    });
    try {
      final email = _emailController.text.trim().toLowerCase();

      // Use the FirestoreService to search for the user
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final userData = await firestoreService.searchUserByEmail(email);

      setState(() {
        _isSearching = false;
        _searchResult = userData ?? {}; // Empty map if no user found
      });

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active user found with this email.'))
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching user: $e')),
      );
    }
  }
  Future<void> _addUserToProject() async {
    if (_searchResult == null || _selectedProject == null) return;
    try {
      setState(() {
        _isLoading = true;
      });

      // Get project from project service
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final projectIndex = projectService.projects.indexWhere(
              (p) => (p['name'] ?? p['title'] ?? '') == _selectedProject
      );

      if (projectIndex == -1) {
        throw Exception('Project not found');
      }

      final projectId = projectService.projects[projectIndex]['id'];
      final userId = _searchResult!['id'];
      final userName = _searchResult!['name'] ?? 'Unknown User';

      // IMPORTANT: Use the user's existing role instead of _selectedRole
      final userRole = _searchResult!['role'] ?? 'Team Member'; // Default to Team Member if no role found

      print('User\'s actual role from profile: $userRole');

      // Get the current project data
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final projectDoc = await firestoreService.projectsRef.doc(projectId).get();
      final projectData = projectDoc.data() as Map<String, dynamic>?;

      if (projectData == null) {
        throw Exception('Project data not found');
      }

      // Determine which structure the project is using
      if (projectData.containsKey('roles')) {
        // New structure - add based on user's existing role
        String roleName = '';

        // Map from user roles to data structure field names
        // Ensure exact string comparison with no whitespace issues
        if (userRole.contains('Scrum Master')) {
          roleName = 'scrumMasters';
        } else if (userRole.contains('Team Member')) {
          roleName = 'teamMembers';
        } else if (userRole.contains('Client')) {
          roleName = 'clients';
        } else {
          // Default to teamMembers if role is not recognized
          roleName = 'teamMembers';
          print('WARNING: Unrecognized role "$userRole", defaulting to teamMembers');
        }

        print('Adding user "$userName" to role: "$roleName" (based on user profile role: "$userRole")');

        // IMPORTANT: First check if user exists in any other role arrays and remove them
        if (roleName != 'scrumMasters' &&
            projectData['roles'].containsKey('scrumMasters') &&
            projectData['roles']['scrumMasters'] is List &&
            (projectData['roles']['scrumMasters'] as List).contains(userId)) {
          // Remove from scrumMasters if being added to a different role
          await firestoreService.projectsRef.doc(projectId).update({
            'roles.scrumMasters': FieldValue.arrayRemove([userId]),
          });
          print('Removed user from scrumMasters array before adding to $roleName');
        }

        if (roleName != 'teamMembers' &&
            projectData['roles'].containsKey('teamMembers') &&
            projectData['roles']['teamMembers'] is List &&
            (projectData['roles']['teamMembers'] as List).contains(userId)) {
          // Remove from teamMembers if being added to a different role
          await firestoreService.projectsRef.doc(projectId).update({
            'roles.teamMembers': FieldValue.arrayRemove([userId]),
          });
          print('Removed user from teamMembers array before adding to $roleName');
        }

        if (roleName != 'clients' &&
            projectData['roles'].containsKey('clients') &&
            projectData['roles']['clients'] is List &&
            (projectData['roles']['clients'] as List).contains(userId)) {
          // Remove from clients if being added to a different role
          await firestoreService.projectsRef.doc(projectId).update({
            'roles.clients': FieldValue.arrayRemove([userId]),
          });
          print('Removed user from clients array before adding to $roleName');
        }

        // Now add to the correct role array
        await firestoreService.projectsRef.doc(projectId).update({
          'roles.$roleName': FieldValue.arrayUnion([userId]),
          'updated_at': FieldValue.serverTimestamp(),
        });

        print('Successfully added user to $roleName array');
      } else {
        // Old structure - use the members array
        await firestoreService.addMemberToProject(projectId, userId);
      }

      // Refresh projects list to ensure it's updated everywhere
      await projectService.refreshProjects();

      setState(() {
        _isLoading = false;
        _searchResult = null;
        _emailController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User "$userName" added to project as $userRole'),
          backgroundColor: primaryColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding user to project: $e'),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  // Modern input decoration based on SignUp screen
  InputDecoration _getModernInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: primaryColor, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFDFDFD),
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      constraints: const BoxConstraints(minHeight: 56),
      alignLabelWithHint: true,
      isCollapsed: false,
      prefixIconColor: primaryColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      errorStyle: TextStyle(
        color: errorColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
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
                fontFamily: 'Poppins-SemiBold',
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project dropdown with no label
            Builder(
              builder: (context) {
                final projectService = Provider.of<ProjectService>(context);

                // If no projects are available
                if (projectService.projects.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No projects available. Please create a project first."),
                  );
                }

                // Extract project names
                final List<DropdownMenuItem<String>> dropdownItems = [];
                for (var project in projectService.projects) {
                  final name = project['name'] ?? project['title'] ?? 'Unnamed Project';
                  dropdownItems.add(DropdownMenuItem(
                    value: name,
                    child: Text(name),
                  ));
                }

                return DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFDFDFD),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.assignment, color: primaryColor, size: 22),
                  ),
                  hint: const Text('Select a project'),
                  value: _selectedProject,
                  items: dropdownItems,
                  onChanged: (value) {
                    setState(() {
                      _selectedProject = value;
                    });
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Instruction text for searching by email
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Text(
                "Enter the member's email address to search for them:",
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Email input with search button
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: _getModernInputDecoration(
                      label: 'Email Address',
                      icon: Icons.email,
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  child: const Text('Search', style: TextStyle (color: Color(0xFFFDFDFD), fontWeight: FontWeight.bold)),
                ),
              ],
            ),

            // Search results or invitation form
            _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResult == null
                ? const SizedBox.shrink()
                : _searchResult!.isEmpty
                ? _buildInvitationForm()
                : _buildUserSearchResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSearchResult() {
    return Card(
      color: Color(0xFFFDFDFD),
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: primaryColor,
                  child: Text(
                    _searchResult!['name'].toString().substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _searchResult!['name'] ?? 'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _searchResult!['email'] ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      // Display user role
                      Text(
                        _searchResult!['role'] ?? 'Unknown Role',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _addUserToProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Add', style: TextStyle(color: Color(0xFFFDFDFD), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationForm() {
    return Card(
      color: Color(0xFFFDFDFD),
      margin: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User not found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send an invitation to ${_emailController.text}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),

            // Role selection
            DropdownButtonFormField<String>(
              decoration: _getModernInputDecoration(
                label: 'Role',
                icon: Icons.person,
              ),
              value: _selectedRole,
              items: _roles.map((role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Invitation message
            TextFormField(
              controller: _invitationMessageController,
              decoration: _getModernInputDecoration(
                label: 'Invitation Message (Optional)',
                icon: Icons.message,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Send email invitation button
            Center(
              child: ElevatedButton.icon(
                onPressed: _sendEmailInvitation,
                icon: const Icon(Icons.email, size: 18),
                label: const Text('Send Email Invitation', style: TextStyle(color: Color(0xFFFDFDFD), fontWeight: FontWeight.bold,),),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('invitations')
          .where('invitedBy', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final invitations = snapshot.data?.docs ?? [];

        if (invitations.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No pending invitations found',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: invitations.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final invitation = invitations[index].data() as Map<String, dynamic>;
            final invitationId = invitations[index].id;

            return Card(
              color: Color(0xFFFDFDFD),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Text(
                            invitation['email'].toString().substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                invitation['email'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Project: ${invitation['projectName'] ?? 'Unknown'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Role: ${invitation['role'] ?? 'Member'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Status: ${invitation['status'] ?? 'pending'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _cancelInvitation(invitationId),
                        ),
                      ],
                    ),
                    if (invitation['message'] != null && invitation['message'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Message: ${invitation['message']}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    // Add a "Resend Email" button
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: Icon(Icons.email, size: 16, color: primaryColor),
                          label: Text(
                            'Resend Email',
                            style: TextStyle(color: primaryColor),
                          ),
                          onPressed: () {
                            // Prepare email content
                            final email = invitation['email'] ?? '';
                            final projectName = invitation['projectName'] ?? '';
                            final role = invitation['role'] ?? '';
                            final message = invitation['message'] ?? '';
                            final recipientName = _getNameFromEmail(email);
                            final inviterName = invitation['inviterName'] ?? 'TaskOrbit team member';

                            final subject = 'Invitation to join TaskOrbit project: $projectName';
                            final body = '''
Dear $recipientName,

You have been invited to join the TaskOrbit project "$projectName" as a $role by $inviterName.

${message.isNotEmpty ? 'Message: $message\n\n' : ''}

To accept this invitation, please create an account on TaskOrbit using this email address: $email

Best regards,
TaskOrbit Team
''';

                            final Uri emailLaunchUri = Uri(
                              scheme: 'mailto',
                              path: email,
                              query: _encodeQueryParameters({
                                'subject': subject,
                                'body': body,
                              }),
                            );

                            launchUrl(emailLaunchUri);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
        title: const Text(
          "Add Members",
          style: TextStyle(
            color: Color(0xFF313131),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: const Color(0xFF004AAD),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat),
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'Add Members'),
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
          child: Column(
            children: [
              // Back button and title
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text(
                      'Add Members',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                  ],
                ),
              ),

              // Tab Bar (matching ProductBacklogScreen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                            _selectedTabIndex == 0
                                ? const Color(0xFF004AAD)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => setState(() => _selectedTabIndex = 0),
                          child: Text(
                            'Add',
                            style: TextStyle(
                              color:
                              _selectedTabIndex == 0 ? Colors.white : const Color(0xFF004AAD),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor:
                            _selectedTabIndex == 1
                                ? const Color(0xFF004AAD)
                                : Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => setState(() => _selectedTabIndex = 1),
                          child: Text(
                            'Pending',
                            style: TextStyle(
                              color:
                              _selectedTabIndex == 1 ? Colors.white : const Color(0xFF004AAD),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _selectedTabIndex == 0
                    ? _buildAddTab()
                    : _buildPendingTab(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFDFDFD),
        currentIndex: 1, // Projects tab selected by default
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
            icon: Icon(Icons.schedule),
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
}