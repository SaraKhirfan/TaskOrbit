import 'package:flutter/material.dart';
import '../../services/TeamMemberTaskService.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import 'package:provider/provider.dart';
import '../../widgets/team_member_drawer.dart';
import 'dart:math' show min;

class TeamMemberTaskDetailsScreen extends StatefulWidget {
  final String taskId;
  final String projectId;
  final String backlogId;

  const TeamMemberTaskDetailsScreen({
    Key? key,
    required this.taskId,
    required this.projectId,
    required this.backlogId,
  }) : super(key: key);


  @override
  _TeamMemberTaskDetailsScreenState createState() => _TeamMemberTaskDetailsScreenState();
}

class _TeamMemberTaskDetailsScreenState extends State<TeamMemberTaskDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  Map<String, dynamic>? task;
  String _selectedStatus = 'Not Started'; // Default status
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _error;
  List<Map<String, dynamic>> _assignedMembers = [];

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  @override
  void initState() {
    super.initState();
    _loadTaskData();
  }

  Future<void> _loadTaskData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get the task service
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);

      // Try to get task from the service
      final taskData = teamMemberTaskService.getTaskById(widget.taskId);

      if (taskData != null) {
        setState(() {
          task = taskData;
          _selectedStatus = taskData['status'] ?? 'Not Started';
          _isLoading = false;

          // Initialize assigned members if they exist
          if (task!.containsKey('assignedMembersData') && task!['assignedMembersData'] != null) {
            _assignedMembers = List<Map<String, dynamic>>.from(
              task!['assignedMembersData'],
            );
            print('Task Screen: Loaded ${_assignedMembers.length} assigned members from task');
          }
        });

        print('Loaded task: ${task!['title']} with status $_selectedStatus');
      } else {
        print('Task not found in service, will reload tasks');

        // If task not found, try to reload all tasks
        await teamMemberTaskService.loadTasks();

        // Check again
        final refreshedTask = teamMemberTaskService.getTaskById(widget.taskId);
        if (refreshedTask != null) {
          setState(() {
            task = refreshedTask;
            _selectedStatus = refreshedTask['status'] ?? 'Not Started';
            _isLoading = false;

            // Initialize assigned members if they exist
            if (task!.containsKey('assignedMembersData') && task!['assignedMembersData'] != null) {
              _assignedMembers = List<Map<String, dynamic>>.from(
                task!['assignedMembersData'],
              );
              print('Task Screen: Loaded ${_assignedMembers.length} assigned members from task');
            }
          });
          print('Loaded task after refresh: ${task!['title']} with status $_selectedStatus');
        } else {
          setState(() {
            // Create a minimal task structure to avoid null issues
            task = {
              'title': 'Task not found',
              'status': 'Not Started',
              'priority': 'Medium',
            };
            _isLoading = false;
          });
          print('Task still not found after refresh, using placeholder');
        }
      }
    } catch (e) {
      print('Error loading task: $e');
      setState(() {
        // Create a minimal task structure to avoid null issues
        task = {
          'title': 'Error loading task',
          'status': 'Not Started',
          'priority': 'Medium',
        };
        _error = 'Failed to load task: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      print('TeamMemberTaskDetailsScreen: Updating task ${widget.taskId} to status: $newStatus');

      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);

      // Use the simpler updateTask method instead
      await teamMemberTaskService.updateTask(widget.taskId, {
        'status': newStatus,
      });

      // Update local state immediately
      setState(() {
        _selectedStatus = newStatus;
        if (task != null) {
          task!['status'] = newStatus;
        }
      });

      print('TeamMemberTaskDetailsScreen: Status updated successfully to $newStatus');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $newStatus')),
      );

      // Reload the task data to ensure consistency
      await _loadTaskData();

    } catch (e) {
      print('TeamMemberTaskDetailsScreen: Error updating status: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
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

  // Build a card with icon, title and content
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
                content.isEmpty ? 'No $title information provided' : content,
                style: TextStyle(
                  fontSize: 14,
                  color: content.isEmpty ? Colors.black54 : Colors.black87,
                  fontStyle: content.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the status section that allows users to update status
  Widget _buildStatusSection() {
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
              // Status buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusButton('Not Started', Colors.grey),
                  _buildStatusButton('In Progress', Color(0xFF004AAD)),
                  _buildStatusButton('Done', Colors.green),
                ],
              ),
              SizedBox(height: 16),
              if (_isUpdating)
                Center(child: CircularProgressIndicator())
            ],
          ),
        ),
      ),
    );
  }

  // Build a status button with appropriate styling
  Widget _buildStatusButton(String status, Color color) {
    final isSelected = _selectedStatus.toLowerCase() == status.toLowerCase();
    return ElevatedButton(
      onPressed: _isUpdating ? null : () => _updateTaskStatus(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : Colors.grey.shade200,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(status),
    );
  }

  Widget _buildAssignedMembersSection() {
    // DEBUG: Print the assigned members structure
    print('=== ASSIGNED MEMBERS DEBUG ===');
    print('Total assigned members: ${_assignedMembers.length}');
    for (int i = 0; i < _assignedMembers.length; i++) {
      final member = _assignedMembers[i];
      print('Member $i: ${member.toString()}');
      if (member.containsKey('members')) {
        print('  - Has members array: ${member['members'].length} members');
        for (var subMember in member['members']) {
          print('    - Sub-member: ${subMember['name']} (${subMember['id']})');
        }
      } else {
        print('  - Individual member: ${member['name']} (${member['id']})');
      }
      if (member.containsKey('isIndividual')) {
        print('  - Is Individual flag: ${member['isIndividual']}');
      }
    }
    print('==============================');

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
                  ..._assignedMembers.map((member) {
                    // Check if this has members array (new structure)
                    final bool hasMembers = member.containsKey('members') && member['members'] is List;
                    final bool isIndividual = member.containsKey('isIndividual') && member['isIndividual'] == true;

                    if (hasMembers) {
                      // NEW STRUCTURE: Has members array
                      final List<dynamic> teamMembers = member['members'];

                      if (isIndividual) {
                        // Individual assignment (new structure)
                        final individualMember = teamMembers.first;
                        return _buildIndividualMemberCard(individualMember);
                      } else {
                        // Actual sub-team (new structure)
                        return _buildSubTeamCard(member, teamMembers);
                      }
                    } else {
                      // OLD STRUCTURE: Individual member without members array
                      // This handles backward compatibility
                      return _buildIndividualMemberCard(member);
                    }
                  }).toList(),
                ] else ...[
                  Center(
                    child: Text(
                      'No members assigned to this task yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildTeamStatusSection() {
    final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);
    final isSubTeam = teamMemberTaskService.isSubTeamTask(widget.taskId);

    if (!isSubTeam) return SizedBox.shrink();

    final memberStatuses = teamMemberTaskService.getTeamMemberStatuses(widget.taskId);
    final myStatus = teamMemberTaskService.getCurrentUserTaskStatus(widget.taskId);
    final overallStatus = task?['status'] ?? 'Not Started';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        color: Color(0xFFF8F9FA),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF004AAD), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Team Status Overview',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004AAD),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Status',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(myStatus).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getStatusColor(myStatus)),
                        ),
                        child: Text(
                          myStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(myStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Status',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(overallStatus).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getStatusColor(overallStatus)),
                        ),
                        child: Text(
                          overallStatus,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(overallStatus),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (memberStatuses.length > 1) ...[
                SizedBox(height: 8),
                Text(
                  'Team members must agree on status for task to change',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
// Helper method to build individual member card
    Widget _buildIndividualMemberCard(Map<String, dynamic> member) {
      return Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color(0xFFE8F4F8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFDDDDDD)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFF004AAD),
              child: Text(
                (member['name'] ?? 'U').substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member['name'] ?? 'Team Member',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF313131),
                    ),
                  ),
                  Text(
                    member['email'] ?? 'No email',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

// Helper method to build sub-team card
    Widget _buildSubTeamCard(Map<String, dynamic> subTeam, List<dynamic> teamMembers) {
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
                  subTeam['name'] ?? 'Sub-Team',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF004AAD),
                  ),
                ),
                Text(
                  ' (${teamMembers.length} members)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Show all sub-team members
            ...teamMembers.map((subMember) {
              return Padding(
                padding: EdgeInsets.only(left: 24, bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF004AAD).withOpacity(0.7),
                      child: Text(
                        (subMember['name'] ?? 'U').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subMember['name'] ?? 'Team Member',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF313131),
                            ),
                          ),
                          Text(
                            subMember['email'] ?? 'No email',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF0F4F7),
        key: _scaffoldKey,
        appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
        drawer: TeamMemberDrawer(selectedItem: 'Projects'),
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: TMBottomNav(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      );
    }

    // Always have a default task object to prevent null errors
    if (task == null) {
      task = {
        'title': 'Task not found',
        'status': 'Not Started',
        'priority': 'Medium',
      };
    }

    String priority = task!['priority'] ?? 'Medium';
    Color priorityColor = _getPriorityColor(priority);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F7), // Light blue background
      key: _scaffoldKey,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: TeamMemberDrawer(selectedItem: 'Projects'),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
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
                "User Story: ${task!['storyTitle'] ?? task!['backlogTitle'] ?? 'N/A'}",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
            ),

            // Task Title
            _buildCard(
              icon: Icons.assignment,
              title: 'Task Title',
              content: task!['title'] ?? '',
            ),
            // Status section
            _buildStatusSection(),
            _buildTeamStatusSection(),
            // Assigned members section
            _buildAssignedMembersSection(),

            // What section
            _buildCard(
              icon: Icons.description,
              title: 'What',
              content: task!['what'] ?? task!['description'] ?? '',
            ),

            // Why section
            _buildCard(
              icon: Icons.help_outline,
              title: 'Why',
              content: task!['why'] ?? '',
            ),

            // How section
            _buildCard(
              icon: Icons.settings,
              title: 'How',
              content: task!['how'] ?? '',
            ),

            // Acceptance Criteria section
            _buildCard(
              icon: Icons.checklist,
              title: 'Acceptance Criteria',
              content: task!['acceptanceCriteria'] ?? '',
            ),

            // Priority section
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
            // Due Date Section
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
                        task!['dueDate'] ?? 'No due date',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        task!.containsKey('attachments') && task!['attachments'] is List && (task!['attachments'] as List).isNotEmpty
                            ? '${(task!['attachments'] as List).length} attachment(s)'
                            : 'No attachments',
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
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}