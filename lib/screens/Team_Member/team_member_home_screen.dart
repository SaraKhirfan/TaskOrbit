// File: lib/screens/Team_Member/team_member_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Team_Member/team_member_task_details_screen.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import '../../services/TodoService.dart';
import '../../services/TeamMemberTaskService.dart';

class TeamMemberHomeScreen extends StatefulWidget {
  const TeamMemberHomeScreen({Key? key, required String userRole}) : super(key: key);

  @override
  State<TeamMemberHomeScreen> createState() => _TeamMemberHomeScreenState();
}

class _TeamMemberHomeScreenState extends State<TeamMemberHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Force a refresh of tasks when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Load tasks from the TeamMemberTaskService
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(
          context, listen: false);
      teamMemberTaskService.loadTasks();
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  @override
  Widget build(BuildContext context) {
    final taskService = Provider.of<TodoService>(context);
    final todoItems = taskService.getTodosForHomeView();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Home"),
      drawer: const TeamMemberDrawer(selectedItem: 'Home'),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/HomeProductOwner.png'),
              fit: BoxFit.cover,
            ),
          ),
          // Use a Column with Expanded to fill the screen
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // To-Do section
                        _buildSectionHeader('Your To-do', 'See all'),
                        const SizedBox(height: 12),
                        _buildTodoSection(context, todoItems),

                        const SizedBox(height: 24),

                        // Workload section
                        _buildSectionHeader('Today\'s Workload', 'View'),
                        const SizedBox(height: 12),
                        _buildWorkloadIndicator(),

                        const SizedBox(height: 24),

                        // Assigned Tasks section
                        _buildSectionHeader('Your Assigned Tasks', 'See all'),
                        const SizedBox(height: 12),
                        _buildAssignedTasksList(context),

                        // Spacer to ensure content pushes down
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
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

  Widget _buildSectionHeader(String title, String actionText) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        TextButton(
          onPressed: () {
            if (title == 'Your To-do') {
              Navigator.pushReplacementNamed(context, '/tmMyTodo');
            } else if (title == 'Today\'s Workload') {
              Navigator.pushReplacementNamed(context, '/teamMemberWorkload');
            } else if (title == 'Your Assigned Tasks') {
              Navigator.pushReplacementNamed(
                  context, '/teamMemberAssignedTasks');
            }
          },
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF004AAD),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildWorkloadIndicator() {
    // Get the task service
    final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context);

    // Get real workload percentage
    final workloadPercentage = teamMemberTaskService.getCurrentWorkloadPercentage();

    // Get status text
    final String workloadStatus = teamMemberTaskService.getWorkloadStatus(workloadPercentage);

    // Calculate the filled width based on percentage
    final double fillWidth = MediaQuery.of(context).size.width - 32; // Full width minus padding
    final double filledWidth = (workloadPercentage / 100) * fillWidth;

    // Define the color based on percentage for the status indicator
    Color statusColor;
    if (workloadPercentage <= 30) {
      statusColor = Colors.green;
    } else if (workloadPercentage <= 70) {
      double factor = (workloadPercentage - 30) / 40.0;
      statusColor = Color.lerp(Colors.green, Colors.orange, factor)!;
    } else {
      double factor = (workloadPercentage - 70) / 30.0;
      statusColor = Color.lerp(Colors.orange, Colors.red, factor)!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient progress bar with dynamic fill
        Container(
          width: double.infinity,
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.grey[200], // Background color
          ),
          child: Stack(
            children: [
              // Gradient fill that grows based on percentage
              Container(
                width: filledWidth,
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green,
                      Colors.green, // Green extends to 30%
                      Colors.orange, // Orange at 70%
                      Colors.red,
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0], // Adjusted stops
                  ),
                ),
              ),
            ],
          ),
        ),

        // Current workload item with percentage and status
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF004AAD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Current Workload: $workloadPercentage%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  workloadStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
// Helper method for workload color
  Color _getColorForPercentage(int percentage) {
    if (percentage <= 30) {
      // Green for 1-30%
      return Colors.green;
    } else if (percentage <= 70) {
      // Calculate a gradient from green to orange for 31-70%
      double factor = (percentage - 30) / 40.0; // Normalize to 0-1 range for 30-70%
      return Color.lerp(Colors.green, Colors.orange, factor)!;
    } else {
      // Calculate a gradient from orange to red for 71-100%
      double factor = (percentage - 70) / 30.0; // Normalize to 0-1 range for 70-100%
      return Color.lerp(Colors.orange, Colors.red, factor)!;
    }
  }

  Widget _buildTodoSection(BuildContext context,
      List<Map<String, dynamic>> todoItems) {
    // If no items, show placeholder
    if (todoItems.isEmpty) {
      return _buildEmptyTodoCard();
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: todoItems.length,
        itemBuilder: (context, index) {
          return _buildTodoCard(
            todoItems[index],
            index == 0 ? const Color(0xFF004AAD) : const Color(0xFFEDF1F3),
          );
        },
      ),
    );
  }

  Widget _buildEmptyTodoCard() {
    return Container(
      height: 180,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Text(
        'No to-do items for today',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTodoCard(Map<String, dynamic> todo, Color cardColor) {
    final isHighlighted = cardColor == const Color(0xFF004AAD);
    final textColor = isHighlighted ? Colors.white : Colors.black87;

    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.task_alt,
                color: textColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  todo['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Text(
              todo['description'],
              style: TextStyle(
                fontSize: 14,
                color: textColor.withOpacity(0.8),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Priority
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priority',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(todo['priority'], isHighlighted),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      todo['priority'],
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              // Deadline
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Deadline',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    todo['deadline'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 12,
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority, bool isHighlighted) {
    if (isHighlighted) {
      switch (priority.toLowerCase()) {
        case 'high':
          return Colors.red[400]!;
        case 'medium':
          return Colors.orange[400]!;
        case 'low':
          return Colors.green[400]!;
        default:
          return Colors.blue[400]!;
      }
    } else {
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
  }

  Widget _buildAssignedTasksList(BuildContext context) {
    // Get the task service
    final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context);

    // Check if tasks are loading
    if (teamMemberTaskService.isLoading) {
      return Center(
        child: CircularProgressIndicator( color: Color(0xFF004AAD),),
      );
    }

    // Get tasks with "Not Started" or "In Progress" status
    final notStartedTasks = teamMemberTaskService.getTasksByStatus(
        'Not Started');
    final inProgressTasks = teamMemberTaskService.getTasksByStatus(
        'In Progress');

    // Combine the tasks and sort them
    final List<Map<String, dynamic>> tasks = [
      ...notStartedTasks,
      ...inProgressTasks
    ];

    // If we have no tasks, show a placeholder
    if (tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No assigned tasks',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    // Sort tasks by priority (High first, then Medium, then Low)
    tasks.sort((a, b) {
      final Map<String, int> priorityValues = {
        'high': 3,
        'medium': 2,
        'low': 1,
      };

      final aPriority = priorityValues[a['priority']
          .toString()
          .toLowerCase()] ?? 0;
      final bPriority = priorityValues[b['priority']
          .toString()
          .toLowerCase()] ?? 0;

      // Sort by priority (high to low)
      return bPriority.compareTo(aPriority);
    });

    // Limit to 2 tasks for display
    final displayTasks = tasks.length > 2 ? tasks.sublist(0, 2) : tasks;

    return Column(
      children: displayTasks.map((task) => _buildRealTaskCard(task)).toList(),
    );
  }

  Widget _buildRealTaskCard(Map<String, dynamic> task) {
    // Determine priority color
    Color priorityColor;

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
          builder: (context) => TeamMemberTaskDetailsScreen(
            taskId: taskId,
            projectId: projectId,
            backlogId: backlogId,
          ),
        ),
      );
    }

    return InkWell(
      onTap: navigateToTaskDetails,
      child: Card(
        color: Colors.white,
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Blue vertical line on the left
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF004AAD),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),

              // Task content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task title
                      Text(
                        task['title'] ?? 'Untitled Task',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Project name
                      Text(
                        task['project'] ?? 'Unknown Project',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),

                      const SizedBox(height: 6),

                      // Priority section
                      Row(
                        children: [
                          // Priority label
                          Text(
                            "Priority:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Priority chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              task['priority'] ?? 'Medium',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // Bottom row with status and due date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Status section
                          Row(
                            children: [
                              // Status label
                              Text(
                                "Status:",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Status chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Due date section
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 12,
                                  color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                task['dueDate'] ?? 'No date',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
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
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF004AAD),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 16,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  onPressed: navigateToTaskDetails,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}