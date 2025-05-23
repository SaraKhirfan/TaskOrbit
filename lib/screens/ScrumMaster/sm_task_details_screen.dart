import 'package:flutter/material.dart';
import '../../services/TeamMemberTaskService.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../services/project_service.dart';
import 'package:provider/provider.dart';
import 'TeamMemberSelectionDialog.dart';

class SMTaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String storyStatus; // Added storyStatus parameter
  final String projectId; // Added to fetch project members
  const SMTaskDetailsScreen({
    Key? key,
    required this.task,
    required this.storyStatus,
    required this.projectId,
  }) : super(key: key);
  @override
  _SMTaskDetailsScreenState createState() => _SMTaskDetailsScreenState();
}
class _SMTaskDetailsScreenState extends State<SMTaskDetailsScreen> {
  // Removed the duplicate assignedMembers variable
  List<Map<String, dynamic>> _assignedMembers = []; // Single source of truth for assigned members
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 1; // tab in bottom nav
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/scrumMasterProfile');
  }
  @override
  void initState() {
    super.initState();
    // Debug for all parameters
    print('Task Screen: Initialized with:');
    print('- projectId: "${widget.projectId}"');
    print('- task data keys: ${widget.task.keys.toList()}');
    print('- storyStatus: ${widget.storyStatus}');

    // Check for backlogId specifically
    if (!widget.task.containsKey('backlogId') || widget.task['backlogId'] == null || widget.task['backlogId'].toString().isEmpty) {
      print('Task Screen WARNING: task is missing backlogId!');
    }

    // Initialize assigned members from task if they exist (fallback)
    if (widget.task.containsKey('assignedMembersData')) {
      _assignedMembers = List<Map<String, dynamic>>.from(
        widget.task['assignedMembersData'],
      );
      print('Task Screen: Loaded ${_assignedMembers.length} assigned members from task');
    }

    // Load assigned members from Firestore
    _loadAssignedMembersFromFirestore();
  }

