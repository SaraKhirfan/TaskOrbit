import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/widgets/clientBottomNav.dart';
import '../../services/AuthService.dart';
import '../../services/project_service.dart';
import '../../widgets/client_drawer.dart';
import '../../widgets/sm_app_bar.dart';

class ClientProjectDetailsScreen extends StatefulWidget {
  final String projectId;

  const ClientProjectDetailsScreen({super.key, required this.projectId});

  @override
  State<ClientProjectDetailsScreen> createState() => _ClientProjectDetailsScreenState();
}

class _ClientProjectDetailsScreenState extends State<ClientProjectDetailsScreen> {
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
    if (index == 0) Navigator.pushNamed(context, '/clientHome');
    if (index == 1) Navigator.pushNamed(context, '/clientProjects');
    if (index == 2) Navigator.pushNamed(context, '/clientTimeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/clientProfile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: ClientDrawer(selectedItem: 'Projects'),
      body: SafeArea(
        // Add this parameter to remove bottom padding
        bottom: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _project == null
            ? _buildProjectNotFound()
            : SingleChildScrollView( // ADD THIS
          child: _buildProjectDetails(),
        ),
      ),
      bottomNavigationBar: clientBottomNav(
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
              backgroundColor: const Color(0xFF004AAD),
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
              Navigator.pushReplacementNamed(context, '/clientProjects');
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004AAD),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _project!['name'] ?? _project!['title'] ?? 'Project Details',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            color: const Color(0xFFEDF1F3),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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

          // CHANGED: Removed Expanded and used Column directly
          Column(
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
                  const SizedBox(width: 12), // Gap between buttons
                  // Team button
                  Expanded(
                    child: _buildFeatureButton(
                      icon: Icons.people,
                      title: 'Team',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12), // Gap between rows
              // Full-width Analytics button
              SizedBox(
                width: double.infinity, // Takes full width
                child: _buildFeatureButton(
                  icon: Icons.analytics,
                  title: 'Analytics',
                ),
              ),
              const SizedBox(height: 100), // Add some bottom spacing
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // This should fix it
        children: [
          Container(
            width: double.infinity,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: 6),
          // Value
          Container(
            width: double.infinity,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                height: 1.5,
              ),
              textAlign: TextAlign.left, // Explicitly align left
            ),
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
              '/clientMemberSprintPlanning',
              arguments: _project!['id'],
            );
          } else if (title == 'Team') {
            // Pass the whole project object instead of just the ID
            Navigator.pushNamed(
              context,
              '/ClientTeamOverview',
              arguments: _project,  // Pass the entire project object
            );
          } else if (title == 'Analytics') {
            // For future implementation
            Navigator.pushNamed(
              context,
              '/clientAnalytics',
              arguments: _project!['id'],
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