import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../services/navigation_service.dart';
import '../../widgets/clientBottomNav.dart';
import '../../widgets/client_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../services/sprint_service.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({Key? key, required String userRole}) : super(key: key);

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final NavigationService _navigationService = NavigationService();
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/clientHome');
    if (index == 1) Navigator.pushNamed(context, '/clientProjects');
    if (index == 2) Navigator.pushNamed(context, '/clientTimeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/clientProfile');
  }


  Future<List<Map<String, dynamic>>> _getActiveSprints(
      List<Map<String, dynamic>> projects,
      SprintService sprintService
      ) async {
    List<Map<String, dynamic>> activeSprints = [];

    for (var project in projects) {
      try {
        // Get all sprints for this project
        final projectSprints = await sprintService.getSprints(project['firestoreId'] ?? project['id']);

        // Filter for active sprints and add project info
        for (var sprint in projectSprints) {
          if (sprint['status'] == 'Active') {
            // Calculate real progress
            final progress = await sprintService.calculateSprintProgress(
                project['firestoreId'] ?? project['id'],
                sprint['id']
            );

            activeSprints.add({
              'projectName': project['name'] ?? 'Project',
              'sprintName': sprint['name'] ?? 'Sprint',
              'velocity': progress / 100, // Convert percentage to decimal (0.0-1.0)
              'deadline': _formatDate(sprint['endDate']),
            });
          }
        }
      } catch (e) {
        print('Error fetching sprints for project ${project['name']}: $e');
      }
    }

    return activeSprints;
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'No deadline';

    try {
      if (date is Timestamp) {
        final dateTime = date.toDate();
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (date is String) {
        return date;
      }
      return 'No deadline';
    } catch (e) {
      return 'No deadline';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access project service for real data
    final projectService = Provider.of<ProjectService>(context);
      // ADD THIS DEBUG CODE:
      print('=== CLIENT UI DEBUG ===');
      print('Projects in service: ${projectService.projects.length}');
      for (var project in projectService.projects) {
        print('- ${project['name']} (${project['id']})');
      }
      print('=== END UI DEBUG ===');
    final projects = projectService.projects;

    final sprintService = Provider.of<SprintService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Home"),
      drawer: const ClientDrawer (selectedItem: 'Home'),
      body: SafeArea(
    child: Container(
    decoration: BoxDecoration(
        image: DecorationImage(
        image: AssetImage('assets/images/HomeProductOwner.png'),
    fit: BoxFit.cover,
    ),
    ),
      child:
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting section
              const Text(
                'Hello!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 24),

              // Sprints Updates section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Active Sprints',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Sprint cards - horizontal scrollable
              SizedBox(
                height: 220,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getActiveSprints(projects, sprintService),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator( color: Color(0xFF004AAD) ,));
                    }

                    final activeSprints = snapshot.data ?? [];

                    if (activeSprints.isEmpty) {
                      return Center(
                        child: Text(
                          'No active sprints',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      );
                    }

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: activeSprints.length,
                      itemBuilder: (context, index) {
                        return _buildSprintCard(activeSprints[index]);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
    _buildProjectsSection(),
    SizedBox(height: MediaQuery.of(context).padding.bottom + 250),
            ],
          ),
        ),
      ),
    ),
      ),
      bottomNavigationBar: clientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildSprintCard(Map<String, dynamic> sprint) {
    return Container(
      width: 230,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
          color: Color(0xFFEDF1F3),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name with icon
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Colors.grey[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sprint['projectName'],
                  style: TextStyle(
                    fontSize: 14, // REDUCED from 16 to 14
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sprint name - FIX THE OVERFLOW HERE
          Text(
            sprint['sprintName'],
            style: const TextStyle(
              fontSize: 16, // REDUCED from 18 to 16
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2, // ADD: Allow 2 lines
            overflow: TextOverflow.ellipsis, // ADD: Handle overflow
          ),

          const SizedBox(height: 16),

          // Progress section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(sprint['velocity'] * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: sprint['velocity'],
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 16),

          // Deadline - MAKE THIS MORE COMPACT
          Column( // CHANGED from Row to Column for better space usage
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deadline',
                style: TextStyle(
                  fontSize: 12, // REDUCED from 14 to 12
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sprint['deadline'],
                style: TextStyle(
                  fontSize: 12, // REDUCED from 14 to 12
                  color: Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis, // ADD: Handle overflow
                maxLines: 1, // ADD: Single line only
              ),
            ],
          ),
        ],
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
              onPressed: () => Navigator.pushNamed(context, '/clientProjects'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF004AAD),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
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
                onTap: () =>
                    Navigator.pushNamed(
                      context,
                      '/client/project_details',
                      arguments: {'id': project['id']},
                    ),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
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
                              project['title'] ?? project['name'] ??
                                  'Project ${projectService.projects.indexOf(
                                      project) + 1}',
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
}