// Add this new method to SMTaskDetailsScreen
  Future<void> _loadAssignedMembersFromFirestore() async {
    try {
      print('Loading assigned members from Firestore...');

      // Get the required IDs
      final taskId = widget.task['id'];
      final backlogId = widget.task['backlogId'];
      String? projectId = widget.projectId;

      if (projectId.isEmpty && widget.task.containsKey('projectId')) {
        projectId = widget.task['projectId'];
      }

      if (taskId == null || backlogId == null || projectId == null || projectId.isEmpty) {
        print('Cannot load assigned members: missing required IDs');
        print('- taskId: $taskId');
        print('- backlogId: $backlogId');
        print('- projectId: $projectId');
        return;
      }

      // Use TeamMemberTaskService to get the assigned members
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);
      final assignedMembers = await teamMemberTaskService.getTaskAssignedMembers(
        projectId,
        backlogId,
        taskId,
      );

      print('Loaded ${assignedMembers.length} assigned members from Firestore');

      setState(() {
        _assignedMembers = assignedMembers;
      });
    } catch (e) {
      print('Error loading assigned members from Firestore: $e');
    }
  }

  Future<void> _showTeamMemberSelectionDialog() async {
    try {
      // Try to get a valid project ID from multiple sources
      String? effectiveProjectId;
      // First check if widget.projectId is valid
      if (widget.projectId.isNotEmpty) {
        effectiveProjectId = widget.projectId;
        print('Using widget.projectId: $effectiveProjectId');
      }
      // If not, check the task data
      else if (widget.task.containsKey('projectId') &&
          widget.task['projectId'] != null &&
          widget.task['projectId'].toString().isNotEmpty) {
        effectiveProjectId = widget.task['projectId'];
        print('Using projectId from task: $effectiveProjectId');
      }
      // If still not found, use the first project from ProjectService as fallback
      else {
        print('No projectId found in task or widget, trying ProjectService');
        final projectService = Provider.of<ProjectService>(context, listen: false);
        if (projectService.projects.isNotEmpty) {
          effectiveProjectId = projectService.projects.first['id'];
          print('Using fallback projectId from ProjectService: $effectiveProjectId');
        }
      }
      // Still no valid ID?
      if (effectiveProjectId == null || effectiveProjectId.isEmpty) {
        print('No valid projectId found from any source');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Project ID is missing, cannot load team members')),
        );
        return;
      }
      // Now use the valid project ID for the dialog
      final result = await showDialog<List<Map<String, dynamic>>>(
        context: context,
        builder: (context) => TeamMemberSelectionDialog(
          currentAssignedMembers: _assignedMembers,
          projectId: effectiveProjectId!,
        ),
      );
      if (result != null) {
        setState(() {
          _assignedMembers = result;
        });
        // Save to Firestore with our effective project ID
        await _saveAssignedMembersToFirestore(effectiveProjectId);
      }
    } catch (e) {
      print('Error in team member selection: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting team members')),
      );
    }
  }

  Future<void> _saveAssignedMembersToFirestore(String projectId) async {
    try {
      // Check if task has backlog ID, if not, try to find it
      String? backlogId = widget.task['backlogId'];
      // If backlogId is missing, check if we can get it from other sources
      if (backlogId == null || backlogId.isEmpty) {
        print('ERROR: Task is missing backlogId, checking if story has an ID');
        // Option 1: Check if there's a story ID in the task
        if (widget.task.containsKey('storyId') &&
            widget.task['storyId'] != null &&
            widget.task['storyId'].toString().isNotEmpty) {
          backlogId = widget.task['storyId'];
          print('Found backlogId from storyId: $backlogId');
        }
        else {
          // Show error and return since we can't save without backlogId
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Missing backlog ID - cannot save assignments')),
          );
          return;
        }
      }
      final String taskId = widget.task['id'] ?? '';
      // Validate all required IDs
      if (taskId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Missing task ID')),
        );
        return;
      }
      if (projectId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Missing project ID')),
        );
        return;
      }
      // Make sure backlogId is not null before using it
      if (backlogId == null || backlogId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Missing backlog ID after fallback checks')),
        );
        return;
      }
      // Print all the data we're working with
      print('Using: projectId=$projectId, backlogId=$backlogId, taskId=$taskId');
      print('Saving ${_assignedMembers.length} assigned members');
      // Use TeamMemberTaskService
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);
      await teamMemberTaskService.updateTaskAssignedMembers(
          projectId,
          backlogId,
          taskId,
          _assignedMembers
      );
      // Force UI refresh after successful save
      setState(() {
        // This empty setState will trigger a UI rebuild with the updated _assignedMembers
      });
      print('Successfully saved assigned members to Firestore');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Members assigned successfully')),
      );
    } catch (e) {
      print('Error saving assigned members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving team members: ${e.toString().substring(0, 50)}')),
      );
    }
  }


  // Get priority color based on the priority value
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  // Get status color based on the status value
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'not started':
        return Color(0xFF004AAD); // Blue
      case 'in progress':
        return Colors.orange;
      case 'done':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    String priority = widget.task['priority'] ?? 'Medium';
    Color priorityColor = _getPriorityColor(priority);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F7), // Light blue background
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Color(0xFF004AAD)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.message, color: Color(0xFF004AAD)),
            onPressed: () {
              // Chat functionality
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: Color(0xFF004AAD)),
            onPressed: () {
              // Notifications functionality
            },
          ),
        ],
      ),
      drawer: SMDrawer(selectedItem: 'My Projects'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button and edit icon
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Task Details',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Parent story name
            Padding(
              padding: const EdgeInsets.only(left: 32, bottom: 16),
              child: Text(
                "User Story: ${widget.task['storyTitle'] ?? ''}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),

            // Task Title Card (always at the top)
            _buildCard(
              icon: Icons.assignment,
              title: 'Task Title',
              content: widget.task['title'] ?? '',
            ),

            // If in sprint, show status and assigned members near the top
            if (widget.storyStatus == 'In Sprint') ...[
              // Read-only Task Status at the top
              _buildReadOnlyStatusSection(),

              // Assigned Team Members at the top
              _buildAssignedMembersSection(),
            ],

            // What Card
            _buildCard(
              icon: Icons.description,
              title: 'What',
              content: widget.task['what'] ?? '',
            ),

            // Why Card
            _buildCard(
              icon: Icons.help_outline,
              title: 'Why',
              content: widget.task['why'] ?? '',
            ),

            // How Card
            _buildCard(
              icon: Icons.settings,
              title: 'How',
              content: widget.task['how'] ?? '',
            ),

            // Acceptance Criteria Card
            _buildCard(
              icon: Icons.checklist,
              title: 'Acceptance Criteria',
              content: widget.task['acceptanceCriteria'] ?? '',
            ),

            // Priority Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                color: Color(0xFFFDFDFD),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flag,
                        color: Color(0xFF004AAD),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Due Date Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                color: Color(0xFFFDFDFD),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: Color(0xFF004AAD),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      Text(
                        widget.task['dueDate'] ?? 'Not set',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Attachments Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Card(
                color: Color(0xFFFDFDFD),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.attach_file,
                        color: Color(0xFF004AAD),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Attachments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'No attachments',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // If NOT in sprint, show status and assigned members at the bottom (original position)
            if (widget.storyStatus != 'In Sprint') ...[
              // Assigned Team Members at the bottom
              _buildAssignedMembersSection(),

              // Read-only Task Status at the bottom
              _buildReadOnlyStatusSection(),
            ],

            SizedBox(height: 100), // Bottom padding for scroll
          ],
        ),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Common card builder
  Widget _buildCard({required IconData icon, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        color: Color(0xFFFDFDFD),
        elevation: 0,
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
                  Icon(
                    icon,
                    color: Color(0xFF004AAD),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedMembersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        color: Color(0xFFFDFDFD),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, color: Color(0xFF004AAD), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Assigned Team Members',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: _showTeamMemberSelectionDialog,
                    child: Text(
                      _assignedMembers.isEmpty ? 'Assign' : 'Edit',
                      style: TextStyle(
                        color: Color(0xFF004AAD),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (_assignedMembers.isEmpty)
                Text(
                  'No members assigned yet',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Column(
                  children: _assignedMembers.map((member) {
                    // Check if this is a sub-team
                    final bool isSubTeam = member.containsKey('members') && member['members'] is List;

                    if (isSubTeam) {
                      // Display sub-team
                      final subTeamMembers = member['members'] as List;
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF004AAD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF004AAD).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.group, color: Color(0xFF004AAD), size: 16),
                                SizedBox(width: 4),
                                Text(
                                  member['name'] ?? 'Sub-Team',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF004AAD),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            ...subTeamMembers.map((subMember) => Padding(
                              padding: EdgeInsets.only(left: 20, top: 2),
                              child: Text(
                                '• ${subMember['name'] ?? 'Member'}',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                            )).toList(),
                          ],
                        ),
                      );
                    } else {
                      // Display individual member
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF004AAD),
                              child: Text(
                                (member['name'] ?? 'U').substring(0, 1).toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
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
                                    member['name'] ?? 'Member',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (member['email'] != null)
                                    Text(
                                      member['email'],
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Read-only Task Status Section
  Widget _buildReadOnlyStatusSection() {
    String currentStatus = widget.task['status'] ?? 'Not Started';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        color: Color(0xFFFDFDFD),
        elevation: 0,
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
                  Icon(
                    Icons.sync,
                    color: Color(0xFF004AAD),
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Task Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Display current status with color
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: _getStatusColor(currentStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentStatus,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Note about who can update status
              Center(
                child: Text(
                  'Note: Only the assigned team member can update the task status.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}