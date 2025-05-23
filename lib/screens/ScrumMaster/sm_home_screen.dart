import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sm_project_details_screen.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:task_orbit/services/TodoService.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:task_orbit/widgets/sm_bottom_nav.dart';
import 'package:task_orbit/widgets/sm_drawer.dart';

class ScrumMasterHomeScreen extends StatefulWidget {
  final String userRole;
  const ScrumMasterHomeScreen({super.key, required this.userRole});

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE53935);
  static const Color shadowColor = Color(0x1A000000);

  @override
  State<ScrumMasterHomeScreen> createState() => _ScrumMasterHomeScreenState();
}

class _ScrumMasterHomeScreenState extends State<ScrumMasterHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; //  tab in bottom nav
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
  }

  static const Color primaryColor = Color(0xFF004AAD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Home"),
      drawer: SMDrawer(selectedItem: 'Home'),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/HomeProductOwner.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTasksSection(),
                const SizedBox(height: 30),
                _buildProjectsSection(),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 250),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildTasksSection() {
    return Consumer<TodoService>(
      builder: (context, taskService, child) {
        final tasks = taskService.getTodosForHomeView();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Tasks',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/smMyTasks');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: Color(0xFF004AAD),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 230,
              child:
              tasks.isEmpty
                  ? const Center(
                child: Text(
                  'No tasks available',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
                  : ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tasks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 15),
                itemBuilder:
                    (context, index) =>
                    _buildTaskCard(tasks[index], index),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task, int index) {
    final Color cardColor =
    index % 2 == 0 ? const Color(0xFF004AAD) : const Color(0xFFEDF1F3);
    final Color textColor =
    index % 2 == 0 ? const Color(0xFFFDFDFD) : const Color(0xFF313131);

    // Parse deadline date
    String deadlineText = "Date";
    if (task['deadline'] != null) {
      try {
        final deadline = DateTime.parse(task['deadline']);
        deadlineText = '${deadline.day}/${deadline.month}/${deadline.year}';
      } catch (e) {
        deadlineText = "Date";
      }
    }

    // Set priority background color
    Color priorityColor = Colors.orange; // Default
    if (task['priority'] == 'High') {
      priorityColor = Colors.red;
    } else if (task['priority'] == 'Medium') {
      priorityColor = Colors.orange;
    } else if (task['priority'] == 'Low') {
      priorityColor = Colors.green;
    }

    return SizedBox(
      width: 200,
      child: Card(
        color: cardColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space elements evenly
            children: [
              // Upper section - Title and description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with document icon
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.description_outlined, color: textColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task['title'] ?? 'Task Title',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Description - with proper spacing
                  if (task['description'] != null && task['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0), // Indent to align with title text
                      child: Text(
                        task['description'],
                        style: TextStyle(
                          fontSize: 17,
                          color: textColor.withOpacity(0.8),
                        ),
                        maxLines: 3, // Allow more lines for description
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),

              // Add more vertical space
              const SizedBox(height: 16),

              // Lower section - Priority and Deadline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Priority column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Priority',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          task['priority'] ?? 'Medium',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Deadline column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deadline',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        deadlineText,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildProjectsSection() {
    final projects =
        context.watch<ProjectService>().projects; // Get projects from service

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Projects',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/scrumMasterProjects');
              },
              style: TextButton.styleFrom(
                foregroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'See all',
                style: TextStyle(
                  color: Color(0xFF004AAD),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: projects.length,
          itemBuilder:
              (context, index) => _buildProjectCard(projects[index], index),
        ),
      ],
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    // Calculate color based on passed index
    Color lineColor =
    (index % 2 == 0) ? const Color(0xFF004AAD) : const Color(0xFF545454);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFFDFDFD),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                  ScrumMasterProjectDetailsScreen(project: project),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      project['id'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF004AAD),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  color: Colors.white,
                  iconSize: 20,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => ScrumMasterProjectDetailsScreen(
                          project: project,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
