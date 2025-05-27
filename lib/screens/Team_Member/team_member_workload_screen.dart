// File: lib/screens/Team_Member/team_member_workload_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' show min;
import '../../services/TeamMemberTaskService.dart';
import '../../services/project_service.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import 'team_member_task_details_screen.dart';

class TeamMemberWorkloadScreen extends StatefulWidget {
  const TeamMemberWorkloadScreen({Key? key}) : super(key: key);

  @override
  State<TeamMemberWorkloadScreen> createState() => _TeamMemberWorkloadScreenState();
}

class _TeamMemberWorkloadScreenState extends State<TeamMemberWorkloadScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2;
  bool _isLoading = true;
  bool _dropdownOpen = false;
  String? _selectedProjectId;
  List<Map<String, dynamic>> _userProjects = [];
  bool _isProjectsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
  }

  Future<void> _loadUserProjects() async {
    setState(() {
      _isProjectsLoading = true;
    });

    final projectService = Provider.of<ProjectService>(context, listen: false);
    await projectService.refreshProjects();

    setState(() {
      _userProjects = projectService.projects;
      // Set default selected project if available
      if (_userProjects.isNotEmpty && _selectedProjectId == null) {
        _selectedProjectId = _userProjects[0]['id'];
      }
      _isProjectsLoading = false;
      _isLoading = false;
    });
  }

  void _refreshTasksForSelectedProject() {
    if (_selectedProjectId != null) {
      setState(() {
        _isLoading = true;
      });

      // Add a small delay to show loading state
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  void _showFlagWorkloadDialog(BuildContext context) {
    final TextEditingController explanationController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Color(0xFFFDFDFD),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dialog header
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.flag,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Flag Workload',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Text field for explanation
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: explanationController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Explain your flag raise....',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Send button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AAD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          // Process the flag workload submission
                          final explanation = explanationController.text.trim();
                          if (explanation.isNotEmpty) {
                            Navigator.pop(context); // Close dialog first

                            // Show loading indicator
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Text('Submitting flag...'),
                                  ],
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );

                            try {
                              // Send to backend
                              final taskService = Provider.of<TeamMemberTaskService>(context, listen: false);
                              await taskService.reportWorkloadIssue(
                                _selectedProjectId ?? '',
                                explanation,
                                '', // User ID will be fetched from current user in the service
                              );

                              // Show success
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Workload flag submitted successfully'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            } catch (e) {
                              // Show error
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error submitting flag: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          } else {
                            // Show an error if no explanation is provided
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please provide an explanation for flagging your workload'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'Send',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Simple status card widget
  Widget _buildStatusCard(String title, String count, Color iconColor, IconData icon) {
    return Container(
      width: 80,
      height: 90,
      decoration: BoxDecoration(
        color: Color(0xFF004AAD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: iconColor,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              color: iconColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  // Project selector dropdown
  Widget _buildProjectSelector() {
    return Container(
      margin: EdgeInsets.only(top: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Project',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          InkWell(
            onTap: () {
              setState(() {
                _dropdownOpen = !_dropdownOpen;
              });
            },
            child: Row(
              children: [
                Icon(Icons.folder_outlined, color: Color(0xFF004AAD), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isProjectsLoading
                        ? 'Loading...'
                        : _userProjects.isEmpty
                        ? 'No projects'
                        : _selectedProjectId == null
                        ? 'All Projects'
                        : _userProjects
                        .firstWhere(
                          (p) => p['id'] == _selectedProjectId,
                      orElse: () => {'name': 'Select Project'},
                    )['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  _dropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: Color(0xFF004AAD),
                ),
              ],
            ),
          ),
          if (_dropdownOpen)
            Container(
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Add 'All Projects' option
                  _buildProjectDropdownItem({
                    'id': null,
                    'name': 'All Projects',
                  }),
                  ...(_userProjects.map((project) {
                    return _buildProjectDropdownItem(project);
                  }).toList()),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectDropdownItem(Map<String, dynamic> project) {
    final projectId = project['id'];

    return InkWell(
      onTap: () {
        setState(() {
          _selectedProjectId = projectId;
          _dropdownOpen = false;
          _refreshTasksForSelectedProject();
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Text(
          project['name'] ?? 'Unnamed Project',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _selectedProjectId == projectId
                ? const Color(0xFF004AAD)
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  Map<String, int> _getTaskCountsByDay(List<Map<String, dynamic>> tasks) {
    print("DEBUG: _getTaskCountsByDay called with ${tasks.length} tasks");

    // Create a map to store counts for each day
    Map<String, int> dayCounts = {
      'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0, 'Fri': 0, 'Sat': 0, 'Sun': 0
    };

    // Process each task
    for (var task in tasks) {
      print("DEBUG: Processing task: ${task['title']}, dueDate: ${task['dueDate']}");

      // Skip tasks without due dates
      if (task['dueDate'] == null || task['dueDate'] == 'No date' || task['dueDate'] == 'null') {
        print("DEBUG: Skipping task with no due date");
        continue;
      }

      try {
        // Parse the due date (format: dd-MM-yyyy)
        List<String> dateParts = task['dueDate'].split('-');
        DateTime dueDate = DateTime(
            int.parse(dateParts[2]),  // Year
            int.parse(dateParts[1]),  // Month
            int.parse(dateParts[0])   // Day
        );

        print("DEBUG: Parsed date: $dueDate");

        // Get day of week
        String day;
        switch (dueDate.weekday) {
          case 1: day = 'Mon'; break;
          case 2: day = 'Tue'; break;
          case 3: day = 'Wed'; break;
          case 4: day = 'Thu'; break;
          case 5: day = 'Fri'; break;
          case 6: day = 'Sat'; break;
          case 7: day = 'Sun'; break;
          default: day = 'Mon';
        }

        // Increment the count for this day
        dayCounts[day] = (dayCounts[day] ?? 0) + 1;
        print("DEBUG: Added to $day, new count: ${dayCounts[day]}");

      } catch (e) {
        print('Error parsing date: ${task['dueDate']} - $e');
      }
    }

    print("DEBUG: Final day counts: $dayCounts");
    return dayCounts;
  }

  // Simple heatmap bar widget
  Widget _buildHeatmapBar(String day, double height, Color color, int taskCount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (height > 0)
          Container(
            width: 30,
            height: 140 * height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: taskCount > 0 ? Text(
              '$taskCount',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ) : null,
          )
        else
          Container(
            width: 30,
            height: 2,
            color: Colors.grey[300],
          ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Get color based on workload intensity
  Color _getHeatmapColor(double value) {
    if (value <= 0.3) {
      return Colors.green;
    } else if (value <= 0.7) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get upcoming task based on due date and priority
  Map<String, dynamic>? _getUpcomingTask(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) return null;

    // Filter tasks to only include Not Started and In Progress tasks
    final activeTasks = tasks.where((task) {
      final status = task['status']?.toString().toLowerCase() ?? '';
      return status == 'not started' || status == 'in progress' ||
          status == 'to do' || status == 'doing';
    }).toList();

    if (activeTasks.isEmpty) return null;

    // Filter out tasks without due dates
    final tasksWithDates = activeTasks.where((task) =>
    task['dueDate'] != null && task['dueDate'] != 'No date').toList();

    if (tasksWithDates.isEmpty) {
      // If no tasks with dates, sort by priority and return highest priority
      activeTasks.sort((a, b) {
        final Map<String, int> priorityValues = {
          'high': 3,
          'medium': 2,
          'low': 1,
        };

        final aPriority = priorityValues[a['priority']?.toString().toLowerCase() ?? 'medium'] ?? 2;
        final bPriority = priorityValues[b['priority']?.toString().toLowerCase() ?? 'medium'] ?? 2;

        return bPriority.compareTo(aPriority); // Higher priority first
      });

      return activeTasks.first;
    }

    // Current date
    final now = DateTime.now();

    // Sort tasks with due dates: Overdue first, then by closest due date
    tasksWithDates.sort((a, b) {
      try {
        // Parse due dates
        List<String> aDateParts = a['dueDate'].split('-');
        List<String> bDateParts = b['dueDate'].split('-');

        DateTime aDate = DateTime(
            int.parse(aDateParts[2]),  // Year
            int.parse(aDateParts[1]),  // Month
            int.parse(aDateParts[0])   // Day
        );

        DateTime bDate = DateTime(
            int.parse(bDateParts[2]),  // Year
            int.parse(bDateParts[1]),  // Month
            int.parse(bDateParts[0])   // Day
        );

        // Check if tasks are overdue
        bool aOverdue = aDate.isBefore(now);
        bool bOverdue = bDate.isBefore(now);

        // If both or neither overdue, sort by closest date
        if (aOverdue == bOverdue) {
          return aDate.compareTo(bDate);
        }

        // Overdue tasks come first
        return aOverdue ? -1 : 1;
      } catch (e) {
        print('Error comparing dates: $e');
        return 0;
      }
    });

    return tasksWithDates.first;
  }

  // Build task card
  Widget _buildTaskCard(Map<String, dynamic> task) {
    // Extract task details
    final title = task['title'] ?? 'Untitled Task';
    final dueDate = task['dueDate'] ?? 'No due date';
    final status = task['status'] ?? 'Not Started';
    final backlog = task['backlogTitle'] ?? 'Unknown Backlog';
    final project = task['project'] ?? 'Unknown Project';

    // Determine status color
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'in progress':
        statusColor = Colors.blue[700]!;
        break;
      case 'done':
        statusColor = Colors.green[700]!;
        break;
      default: // Not Started
        statusColor = Colors.orange[700]!;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            project,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                dueDate,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 16),
              Icon(Icons.storage, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  backlog,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigate to task details
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TeamMemberTaskDetailsScreen(
                        taskId: task['id'] ?? '',
                        projectId: task['projectId'] ?? '',
                        backlogId: task['backlogId'] ?? '',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004AAD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the task service
    final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context);

    // Get all tasks
    final allTasks = teamMemberTaskService.tasks;

    // Filter by project if a project is selected
    final List<Map<String, dynamic>> tasks = _selectedProjectId == null
        ? allTasks
        : allTasks.where((task) => task['projectId'] == _selectedProjectId).toList();

    // Count tasks by status
    final int totalTasks = tasks.length;
    final int notStartedTasks = tasks.where((task) {
      final status = task['status']?.toString().toLowerCase() ?? '';
      return status == 'not started' || status == 'to do' || status == 'todo' || status == 'open';
    }).length;

    final int inProgressTasks = tasks.where((task) {
      final status = task['status']?.toString().toLowerCase() ?? '';
      return status == 'in progress' || status == 'doing' || status == 'started';
    }).length;

    final int doneTasks = tasks.where((task) {
      final status = task['status']?.toString().toLowerCase() ?? '';
      return status == 'done' || status == 'completed' || status == 'finished';
    }).length;

    // Get tasks counts by day
    final Map<String, int> taskCounts = _getTaskCountsByDay(tasks);

    // Define max tasks per day
    const int MAX_TASKS_PER_DAY = 5;

    // Calculate normalized heights and colors
    Map<String, double> heightValues = {};
    Map<String, Color> barColors = {};

    taskCounts.forEach((day, count) {
      // Normalize height (0.0 to 1.0)
      double height = min(count / MAX_TASKS_PER_DAY, 1.0);
      heightValues[day] = height;

      // Determine color based on workload
      barColors[day] = _getHeatmapColor(height);
    });

    // Get upcoming task
    final upcomingTask = _getUpcomingTask(tasks);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: SMAppBar(
        scaffoldKey: _scaffoldKey,
        title: 'My Workload',
      ),
      drawer: TeamMemberDrawer(selectedItem: 'My Workload'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
            child: Text('My Workload', style: TextStyle(fontWeight: FontWeight.bold),),
            ),
            // Status cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatusCard(
                    'Total Tasks',
                    totalTasks.toString(),
                    Colors.white,
                    Icons.view_list_sharp,
                  ),
                  _buildStatusCard(
                    'Not Started',
                    notStartedTasks.toString(),
                    Colors.white,
                    Icons.do_not_disturb_on,
                  ),
                  _buildStatusCard(
                    'In Progress',
                    inProgressTasks.toString(),
                    Colors.white,
                    Icons.hourglass_bottom_rounded,
                  ),
                  _buildStatusCard(
                    'Done',
                    doneTasks.toString(),
                    Colors.white,
                    Icons.check_circle,
                  ),
                ],
              ),
            ),

            // Project selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProjectSelector(),
            ),

            // Workload heatmap section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Workload Heatmap',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.flag,
                      color: Colors.red[400],
                    ),
                    onPressed: () => _showFlagWorkloadDialog(context),
                    tooltip: 'Flag Workload',
                  ),
                ],
              ),
            ),

            // Heatmap
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildHeatmapBar('Mon', heightValues['Mon'] ?? 0.0, barColors['Mon'] ?? Colors.grey[300]!, taskCounts['Mon'] ?? 0),
                  _buildHeatmapBar('Tue', heightValues['Tue'] ?? 0.0, barColors['Tue'] ?? Colors.grey[300]!, taskCounts['Tue'] ?? 0),
                  _buildHeatmapBar('Wed', heightValues['Wed'] ?? 0.0, barColors['Wed'] ?? Colors.grey[300]!, taskCounts['Wed'] ?? 0),
                  _buildHeatmapBar('Thu', heightValues['Thu'] ?? 0.0, barColors['Thu'] ?? Colors.grey[300]!, taskCounts['Thu'] ?? 0),
                  _buildHeatmapBar('Fri', heightValues['Fri'] ?? 0.0, barColors['Fri'] ?? Colors.grey[300]!, taskCounts['Fri'] ?? 0),
                  _buildHeatmapBar('Sat', heightValues['Sat'] ?? 0.0, barColors['Sat'] ?? Colors.grey[300]!, taskCounts['Sat'] ?? 0),
                  _buildHeatmapBar('Sun', heightValues['Sun'] ?? 0.0, barColors['Sun'] ?? Colors.grey[300]!, taskCounts['Sun'] ?? 0),
                ],
              ),
            ),

            // Upcoming task section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Nearest Deadline Task',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Upcoming task card
            Padding(
              padding: const EdgeInsets.all(16),
              child: upcomingTask != null
                  ? _buildTaskCard(upcomingTask)
                  : Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  'No upcoming tasks',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
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