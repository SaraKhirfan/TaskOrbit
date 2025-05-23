import 'package:flutter/material.dart';
import 'package:task_orbit/screens/ScrumMaster/smReports.dart';
import 'sm_project_team_screen.dart';
import 'sm_sprint_planning_screen.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_bottom_nav.dart';

class ScrumMasterProjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ScrumMasterProjectDetailsScreen({super.key, required this.project});

  @override
  State<ScrumMasterProjectDetailsScreen> createState() =>
      _ScrumMasterProjectDetailsScreenState();
}

class _ScrumMasterProjectDetailsScreenState
    extends State<ScrumMasterProjectDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; //  tab in bottom nav
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/scrumMasterProfile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: SMDrawer(selectedItem: 'My Projects'),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
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
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        widget.project['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
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
                          widget.project['id'] ?? 'N/A',
                        ),
                        const Divider(height: 24, thickness: 1),

                        // Description - Changed to match screenshot
                        if (widget.project['description'] != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label
                              Text(
                                'Description',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF313131),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Value with better wrapping
                              Text(
                                widget.project['description'] ?? 'No description',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                              const Divider(height: 24, thickness: 1),
                            ],
                          ),

                        // Start Date
                        _buildDetailRow(
                          'Start Date',
                          widget.project['startDate'] ?? 'DD/MM/YYYY',
                        ),
                        const Divider(height: 24, thickness: 1),

                        // End Date
                        _buildDetailRow(
                          'End Date',
                          widget.project['endDate'] ?? 'DD/MM/YYYY',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Original GridView layout - just with fixed height
                GridView.count(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true, // This makes GridView take only space it needs
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  padding: const EdgeInsets.all(8),
                  children: [
                    _buildFeatureButton(
                      icon: Icons.view_list_rounded,
                      title: 'Backlog',
                    ),
                    _buildFeatureButton(
                      icon: Icons.cached_outlined,
                      title: 'Sprints',
                    ),
                    _buildFeatureButton(icon: Icons.people, title: 'Team'),
                    _buildFeatureButton(
                      icon: Icons.analytics,
                      title: 'Analytics',
                    ),
                  ],
                ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align to top for multi-line text
        children: [
          // Fixed width container for labels to ensure consistent alignment
          Container(
            width: 100, // Adjust this width based on your longest label
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
            ),
          ),
          const SizedBox(width: 8), // Add consistent spacing between label and value
          // Expanded container for values with better text alignment
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.left, // Change from textAlign.right to textAlign.left
              overflow: TextOverflow.visible, // Allow text to wrap naturally
              maxLines: null, // Allow unlimited lines
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
          if (title == 'Backlog') {
            Navigator.pushNamed(
              context,
              '/scrumMasterBacklog',
              arguments: widget.project,
            );
          } else if (title == 'Sprints') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                    SMSprintPlanningScreen(project: widget.project),
              ),
            );
          }
          if (title == 'Team') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SMProjectTeamScreen(
                  projectData: widget.project, // Pass the actual project data
                ),
              ),
            );
          } else if (title == 'Analytics') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                    SMReportsAnalyticsScreen(project: widget.project),
              ),
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