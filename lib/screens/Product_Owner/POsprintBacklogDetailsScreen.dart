import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/product_owner_drawer.dart';
import '../../widgets/team_member_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../services/sprint_service.dart';
import 'PO_sprint_task_details_screen.dart';

class POSprintBacklogDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> story;
  final String projectId;

  const POSprintBacklogDetailsScreen({
    Key? key,
    required this.story,
    required this.projectId,
  }) : super(key: key);

  @override
  _POSprintBacklogDetailsScreenState createState() =>
      _POSprintBacklogDetailsScreenState();
}

class _POSprintBacklogDetailsScreenState
    extends State<POSprintBacklogDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> tasks = [];
  bool _isLoading = true;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  @override
  void initState() {
    super.initState();

    // Ensure story has projectId
    if (widget.story['projectId'] == null) {
      widget.story['projectId'] = widget.projectId;
    }

    // Load full backlog item data with tasks
    _loadBacklogItemDetails();
  }

  Future<void> _loadBacklogItemDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get the sprint service
      final sprintService = Provider.of<SprintService>(context, listen: false);

      // Fetch the complete backlog item with tasks
      final fullBacklogItem = await sprintService.getBacklogItemDetails(
        widget.projectId,
        widget.story['id'],
      );

      // Check if tasks exist in the fetched data
      if (fullBacklogItem != null &&
          fullBacklogItem.containsKey('tasks') &&
          fullBacklogItem['tasks'] is List) {
        setState(() {
          tasks = List<Map<String, dynamic>>.from(fullBacklogItem['tasks']);
          _isLoading = false;
        });

        print('Loaded ${tasks.length} tasks for backlog item');
      } else {
        setState(() {
          tasks = [];
          _isLoading = false;
        });
        print('No tasks found for this backlog item');
      }
    } catch (e) {
      print('Error loading backlog item details: $e');
      setState(() {
        tasks = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading backlog item details')),
      );
    }
  }

  void _navigateToTaskDetails(Map<String, dynamic> task) {
    // Add backlogId to task if missing
    if (!task.containsKey('backlogId')) {
      task['backlogId'] = widget.story['id'];
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PoSprintTaskDetailsScreen(
          task: task,
          storyStatus: widget.story['status'] ?? 'In Sprint',
          projectId: widget.projectId,
        ),
      ),
    ).then((updatedTask) {
      if (updatedTask != null && updatedTask is Map<String, dynamic>) {
        setState(() {
          final taskIndex = tasks.indexWhere((t) => t['id'] == task['id']);
          if (taskIndex != -1) {
            tasks[taskIndex] = updatedTask;
          }
        });
      }
      _loadBacklogItemDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get priority color
    Color priorityColor;
    String priorityText = widget.story['priority'] ?? 'Medium';

    switch (priorityText) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      case 'Low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.orange;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "My Projects"),
      drawer: ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildUserStoryCard(priorityColor, priorityText),
          ),

          // Tasks section title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                Text(
                  '${tasks.length} tasks',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                ? Center(
              child: Text(
                'No tasks for this backlog item yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _buildTaskCard(task);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFDFDFD),
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF004AAD),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment), label: 'Projects',),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
  Widget _buildUserStoryCard(Color priorityColor, String priorityText) {
    return Container(
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
      child: IntrinsicHeight(  // Added this to make indicator line match content height
        child: Row(
          children: [
            // Vertical line on the left (blue) - now matches card height
            Container(
              width: 5,
              // Removed fixed height: 150
              decoration: const BoxDecoration(
                color: Color(0xFF004AAD),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Story details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User story title
                    Text(
                      widget.story['title'] ?? 'User Story',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Priority indicator
                    Row(
                      children: [
                        Text(
                          'Priority Indicator',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priorityText,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Description - now shows full text
                    Text(
                      'Description',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.story['description'] ?? 'No description',
                      style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      // Removed maxLines and overflow to show full description
                    ),
                    const SizedBox(height: 12),

                    // Due Date and story points
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF313131),
                                ),
                              ),
                              Text(
                                widget.story['dueDate'] ?? 'Date',
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Vertical line on the left
          Container(
            width: 5,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFF004AAD),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          // Task title
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Text(
                task['title'] ?? 'Task Title',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
            ),
          ),
          // Navigation arrow
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF004AAD),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _navigateToTaskDetails(task),
            ),
          ),
        ],
      ),
    );
  }
}
