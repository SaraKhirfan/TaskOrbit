import 'package:flutter/material.dart';
import '../../widgets/TMBottomNav.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../services/AuthService.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import '../Product_Owner/my_projects_screen.dart';

class TeamMemberProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const TeamMemberProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<TeamMemberProjectDetailsScreen> createState() => _TeamMemberProjectDetailsScreenState();
}

class _TeamMemberProjectDetailsScreenState extends State<TeamMemberProjectDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
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
      final projectService = Provider.of<ProjectService>(
          context, listen: false);
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
        final refreshedProject = projectService.getProjectById(
            widget.projectId);

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

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: TeamMemberDrawer(selectedItem: 'Projects'),
      body: SafeArea(
        // Add this parameter to remove bottom padding
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
            ? _buildProjectNotFound()
            : _buildProjectDetails(),
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
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
              Navigator.pushReplacementNamed(context, '/teamMemberProjects');
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
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: MaterialStateProperty.all(const Color(0xFF004AAD)),
        trackColor: MaterialStateProperty.all(const Color(0xFF004AAD).withOpacity(0.2)),
        thickness: MaterialStateProperty.all(6.0),
        radius: const Radius.circular(3.0),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        trackVisibility: true,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project header with back button and title - unchanged
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF004AAD),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        _project!['name'] ?? _project!['title'] ?? 'Project Details',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Project details card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: const Color(0xFFEDF1F3),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    width: double.infinity,
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
              ),

              const SizedBox(height: 20),

              // Feature buttons section
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
                child: Column(
                  children: [
                    // Top row with two buttons
                    Row(
                      children: [
                        // Sprints button
                        Expanded(
                          child: _buildFeatureButton(
                            icon: Icons.cached_outlined,
                            title: 'Sprints',
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Team button
                        Expanded(
                          child: _buildFeatureButton(
                            icon: Icons.people,
                            title: 'Team',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Full-width Analytics button
                    SizedBox(
                      width: double.infinity,
                      child: _buildFeatureButton(
                        icon: Icons.analytics,
                        title: 'Analytics',
                      ),
                    ),

                    // Add extra padding to force scrolling and make scrollbar visible
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // This ensures left alignment
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF313131),
            ),
            textAlign: TextAlign.left, // Explicitly set left alignment
          ),
          const SizedBox(height: 4),
          // Value
          Text(
            value,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.left, // Explicitly set left alignment
            overflow: TextOverflow.visible,
            maxLines: null,
          ),
        ],
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
          if (title == 'Sprints') {
            // For future implementation
            Navigator.pushNamed(
              context,
              '/teamMemberSprintPlanning',
              arguments: _project!['id'],
            );
          } else if (title == 'Team') {
            // Pass the whole project object instead of just the ID
            Navigator.pushNamed(
              context,
              '/TMTeamOverview',
              arguments: _project,  // Pass the entire project object
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
              '/TMAnalytics',
              arguments: projectForNavigation,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 8,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
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