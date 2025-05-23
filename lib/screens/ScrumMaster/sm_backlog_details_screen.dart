import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/ScrumMaster/sprint_selection_dialog.dart';
import '../../services/sprint_service.dart';
import 'sm_task_details_screen.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_bottom_nav.dart';

class SMBacklogDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> story;

  const SMBacklogDetailsScreen({Key? key, required this.story})
      : super(key: key);

  @override
  _SMBacklogDetailsScreenState createState() => _SMBacklogDetailsScreenState();
}

class _SMBacklogDetailsScreenState extends State<SMBacklogDetailsScreen> {
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
    // Debug story object

    if (widget.story['projectId'] == null) {
      // Get the original project data that was passed to this screen
      final routeArgs = ModalRoute.of(context)?.settings.arguments;

      if (routeArgs is Map<String, dynamic> && routeArgs.containsKey('id')) {
        // This is the projectId from the passed project
        final projectId = routeArgs['id'];
        print('Adding missing projectId to story: $projectId');

        // Update the story with the projectId
        widget.story['projectId'] = projectId;
      }
    }
  }

  Future<void> _moveToSprint() async {
    try {
      // Show sprint selection dialog
      final sprintId = await showDialog<String>(
        context: context,
        builder: (context) => SprintSelectionDialog(
          projectId: widget.story['projectId'],
        ),
      );

      // If no sprint was selected (dialog was cancelled)
      if (sprintId == null) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Moving to sprint...'), duration: Duration(seconds: 1)),
      );

      // Move backlog item to selected sprint
      final sprintService = Provider.of<SprintService>(context, listen: false);
      await sprintService.moveBacklogItemToSprint(
        widget.story['projectId'],
        widget.story['id'],
        sprintId,
      );

      // Get sprint details for success message
      final sprint = await sprintService.getSprint(
        widget.story['projectId'],
        sprintId,
      );

      // Update local story state
      setState(() {
        widget.story['status'] = 'In Sprint';
        widget.story['sprintId'] = sprintId;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Moved to Sprint: ${sprint != null ? sprint['name'] : 'Unknown'}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Return updated story when navigating back
      Navigator.pop(context, {
        ...widget.story,
        'status': 'In Sprint',
        'sprintId': sprintId,
      });
    } catch (e) {
      print('Error moving to sprint: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to move to sprint: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and Edit/Delete options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // User Story Card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vertical line
                    Container(
                      width: 4,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF004AAD),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.story['title'] ?? 'User Story',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Status
                          Row(
                            children: [
                              Text(
                                'Status: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(widget.story['status']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: _getStatusColor(widget.story['status']),
                                  ),
                                ),
                                child: Text(
                                  widget.story['status'] ?? 'Status',
                                  style: TextStyle(
                                    color: _getStatusColor(widget.story['status']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          // Priority
                          Row(
                            children: [
                              Text(
                                'Priority: ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(widget.story['priority']).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: _getPriorityColor(widget.story['priority']),
                                  ),
                                ),
                                child: Text(
                                  widget.story['priority'] ?? 'Priority',
                                  style: TextStyle(
                                    color: _getPriorityColor(widget.story['priority']),
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
              SizedBox(height: 16),

              // Description Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.story['description'] ?? 'No description provided',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Due Date and Estimated Effort - Row with two cards
              Row(
                children: [
                  // Due Date Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                color: Color(0xFF004AAD),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.story['dueDate'] ?? 'Not set',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Estimated Effort Card
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.access_time,
                                color: Color(0xFF004AAD),
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Estimated',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.story['estimatedEffort'] ?? 'Not set',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // Tasks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF004AAD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${(widget.story['tasks'] as List?)?.length ?? 0}',
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
              SizedBox(height: 8),
              Text(
                'You have to assign team members to these tasks',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),

              // Tasks List
              if ((widget.story['tasks'] as List?)?.isEmpty ?? true)
                Center(
                  child: Text(
                    'No tasks available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: (widget.story['tasks'] as List?)?.length ?? 0,
                  itemBuilder: (context, index) {
                    final task = Map<String, dynamic>.from(
                      (widget.story['tasks'] as List)[index],
                    );
                    return _buildTaskCard(task);
                  },
                ),

              SizedBox(height: 24),

              // Move to Sprint button (only show if status is 'Ready')
              if (widget.story['status'] == 'Ready')
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.arrow_forward),
                    label: Text('Move to Sprint'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004AAD),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () => _moveToSprint(),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Build task card with vertical blue line
  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Blue vertical line
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: Color(0xFF004AAD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Task content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.reorder, color: Colors.grey[400]),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task['title'] ?? 'Task Title',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    // Task status indicator
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFF004AAD).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task['status'] ?? 'To Do',
                        style: TextStyle(
                          color: Color(0xFF004AAD),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Navigate to task details
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final taskWithIds = Map<String, dynamic>.from(task);

                  // Ensure projectId is set
                  if (!taskWithIds.containsKey('projectId') || taskWithIds['projectId'] == null || taskWithIds['projectId'].isEmpty) {
                    print('Adding projectId ${widget.story['projectId']} to task before navigation');
                    taskWithIds['projectId'] = widget.story['projectId'];
                  }

                  // Ensure backlogId is set - this is what's missing!
                  if (!taskWithIds.containsKey('backlogId') || taskWithIds['backlogId'] == null || taskWithIds['backlogId'].isEmpty) {
                    print('Adding backlogId ${widget.story['id']} to task before navigation');
                    taskWithIds['backlogId'] = widget.story['id'];
                  }

                  // Also ensure the story title is included for reference
                  if (!taskWithIds.containsKey('storyTitle')) {
                    taskWithIds['storyTitle'] = widget.story['title'];
                  }

                  // Log the task data we're passing
                  print('Navigating to task details with:');
                  print('- projectId: ${taskWithIds['projectId']}');
                  print('- backlogId: ${taskWithIds['backlogId']}');
                  print('- taskId: ${taskWithIds['id']}');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SMTaskDetailsScreen(
                        task: taskWithIds,
                        storyStatus: widget.story['status'],
                        projectId: widget.story['projectId'] ?? '',
                      ),
                    ),
                  ).then((updatedTask) {
                    if (updatedTask != null && updatedTask is Map<String, dynamic>) {
                      // Update the task in the user story
                      setState(() {
                        final tasks = widget.story['tasks'] as List;
                        final taskIndex = tasks.indexWhere(
                              (t) => t['id'] == task['id'],
                        );
                        if (taskIndex != -1) {
                          tasks[taskIndex] = updatedTask;
                        }
                      });
                    }
                  });
                },
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: Container(
                  width: 44,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get priority color based on value
  Color _getPriorityColor(String? priority) {
    if (priority == null) return Colors.grey;

    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get status color based on value
  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;

    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'ready':
        return Colors.green;
      case 'in sprint':
        return Color(0xFF004AAD);
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}