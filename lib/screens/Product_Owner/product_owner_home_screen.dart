import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:task_orbit/services/TodoService.dart';
import '../../services/AuthService.dart';
import '../../widgets/product_owner_drawer.dart';

class ProductOwnerHomeScreen extends StatefulWidget {
  final String userRole;
  const ProductOwnerHomeScreen({super.key, required this.userRole});

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color errorColor = Color(0xFFE53935);
  static const Color shadowColor = Color(0x1A000000);

  @override
  State<ProductOwnerHomeScreen> createState() => _ProductOwnerHomeScreenState();
}

class _ProductOwnerHomeScreenState extends State<ProductOwnerHomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Add user data variables
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }


  // Initialize all data with error handling
  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      // Load user profile
      await _loadUserData();

      // Load projects and tasks
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final taskService = Provider.of<TodoService>(context, listen: false);

      await Future.wait([
        projectService.refreshProjects(),
        taskService.refreshTodos()
      ]);

    } catch (e) {
      print('Error initializing home screen data: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load data. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserProfile();
      if (userData != null && mounted) {
        print('User data loaded from Firebase: ${userData['name']}, ${userData['email']}');
        setState(() {
          _userName = userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? '';
        });
      } else {
        print('No user data found in Firebase');
      }
    } catch (e) {
      print('Error loading user profile: $e');
      // Don't set error state, allow the app to continue with default values
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }


  static const Color primaryColor = Color(0xFF004AAD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFFFDFDFD),
        foregroundColor: Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: Color(0xFF004AAD),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat),
            color: Color(0xFF004AAD),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'Home'),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/HomeProductOwner.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
              ? _buildErrorView()
              : SingleChildScrollView(
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
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ProductOwnerHomeScreen.primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _initializeData,
              child: Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    // Use TaskService instead of direct Firestore access
    final taskService = Provider.of<TodoService>(context);

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
                Navigator.pushNamed(context, '/MyTasks');
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
          child: taskService.isLoading
              ? const Center(child: CircularProgressIndicator())
              : taskService.incompleteTodos.isEmpty
              ? const Center(
            child: Text(
              'No tasks available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          )
              : ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: taskService.incompleteTodos.length > 5
                ? 5
                : taskService.incompleteTodos.length,
            separatorBuilder: (_, __) => const SizedBox(width: 15),
            itemBuilder: (context, index) => _buildTaskCard(
                taskService.incompleteTodos[index],
                index
            ),
          ),
        ),
      ],
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
    final projectService = Provider.of<ProjectService>(context);
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
              onPressed: () => Navigator.pushNamed(context, '/myProjects'),
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
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        projectService.projects.isEmpty
            ? Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Text(
              'No projects available',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        )
            : Column(
          children: projectService.projects.take(2).map((project) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: () => Navigator.pushNamed(
                  context,
                  '/projectDetails',
                  arguments: {'id': project['id']},
                ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      // Vertical colored bar
                      Container(
                        width: 4,
                        height: 30,
                        decoration: BoxDecoration(
                          color: projectService.projects.indexOf(project) == 0
                              ? Color(0xFF004AAD) // Blue for first project
                              : Colors.grey, // Grey for others
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Project name and ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project['title'] ?? project['name'] ?? 'Project ${projectService.projects.indexOf(project) + 1}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              project['id'] ?? 'No ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Arrow button
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Color(0xFF004AAD),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  Widget _buildBottomNavBar() {
    return Container(
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
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF004AAD) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF004AAD) : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}