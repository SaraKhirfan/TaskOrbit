// File: lib/screens/ScrumMaster/sm_all_tasks_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:task_orbit/services/TeamMemberTaskService.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:task_orbit/widgets/sm_drawer.dart';
import 'sm_task_details_screen.dart';

class SMAllTasksManagementScreen extends StatefulWidget {
  const SMAllTasksManagementScreen({Key? key}) : super(key: key);

  static const Color primaryColor = Color(0xFF004AAD);

  @override
  State<SMAllTasksManagementScreen> createState() => _SMAllTasksManagementScreenState();
}

class _SMAllTasksManagementScreenState extends State<SMAllTasksManagementScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _allTasks = [];
  bool _isLoading = false;
  late TabController _tabController;
  String _selectedTeamMember = 'All';
  List<String> _teamMembers = ['All'];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  String? _selectedProject = 'All';
  List<String> _projects = ['All'];
  Map<String, String> _projectNames = {};
  Map<String, List<String>> _teamMemberIds = {}; // Added for member name to ID mapping

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTeamMembers();
    _loadProjects();

    // Load tasks after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllTasks() {
    setState(() {
      _isLoading = true; // Start loading
    });

    final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);

    // Call the new method to load ALL tasks, not just assigned ones
    print('Loading ALL project tasks for Scrum Master');

    // Load ALL tasks, not just assigned ones
    teamMemberTaskService.loadAllProjectTasks().then((_) {
      final allTasksCount = teamMemberTaskService.getAllProjectTasks().length;
      print('Tasks loaded: $allTasksCount total tasks');

      // Debug: print first few task titles if any exist
      if (allTasksCount > 0) {
        final tasks = teamMemberTaskService.getAllProjectTasks();
        print('First 3 task titles: ${tasks.take(3).map((t) => t['title'] ?? 'No title').join(', ')}');
      } else {
        print('No tasks were loaded from the service');
      }

      // Force a UI refresh
      setState(() {
        _isLoading = false; // End loading
      });
    }).catchError((error) {
      print('Error loading tasks: $error');

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load tasks: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      setState(() {
        _isLoading = false; // End loading on error
      });
    });
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

  void _loadTeamMembers() async {
    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      // Get team members across all projects
      final allMembers = await projectService.getAllTeamMembers();

      setState(() {
        _teamMembers = ['All'];
        _teamMemberIds = {'All': []};

        for (var member in allMembers) {
          if (member['name'] != null && member['id'] != null) {
            final name = member['name'] as String;
            final id = member['id'] as String;

            _teamMembers.add(name);

            // Store the mapping
            if (_teamMemberIds.containsKey(name)) {
              _teamMemberIds[name]!.add(id);
            } else {
              _teamMemberIds[name] = [id];
            }
          }
        }
      });
    } catch (e) {
      print('Error loading team members: $e');
      // Default fallback
      setState(() {
        _teamMembers = ['All'];
        _teamMemberIds = {'All': []};
      });
    }
  }

  void _loadProjects() async {
    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final projects = projectService.projects;

      setState(() {
        _projects = ['All'];
        _projectNames = {'All': 'All Projects'};

        for (var project in projects) {
          final projectId = project['id'] as String;
          _projects.add(projectId);
          _projectNames[projectId] = project['name'] as String;
        }
      });
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      appBar: SMAppBar(
        scaffoldKey: _scaffoldKey,
        title: "Task Management",
      ),
      drawer: SMDrawer(selectedItem: 'Task Management'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTaskList('To Do'),
                  _buildTaskList('In Progress'),
                  _buildTaskList('Done'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SMAllTasksManagementScreen.primaryColor,
        child: const Icon(Icons.refresh, color: Colors.white,),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Refreshing tasks...'))
          );
          _loadAllTasks();
        },
      ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Task Management',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage tasks across all projects',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(height: 16),

          // Project filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter by project:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final projectId = _projects[index];
                    final isSelected = projectId == _selectedProject;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedProject = projectId;
                          });
                        },
                        child: Chip(
                          label: Text(_projectNames[projectId] ?? projectId),
                          backgroundColor: isSelected
                              ? SMAllTasksManagementScreen.primaryColor
                              : Colors.grey[200],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: SMAllTasksManagementScreen.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: SMAllTasksManagementScreen.primaryColor,
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'To Do'),
          Tab(text: 'In Progress'),
          Tab(text: 'Done'),
        ],
      ),
    );
  }

  Widget _buildTaskList(String status) {
    return Consumer<TeamMemberTaskService>(
      builder: (context, teamMemberTaskService, child) {
        // Show loading indicator if tasks are being loaded
        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: SMAllTasksManagementScreen.primaryColor,
                ),
                SizedBox(height: 16),
                Text('Loading tasks...'),
              ],
            ),
          );
        }

        List<Map<String, dynamic>> allTasks = teamMemberTaskService.getAllProjectTasks();
        // Debug print all tasks
        print('All tasks (${allTasks.length}) for $status tab');

        // Filter tasks based on status
        var statusFilteredTasks = allTasks.where((task) {
          if (task['status'] == null) {
            print('Task is missing status: ${task['title'] ?? 'Unknown'}');
            return false;
          }

          final taskStatus = (task['status'] as String).toLowerCase();
          bool matches = false;

          if (status == 'To Do') {
            matches = teamMemberTaskService.isStatusNotStarted(taskStatus);
          } else if (status == 'In Progress') {
            matches = teamMemberTaskService.isStatusInProgress(taskStatus);
          } else if (status == 'Done') {
            matches = teamMemberTaskService.isStatusDone(taskStatus);
          }

          return matches;
        }).toList();

        print('After status filter for $status: ${statusFilteredTasks.length} tasks');

        // Apply project filter and search query
        var filteredTasks = statusFilteredTasks.where((task) {
          // Filter by project
          bool matchesProject = _selectedProject == 'All' ||
              (task['projectId'] != null && task['projectId'] == _selectedProject);

          // Filter by search query
          bool matchesSearch = _searchQuery.isEmpty ||
              (task['title'] != null &&
                  task['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()));

          return matchesProject && matchesSearch;
        }).toList();

        print('Final filtered tasks for $status tab: ${filteredTasks.length}');

        if (filteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No $status tasks found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh Tasks'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SMAllTasksManagementScreen.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    _loadAllTasks();
                  },
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];

            // Debug print task info
            print('Task at index $index - ID: ${task['id']}, Title: ${task['title']}');

            // Format date
            String formattedDate = 'No due date';
            if (task['dueDate'] != null) {
              try {
                DateTime dueDate;
                if (task['dueDate'] is DateTime) {
                  dueDate = task['dueDate'] as DateTime;
                } else {
                  dueDate = DateTime.parse(task['dueDate'].toString());
                }
                formattedDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';
              } catch (e) {
                print('Error formatting date: $e');
              }
            }

            // Get priority color
            Color priorityColor = Colors.grey;
            final priority = task['priority']?.toString().toLowerCase() ?? 'medium';
            if (priority == 'high') {
              priorityColor = Colors.red;
            } else if (priority == 'medium') {
              priorityColor = Colors.orange;
            } else if (priority == 'low') {
              priorityColor = Colors.green;
            }

            return InkWell(
              onTap: () {
                // If task doesn't have storyStatus field, we need to determine it
                String storyStatus = 'Not In Sprint';
                if (task.containsKey('storyStatus') && task['storyStatus'] != null) {
                  storyStatus = task['storyStatus'] as String;
                } else if (task.containsKey('sprintId') && task['sprintId'] != null) {
                  // If task has a sprintId, it's likely in a sprint
                  storyStatus = 'In Sprint';
                }

                // Navigate to task details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SMTaskDetailsScreen(
                      task: task,  // Pass the entire task map
                      storyStatus: storyStatus,
                      projectId: task['projectId'] as String? ?? '',
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left accent border
                    Container(
                      width: 4,
                      height: 90,
                      decoration: BoxDecoration(
                        color: SMAllTasksManagementScreen.primaryColor,
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
                              task['title'] as String? ?? 'Untitled Task',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              softWrap: true,
                            ),
                            SizedBox(height: 4),
                            // Project and backlog info
                            Text(
                              '${_projectNames[task['projectId']] ?? 'Project'} - ${task['backlogTitle'] ?? 'Backlog'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              softWrap: true,
                            ),
                            SizedBox(height: 8),
                            // Task metadata in flexible layout
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
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
                                        task['priority'] as String? ?? 'Medium',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: priorityColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                                        task['status'] as String? ?? 'Unknown',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Due date
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.grey[400]!),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calendar_today, size: 10, color: Colors.grey[600]),
                                      SizedBox(width: 4),
                                      Text(
                                        formattedDate,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
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
          },
        );
      },
    );
  }
}