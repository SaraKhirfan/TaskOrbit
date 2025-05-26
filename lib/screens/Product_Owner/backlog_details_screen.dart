import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Product_Owner/BacklogTaskDetailsScreen.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:task_orbit/services/AuthService.dart';
import 'package:intl/intl.dart';
import '../../widgets/product_owner_drawer.dart';
import 'AddBacklogTasksScreen.dart';

class BacklogDetailsScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> story;

  const BacklogDetailsScreen({
    super.key,
    required this.projectId,
    required this.story
  });

  @override
  State<BacklogDetailsScreen> createState() => _BacklogDetailsScreenState();
}

class _BacklogDetailsScreenState extends State<BacklogDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  late List<Map<String, dynamic>> _tasks = [];
  bool get _isReady => widget.story['status'] == 'Ready';
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadBacklogTasks();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserProfile();

      if (userData != null && mounted) {
        setState(() {
          _userName = userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Load backlog tasks from Firebase
  Future<void> _loadBacklogTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final tasks = await projectService.getBacklogTasks(
          widget.projectId,
          widget.story['id']
      );

      if (mounted) {
        setState(() {
          _tasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading backlog tasks: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
// In BacklogDetailsScreen, add a method to mark the story as Ready
  Future<void> _markAsReady() async {
    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);

      // Update the backlog item status to 'Ready'
      final success = await projectService.updateBacklogItem(
          widget.projectId,
          widget.story['id'],
          {'status': 'Ready'}
      );

      if (success && mounted) {
        // Update local state
        setState(() {
          widget.story['status'] = 'Ready';
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Backlog item marked as Ready'),
            backgroundColor: Color(0xFF004AAD),
          ),
        );

        // Return to previous screen with updated story
        Navigator.pop(context, widget.story);
      }
    } catch (e) {
      print('Error marking backlog as ready: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking backlog as ready: $e')),
      );
    }
  }
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  Future<void> _addTask() async {
    // Navigate to AddTaskScreen instead of showing dialog
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          storyTitle: widget.story['title'] ?? 'User Story',
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      try {
        final projectService = Provider.of<ProjectService>(context, listen: false);
        final addedTask = await projectService.addBacklogTask(
            widget.projectId,
            widget.story['id'],
            result
        );

        if (addedTask != null && mounted) {
          setState(() {
            _tasks.add(addedTask);
          });
        }
      } catch (e) {
        print('Error adding backlog task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding task: $e')),
        );
      }
    }
  }

  // Edit user story method
  void _editBacklog() async {
    // Show dialog to edit user story fields
    showDialog(
      context: context,
      builder: (context) => EditUBacklogDialog(
        story: widget.story,
      ),
    ).then((result) async {
      if (result != null && result is Map<String, dynamic>) {
        try {
          final projectService = Provider.of<ProjectService>(context, listen: false);

          // Update in Firestore
          final success = await projectService.updateBacklogItem(
              widget.projectId,
              widget.story['id'],
              result
          );

          if (success && mounted) {
            setState(() {
              // Update the story object with edited values
              widget.story.forEach((key, value) {
                if (result.containsKey(key)) {
                  widget.story[key] = result[key];
                }
              });
            });
          }
        } catch (e) {
          print('Error updating backlog item: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating user story: $e')),
          );
        }
      }
    });
  }

  // Delete user story method
  void _deleteBacklog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFFAFAFA),
        title: const Text('Delete User Story'),
        content: Text('Are you sure you want to delete "${widget.story['title']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              try {
                final projectService = Provider.of<ProjectService>(context, listen: false);
                final success = await projectService.deleteBacklogItem(
                    widget.projectId,
                    widget.story['id']
                );

                if (success) {
                  // Return to previous screen with delete flag
                  Navigator.pop(context, {'delete': true});
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete user story')),
                  );
                }
              } catch (e) {
                print('Error deleting backlog item: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting user story: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFF004AAD)),),
          ),
        ],
      ),
    );
  }

  // Navigate to task details screen
  void _navigateToTaskDetails(int index) async {
    final task = _tasks[index];

    // Navigate to task details screen and wait for result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BacklogTaskDetailsScreen(
          task: task,
          storyTitle: widget.story['title'] ?? 'User Story',
          isReadOnly: _isReady, // Pass readOnly flag if story is in Ready status
        ),
      ),
    );

    // Update task if edited (only if not in Ready state)
    if (!_isReady && result != null && result is Map<String, dynamic>) {
      try {
        final projectService = Provider.of<ProjectService>(context, listen: false);

        if (result.containsKey('delete') && result['delete'] == true) {
          // Delete task from Firestore
          final success = await projectService.deleteBacklogTask(
              widget.projectId,
              widget.story['id'],
              task['id']
          );

          if (success && mounted) {
            setState(() {
              // Delete task from local list
              _tasks.removeAt(index);
            });
          }
        } else {
          // Update task in Firestore
          final success = await projectService.updateBacklogTask(
              widget.projectId,
              widget.story['id'],
              task['id'],
              result
          );

          if (success && mounted) {
            setState(() {
              // Update task in local list
              _tasks[index] = result;
            });
          }
        }
      } catch (e) {
        print('Error updating backlog task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: MyProjectsScreen.primaryColor,
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat),
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BacklogItem.png'),
            fit: BoxFit.cover,
          ),
        ),
        // Use ClipRect to prevent any overflow
        child: ClipRect(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button and Actions Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                      onPressed: () => Navigator.pop(context, widget.story),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 24,
                    ),
                    Row(
                      children: [
                        // Edit button
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF004AAD)),
                          onPressed: _editBacklog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 24,
                        ),
                        const SizedBox(width: 16),
                        // Delete button
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _deleteBacklog,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User Story Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: IntrinsicHeight(  // Use IntrinsicHeight to make the row children match heights
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left blue bar - now will stretch to match parent height
                        Container(
                          width: 4,
                          color: const Color(0xFF004AAD),
                          margin: const EdgeInsets.only(right: 16),
                        ),
                        // Content column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Story',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF313131),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.story['title'],
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Status: ',
                                    style: TextStyle(
                                      color: Color(0xFF313131),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  _buildStatusChip(widget.story['status'] ?? 'Draft'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text(
                                    'Priority: ',
                                    style: TextStyle(
                                      color: Color(0xFF313131),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  _buildPriorityChip(widget.story['priority'] ?? 'Medium'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Description Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.story['description'] ?? 'No description provided.',
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Meta Information (Due Date, Estimated Effort)
                Row(
                  children: [
                    // Due Date
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
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
                                Icon(Icons.calendar_today, size: 16, color: Color(0xFF004AAD)),
                                SizedBox(width: 4),
                                Text(
                                  'Due Date',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.story['dueDate']?.isNotEmpty == true
                                  ? widget.story['dueDate']
                                  : 'Not set',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Estimated Effort
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
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
                                Icon(Icons.timer, size: 16, color: Color(0xFF004AAD)),
                                SizedBox(width: 4),
                                Text(
                                  'Estimated',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.story['estimatedEffort']?.isEmpty == false
                                  ? widget.story['estimatedEffort'] + ' hours'
                                  : 'Not set',
                              style: const TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tasks Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Tasks',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF313131),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Color(0xFF004AAD).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_tasks.length}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF004AAD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Only show add button if not in Ready state
                          if (!_isReady)
                            IconButton(
                              icon: const Icon(Icons.add, color: Color(0xFF004AAD)),
                              onPressed: _addTask,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Tasks list
                      if (_isLoading)
                        Center(child: CircularProgressIndicator())
                      else if (_tasks.isEmpty)
                        Center(
                          child: Text(
                            'No tasks added yet',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(), // Disable scrolling inside ListView
                          itemCount: _tasks.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) => _buildTaskItem(index),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),


                if (widget.story['status'] == 'Draft' && _tasks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _markAsReady,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Mark as Ready',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildTaskItem(int index) {
    final task = _tasks[index];
    return InkWell(
      onTap: () => _navigateToTaskDetails(index),
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F9),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Task icon
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF004AAD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.checklist,
                color: Color(0xFF004AAD),
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task['title'] ?? 'Untitled Task',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                      fontSize: 14,
                    ),
                  ),
                  if (task['description']?.isNotEmpty == true)
                    Text(
                      task['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(task['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task['status'] ?? 'To Do',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(task['status']),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, bool isSelected) {
    return ElevatedButton(
      onPressed: () => _updateStatus(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF004AAD) : Colors.white,
        foregroundColor: isSelected ? Colors.white : const Color(0xFF313131),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
      ),
      child: Text(status),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    if (widget.story['status'] == newStatus) return;

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);

      // Update in Firestore
      final success = await projectService.updateBacklogItem(
          widget.projectId,
          widget.story['id'],
          {'status': newStatus}
      );

      if (success && mounted) {
        setState(() {
          widget.story['status'] = newStatus;
        });
      }
    } catch (e) {
      print('Error updating backlog status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Ready':
        color = Colors.green;
        break;
      case 'In Sprint':
        color = Colors.blue;
        break;
      case 'Draft':
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = Colors.red;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'In Progress':
        return Colors.orange;
      case 'Done':
        return Colors.green;
      case 'To Do':
      default:
        return Colors.blue;
    }
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFDFDFD),
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: MyProjectsScreen.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects',),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

// Edit Backlog Dialog
class EditUBacklogDialog extends StatefulWidget {
  final Map<String, dynamic> story;

  const EditUBacklogDialog({super.key, required this.story});

  @override
  State<EditUBacklogDialog> createState() => _EditUBacklogDialogState();
}

class _EditUBacklogDialogState extends State<EditUBacklogDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _estimatedEffortController;
  late String _priority;
  late DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story['title']);
    _descriptionController = TextEditingController(text: widget.story['description']);
    _estimatedEffortController = TextEditingController(text: widget.story['estimatedEffort']?.toString() ?? '');
    _priority = widget.story['priority'] ?? 'Medium';

    _dueDate = widget.story['dueDate']?.isNotEmpty == true
        ? DateFormat('yyyy-MM-dd').parse(widget.story['dueDate'])
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedEffortController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF313131),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _saveChanges() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final updatedStory = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'priority': _priority,
      'estimatedEffort': _estimatedEffortController.text,
      'dueDate': _dueDate != null ? DateFormat('yyyy-MM-dd').format(_dueDate!) : '',
    };

    Navigator.of(context).pop(updatedStory);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit User Story',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
            ),
            const SizedBox(height: 16),
            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            // Estimated effort field
            TextField(
              controller: _estimatedEffortController,
              decoration: InputDecoration(
                labelText: 'Estimated Effort (hours)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            // Priority selection
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Priority:'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildPriorityChoice('High'),
                    const SizedBox(width: 8),
                    _buildPriorityChoice('Medium'),
                    const SizedBox(width: 8),
                    _buildPriorityChoice('Low'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Due date field
            InkWell(
              onTap: _selectDueDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Due Date',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dueDate == null
                          ? 'Select a date'
                          : DateFormat('yyyy-MM-dd').format(_dueDate!),
                    ),
                    Icon(Icons.calendar_today, size: 16, color: Color(0xFF004AAD)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AAD),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChoice(String value) {
    final bool isSelected = _priority == value;

    Color color;
    switch (value) {
      case 'High':
        color = Colors.red;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: TextStyle(
              color: isSelected ? color : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}