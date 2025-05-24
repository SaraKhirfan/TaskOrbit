import 'package:flutter/material.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../services/AuthService.dart';
import '../../widgets/product_owner_drawer.dart';
import 'EditProjectScreen.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; // Projects is selected
  bool _isLoading = true;
  Map<String, dynamic>? _project;

  // User data
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProjectData();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getUserProfile();

    if (userData != null && mounted) {
      setState(() {
        _userName = userData['name'] ?? 'User';
        _userEmail = userData['email'] ?? '';
      });
    }
  }

  // Load project data
  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First try to get from current projects
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final project = projectService.getProjectById(widget.projectId);

      if (project != null) {
        setState(() {
          _project = project;
          _isLoading = false;
        });
      } else {
        // If not found, try to refresh projects from Firebase
        await projectService.refreshProjects();

        // Check again after refresh
        final refreshedProject = projectService.getProjectById(widget.projectId);

        setState(() {
          _project = refreshedProject;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading project data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle logout with Firebase
  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
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
        // Remove SafeArea completely and use Container instead
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
            ? _buildProjectNotFound()
            : _buildProjectDetails(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFDFDFD),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: MyProjectsScreen.primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins-SemiBold',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins-SemiBold',
          fontWeight: FontWeight.bold,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects',),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildProjectNotFound() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'Project Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We couldn\'t find the project with ID: ${widget.projectId}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: MyProjectsScreen.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/myProjects');
            },
            child: const Text('Back to Projects'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadProjectData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails() {
    // Create a ScrollController to control the scrolling
    final ScrollController scrollController = ScrollController();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back/edit/delete buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back button on left
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004AAD),
                ),
                onPressed: () => Navigator.pop(context),
              ),

              // Edit and delete buttons on right
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Color(0xFF004AAD),
                    ),
                    onPressed: () => _editProject(),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Color(0xFF004AAD),
                    ),
                    onPressed: () => _showDeleteConfirmation(),
                  ),
                ],
              ),
            ],
          ),

          // Project title with proper spacing
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0, left: 8.0),
            child: Text(
              _project!['name'] ?? _project!['title'] ?? 'Project Details',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
            ),
          ),

          // Project details card with scrollbar
          Expanded(
            child: RawScrollbar(
              thumbColor: const Color(0xFF004AAD).withOpacity(0.6),  // Scrollbar color
              radius: const Radius.circular(10),                     // Rounded corners
              thickness: 6,                                          // Scrollbar width
              controller: scrollController,                          // Connect to the ScrollController
              thumbVisibility: true,                                 // Always show scrollbar
              child: SingleChildScrollView(
                controller: scrollController,  // Use the same controller
                physics: const AlwaysScrollableScrollPhysics(),     // Always allow scrolling
                child: Column(
                  children: [
                    // Project details card
                    Card(
                      color: const Color(0xFFEDF1F3),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Project ID
                            _buildDetailRow(
                              'Project ID',
                              _project!['id'] ?? 'N/A',
                            ),
                            const Divider(height: 24, thickness: 1),

                            // Description
                            if (_project!['description'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetailRow(
                                    'Description',
                                    _project!['description'] ?? 'No description',
                                  ),
                                  const Divider(height: 24, thickness: 1),
                                ],
                              ),

                            // Start Date
                            _buildDetailRow(
                              'Start Date',
                              _project!['startDate'] ?? 'DD/MM/YYYY',
                            ),
                            const Divider(height: 24, thickness: 1),

                            // End Date
                            _buildDetailRow(
                              'End Date',
                              _project!['endDate'] ?? _project!['dueDate'] ?? 'DD/MM/YYYY',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Feature buttons section
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0), // Add padding to account for scrollbar
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(), // Disable grid scrolling
                        children: [
                          _buildFeatureButton(
                            icon: Icons.view_list_rounded,
                            title: 'Backlog',
                          ),
                          _buildFeatureButton(
                            icon: Icons.cached_outlined,
                            title: 'Sprints',
                          ),
                          _buildFeatureButton(
                              icon: Icons.people,
                              title: 'Team'
                          ),
                          _buildFeatureButton(
                            icon: Icons.analytics,
                            title: 'Analytics',
                          ),
                        ],
                      ),
                    ),

                    // Add bottom padding to ensure buttons are not cut off
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF313131),
            ),
          ),
          const SizedBox(height: 4), // Space between label and value

          // Value - for description, make it wrap properly
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
  Future<void> _showDeleteConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Project'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('Are you sure you want to delete this project?'),
                Text('This action cannot be undone.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _deleteProject(); // Proceed with deletion
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProject() async {
    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.deleteProject(_project!['id']);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted successfully')),
        );

        // Navigate back to projects list
        Navigator.pushReplacementNamed(context, '/myProjects');
      }
    } catch (e) {
      if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting project: $e')),
        );
      }
    }
  }
  void _editProject() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(
          project: _project!,
          onProjectUpdated: (projectId, updatedProject) async {
            // Update project in service
            final projectService = Provider.of<ProjectService>(context, listen: false);
            await projectService.updateProject(projectId, updatedProject);

            // Refresh project data
            _loadProjectData();
          },
        ),
      ),
    );
  }

  Widget _buildFeatureButton({required IconData icon, required String title}) {
    return Card(
      color: const Color(0xFF004AAD),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (_project == null) return;

          if (title == 'Backlog') {
            Navigator.pushNamed(
              context,
              '/productBacklog',
              arguments: _project,
            );
          } else if (title == 'Sprints') {
            Navigator.pushNamed(
              context,
              '/sprintPlanning',
              arguments: _project,
            );
          } else if (title == 'Team') {
            Navigator.pushNamed(
              context,
              '/TeamOverview',
              arguments: _project,
            );
          } else if (title == 'Analytics') {
            // Fix for null project ID issue
            final projectForNavigation = Map<String, dynamic>.from(_project!);

            // Explicitly set the ID if it's missing
            if (!projectForNavigation.containsKey('id') || projectForNavigation['id'] == null) {
              projectForNavigation['id'] = widget.projectId;
            }

            print('DEBUG: Navigating to Analytics with project data: $projectForNavigation');
            print('DEBUG: Project ID for navigation: ${projectForNavigation['id']}');

            Navigator.pushNamed(
              context,
              '/Reports',
              arguments: projectForNavigation,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ), // Reduced padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 40, // Smaller icon
              ),
              const SizedBox(height: 4), // Reduced spacing
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14, // Smaller text
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}