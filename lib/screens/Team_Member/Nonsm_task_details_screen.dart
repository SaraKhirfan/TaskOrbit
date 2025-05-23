import 'package:flutter/material.dart';
import '../../services/TeamMemberTaskService.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import '../../services/project_service.dart';
import 'package:provider/provider.dart';
import '../../widgets/team_member_drawer.dart';
import '../ScrumMaster/TeamMemberSelectionDialog.dart';

class NonSMTaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String storyStatus;
  final String projectId;
  const NonSMTaskDetailsScreen({
    Key? key,
    required this.task,
    required this.storyStatus,
    required this.projectId,
  }) : super(key: key);
  @override
  _NonSMTaskDetailsScreenState createState() => _NonSMTaskDetailsScreenState();
}
class _NonSMTaskDetailsScreenState extends State<NonSMTaskDetailsScreen> {
  List<Map<String, dynamic>> _assignedMembers = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  @override
  void initState() {
    super.initState();
    // Debug for all parameters
    print('Task Screen: Initialized with:');
    print('- projectId: "${widget.projectId}"');
    print('- task data keys: ${widget.task.keys.toList()}');
    print('- full task data: ${widget.task}');
    print('- storyStatus: ${widget.storyStatus}');
    // Check for backlogId specifically
    if (!widget.task.containsKey('backlogId') || widget.task['backlogId'] == null || widget.task['backlogId'].toString().isEmpty) {
      print('Task Screen WARNING: task is missing backlogId!');
    }
    // Initialize assigned members from task if they exist
    if (widget.task.containsKey('assignedMembersData')) {
      _assignedMembers = List<Map<String, dynamic>>.from(
        widget.task['assignedMembersData'],
      );
      print('Task Screen: Loaded ${_assignedMembers.length} assigned members from task');
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
        return Colors.grey;
      case 'in progress':
        return Color(0xFF004AAD);
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
      backgroundColor: const Color(0xFFF0F4F7),
      key: _scaffoldKey,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: TeamMemberDrawer(selectedItem: 'Projects'),
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
            _buildCard(
              icon: Icons.assignment,
              title: 'Task Title',
              content: widget.task['title'] ?? '',
            ),
            if (widget.storyStatus == 'In Sprint') ...[
              _buildReadOnlyStatusSection(),
              _buildAssignedMembersSection(),
            ],
            _buildCard(
              icon: Icons.description,
              title: 'What',
              content: widget.task['what'] ?? '',
            ),
            _buildCard(
              icon: Icons.help_outline,
              title: 'Why',
              content: widget.task['why'] ?? '',
            ),
            _buildCard(
              icon: Icons.settings,
              title: 'How',
              content: widget.task['how'] ?? '',
            ),
            _buildCard(
              icon: Icons.checklist,
              title: 'Acceptance Criteria',
              content: widget.task['acceptanceCriteria'] ?? '',
            ),
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
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
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
                children: [
                  Icon(
                    Icons.group,
                    color: Color(0xFF004AAD),
                    size: 24,
                  ),
                  SizedBox(width: 12),
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
              SizedBox(height: 16),
              // Show assigned members if any
              if (_assignedMembers.isNotEmpty) ...[
                // Display individual members or sub-teams
                ..._assignedMembers.map((member) {
                  // Check if this is a sub-team (has members array)
                  final bool isSubTeam = member.containsKey('members') && member['members'] is List;
                  if (isSubTeam) {
                    // This is a sub-team
                    final List<dynamic> subTeamMembers = member['members'];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFEDF1F7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Color(0xFFDDDDDD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.group, color: Color(0xFF004AAD), size: 16),
                              SizedBox(width: 8),
                              Text(
                                member['name'] ?? 'Sub-Team',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004AAD),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          ...subTeamMembers.map<Widget>((subMember) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 24, bottom: 4),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Color(0xFF004AAD),
                                    child: Text(
                                      subMember['name']?.substring(0, 1).toUpperCase() ?? 'M',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    subMember['name'] ?? 'Member',
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF004AAD),
                            child: Text(
                              member['name']?.substring(0, 1).toUpperCase() ?? 'M',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            member['name'] ?? 'Member',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (member['role'] != null) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Color(0xFF004AAD).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                member['role'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF004AAD),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }
                }).toList(),
              ],
              // Otherwise show a message
              if (_assignedMembers.isEmpty)
                Text(
                  'No team members assigned yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

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