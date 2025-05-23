import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_bottom_nav.dart';

class SMTeamMemberWorkloadDetailsScreen extends StatefulWidget {
  static const Color primaryColor = Color(0xFF004AAD);

  final Map<String, dynamic> memberData;

  const SMTeamMemberWorkloadDetailsScreen({
    Key? key,
    required this.memberData,
  }) : super(key: key);

  @override
  _SMTeamMemberWorkloadDetailsScreenState createState() => _SMTeamMemberWorkloadDetailsScreenState();
}

class _SMTeamMemberWorkloadDetailsScreenState extends State<SMTeamMemberWorkloadDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
  }


  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: const Color(0xFFFDFDFD),
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

  // Get color based on workload percentage
  Color _getWorkloadColor(int percentage) {
    if (percentage >= 80) return Colors.red;
    if (percentage >= 50) return Colors.orange;
    return Colors.green;
  }
  @override
  Widget build(BuildContext context) {
    final workloadPercentage = widget.memberData['workloadPercentage'] as int;
    final workloadColor = _getWorkloadColor(workloadPercentage);

    return Scaffold(
      backgroundColor: Colors.white,
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
            icon: const Icon(Icons.chat),
            color: const Color(0xFF004AAD),
            onPressed: () {
              // Open chat with team member
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: SMTeamMemberWorkloadDetailsScreen.primaryColor,
                        radius: 16,
                        child: Text(
                          widget.memberData['avatar'],
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text('Chat with ${widget.memberData['name']}'),
                    ],
                  ),
                  content: Container(
                    height: 200,
                    width: double.maxFinite,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Start a conversation with ${widget.memberData['name']}',
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.send, color: SMTeamMemberWorkloadDetailsScreen.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close'),
                    ),
                  ],
                ),
              );
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
      drawer: SMDrawer(selectedItem: 'Workload Monitoring'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button row below app bar
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Team Member Workload',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Member profile header
              _buildMemberHeader(),

              SizedBox(height: 24),

              // Task metrics
              _buildTaskMetrics(),

              SizedBox(height: 24),

              // Workload heatmap
              _buildWorkloadHeatmap(),

              SizedBox(height: 24),

              // Current tasks
              _buildCurrentTasks(),

              // Add padding at the bottom for better scrolling with the navigation bar
              SizedBox(height: 80),
            ],
          ),
        ),
      ),
      // Standard bottom navigation bar instead of bottomSheet
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
  Widget _buildMemberHeader() {
    final workloadPercentage = widget.memberData['workloadPercentage'] as int;
    final workloadColor = _getWorkloadColor(workloadPercentage);

    return Row(
      children: [
        // Avatar
        CircleAvatar(
          backgroundColor: SMTeamMemberWorkloadDetailsScreen.primaryColor,
          radius: 30,
          child: Text(
            widget.memberData['avatar'],
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        SizedBox(width: 16),
        // Name and role
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Name
                  Flexible(
                    child: Text(
                      widget.memberData['name'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Chat icon button
                  IconButton(
                    icon: Icon(
                      size: 32,
                      Icons.chat,
                      color: SMTeamMemberWorkloadDetailsScreen.primaryColor,
                    ),
                    onPressed: () {
                      // Open chat with team member
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            width: 300,
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Header with avatar and title
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: SMTeamMemberWorkloadDetailsScreen.primaryColor,
                                      radius: 16,
                                      child: Text(
                                        widget.memberData['avatar'],
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Chat with ${widget.memberData["name"]}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                // Chat message
                                Text(
                                  'Start a conversation with ${widget.memberData["name"]}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                SizedBox(height: 16),
                                // Message input
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                          child: TextField(
                                            decoration: InputDecoration(
                                              hintText: 'Type your message...',
                                              border: InputBorder.none,
                                              hintStyle: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Material(
                                        color: SMTeamMemberWorkloadDetailsScreen.primaryColor,
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(8),
                                          bottomRight: Radius.circular(8),
                                        ),
                                        child: InkWell(
                                          onTap: () {},
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Icon(
                                              Icons.send,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                // Close button
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                widget.memberData['role'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              // Workload indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: workloadColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: workloadColor),
                ),
                child: Text(
                  '$workloadPercentage% Workload',
                  style: TextStyle(
                    color: workloadColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskMetrics() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Workload',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTaskCounter(widget.memberData['totalTasks'].toString(), 'Total Tasks', Colors.amber),
              _buildTaskCounter(widget.memberData['notStarted'].toString(), 'Not Started', Colors.grey),
              _buildTaskCounter(widget.memberData['inProgress'].toString(), 'In Progress', Colors.blue),
              _buildTaskCounter(widget.memberData['done'].toString(), 'Done', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCounter(String count, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkloadHeatmap() {
    final dailyWorkload = List<int>.from(widget.memberData['dailyWorkload']);

    // Find the maximum value for scaling
    int maxWorkload = dailyWorkload.reduce((curr, next) => curr > next ? curr : next);
    maxWorkload = maxWorkload > 0 ? maxWorkload : 1; // Avoid division by zero

    // Calculate the height for each bar based on the maximum (25% to 100%)
    List<double> heightPercentages = dailyWorkload.map((load) {
      // Scale from 0.25 to 1.0 for better visibility of small values
      return load == 0 ? 0.0 : 0.25 + ((load / maxWorkload) * 0.75);
    }).toList();

    // Get day labels (S, M, T, W, T, F, S)
    List<String> dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    // Generate dates for the current week
    DateTime now = DateTime.now();
    // Find the start of the week (Sunday)
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    // Generate list of dates for the full week
    List<DateTime> weekDates = List.generate(7, (index) =>
        startOfWeek.add(Duration(days: index))
    );

    // Format dates as day/month
    List<String> dateLabels = weekDates.map((date) =>
    '${date.day}/${date.month}'
    ).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with filter dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Workload Heatmap',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              // Time filter dropdown
            ],
          ),
          SizedBox(height: 24),

          // Heatmap scale - Use the same colors as in Team Member workload screen
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Low',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Medium',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'High',
                      style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),

          // Y-axis labels and chart container
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-axis labels
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('100%', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  SizedBox(height: 20),
                  Text('75%', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  SizedBox(height: 20),
                  Text('50%', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  SizedBox(height: 20),
                  Text('25%', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  SizedBox(height: 20),
                  Text('0%', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
              SizedBox(width: 8),

              // Chart area
              Expanded(
                child: Container(
                  height: 150,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      // Color gradient based on workload value - using the same color scheme
                      Color barColor = Colors.grey[300]!;
                      if (dailyWorkload[index] > 0) {
                        final intensity = (dailyWorkload[index] / maxWorkload);
                        if (intensity < 0.33) {
                          barColor = Colors.green;
                        } else if (intensity < 0.66) {
                          barColor = Colors.orange;
                        } else {
                          barColor = Colors.red;
                        }
                      }

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Chart bar
                          Container(
                            width: 24,
                            height: dailyWorkload[index] > 0
                                ? heightPercentages[index] * 120
                                : 4,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 4),
                          // Day label
                          Text(
                            dayLabels[index],
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                          ),
                          // Date label (day/month)
                          Text(
                            dateLabels[index],
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),

          // Legend for number of tasks
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '* Bar height represents percentage of daily tasks',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTasks() {
    // Filter only in-progress tasks
    final currentTasks = (widget.memberData['currentTasks'] as List<dynamic>)
        .where((task) {
      final status = (task['status'] as String).toLowerCase();
      // Use the same status categorization logic as in TeamMemberTaskService
      return isStatusInProgress(status);
    })
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFDFD),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Tasks (In Progress)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          currentTasks.isEmpty
              ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: Text(
                'No tasks in progress',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
              : Column(
            children: currentTasks.map((task) {
              // Format date for display
              String formattedDate = 'No due date';
              if (task['dueDate'] != null) {
                try {
                  final dueDate = task['dueDate'] is Timestamp
                      ? (task['dueDate'] as Timestamp).toDate()
                      : DateTime.parse(task['dueDate'].toString());
                  formattedDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
                } catch (e) {
                  print('Error formatting date: $e');
                }
              }

              // Get priority color
              Color priorityColor = Colors.grey;
              final priority = (task['priority'] as String).toLowerCase();
              if (priority == 'high') {
                priorityColor = Colors.red;
              } else if (priority == 'medium') {
                priorityColor = Colors.orange;
              } else if (priority == 'low') {
                priorityColor = Colors.green;
              }

              return InkWell(
                onTap: () {
                  // Navigate to task details
                  // This requires access to NavigationService or similar navigation
                  // Implement with your app's navigation pattern
                },
                child: Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      // Left accent border
                      Container(
                        width: 4,
                        height: 90, // Increased height for content
                        decoration: BoxDecoration(
                          color: SMTeamMemberWorkloadDetailsScreen.primaryColor,
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
                              // Task title - removed maxLines and overflow
                              Text(
                                task['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              // Project and backlog info - removed maxLines and overflow
                              Text(
                                '${task['backlogTitle']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              // Priority and due date
                              Row(
                                children: [
                                  // Priority chip
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: priorityColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: priorityColor.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Priority:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          task['priority'] as String,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: priorityColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  // Status chip
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Status:',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          task['status'] as String,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Spacer(),
                                  // Due date
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                      SizedBox(width: 2),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 10,
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
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

// Helper method to determine if a task is in progress
  bool isStatusInProgress(String status) {
    final inProgressStatuses = ['in progress', 'doing', 'started', 'working', 'in-progress'];
    return inProgressStatuses.contains(status.toLowerCase().trim());
  }

  Widget _buildTaskItem(String title, String backlog, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      backlog,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 8),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: statusColor),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey,
          ),
        ],
      ),
    );
  }
}