import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Team_Member/team_member_task_details_screen.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import '../../services/TeamMemberTaskService.dart';

class TeamMemberAssignedTasksScreen extends StatefulWidget {
  const TeamMemberAssignedTasksScreen({Key? key}) : super(key: key);

  @override
  State<TeamMemberAssignedTasksScreen> createState() =>
      _TeamMemberAssignedTasksScreenState();
}

class _TeamMemberAssignedTasksScreenState extends State<TeamMemberAssignedTasksScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;
  String _selectedStatus = 'Not Started';

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  @override
  void initState() {
    super.initState();
    // Force a refresh of tasks when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(
          context, listen: false);
      teamMemberTaskService.loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context);
    final isLoading = teamMemberTaskService.isLoading;
    // DEBUG: Print all tasks and their statuses
    print("DEBUG: All tasks in TeamMemberTaskService:");
    for (var task in teamMemberTaskService.tasks) {
      print(
          "  - ${task['title']} (${task['id']}): Status = '${task['status']}'");
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Assigned Tasks"),
      drawer: TeamMemberDrawer(selectedItem: 'Assigned Tasks'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3EFFF)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Assigned Tasks",
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,),
              const SizedBox(height: 16),
              _buildStatusTabs(),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildTaskList(
                    context, teamMemberTaskService, _selectedStatus),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Modified _buildStatusTabs method for TeamMemberAssignedTasksScreen
  Widget _buildStatusTabs() {
    // These display names will be shown in the UI
    final List<Map<String, String>> statusTabs = [
      {'display': 'Not Started', 'value': 'Not Started'},
      {'display': 'In Progress', 'value': 'In Progress'},
      {'display': 'Done', 'value': 'Done'},
    ];

    return Row(
      children: statusTabs.map((tab) {
        final isSelected = _selectedStatus == tab['value'];
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isSelected
                    ? const Color(0xFF004AAD)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => setState(() => _selectedStatus = tab['value']!),
              child: Text(
                tab['display']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF004AAD),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTaskList(BuildContext context,
      TeamMemberTaskService teamMemberTaskService,
      String status,) {
    // Get tasks for this status
    List<Map<String, dynamic>> tasks = teamMemberTaskService.getTasksByStatus(
        status);

    if (tasks.isEmpty) {
      // Show debug info about all available tasks
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No $status tasks',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildTaskCard(task, index + 1);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int taskNumber) {
    Color borderColor = taskNumber == 1 ? const Color(0xFF004AAD) : Colors.grey;

    // Determine priority color
    Color priorityColor;
    Color priorityTextColor = Colors.white; // Add this line

    switch (task['priority'].toString().toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.blue;
    }

    // Get status color
    Color statusColor;
    final statusText = task['status'] ?? 'Not Started';

    switch (statusText.toLowerCase()) {
      case 'in progress':
        statusColor = Colors.blue;
        break;
      case 'done':
        statusColor = Colors.green;
        break;
      default: // Not Started, To Do, etc.
        statusColor = Colors.grey[400]!;
        break;
    }

    // Extract the task IDs
    final String taskId = task['id'] ?? '';
    final String projectId = task['projectId'] ?? '';
    final String backlogId = task['backlogId'] ?? '';

    void navigateToTaskDetails() {
      // For now, use MaterialPageRoute to bypass the route definition issue
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              TeamMemberTaskDetailsScreen(
                taskId: taskId,
                projectId: projectId,
                backlogId: backlogId,
              ),
        ),
      );
    }

    return Card(
      color: const Color(0xFFFDFDFD),
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colored border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: borderColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Task content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task title
                    Text(
                      task['title'] ?? 'Task $taskNumber',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    // Project name
                    Text(
                      task['project'] ?? 'Project Name',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 12),

                    // Priority row
                    Row(
                      children: [
                        const Text(
                          'Priority Indicator',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            task['priority'] ?? 'Medium',
                            style: TextStyle(
                              fontSize: 12,
                              color: priorityTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Due date and task status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Due date
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due Date',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              task['dueDate'] ?? 'No date',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        // Task status
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Task Status',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor, // Use statusColor here
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task['status'] ?? 'Not Started',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Forward button
            Container(
              margin: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF004AAD),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: navigateToTaskDetails,
              ),
            ),
          ],
        ),
      ),
    );
  }
}