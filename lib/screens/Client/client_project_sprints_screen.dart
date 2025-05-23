import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sprint_service.dart';
import '../../widgets/clientBottomNav.dart';
import '../../widgets/client_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import 'ClientSprintDetails.dart';

class ClientSprintPlanningScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ClientSprintPlanningScreen({super.key, required this.project});

  @override
  State<ClientSprintPlanningScreen> createState() => _ClientSprintPlanningScreenState();
}

class _ClientSprintPlanningScreenState extends State<ClientSprintPlanningScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> sprints = [];
  Map<String, dynamic>? lastCompletedSprint; // Add this line
  Map<String, dynamic>? activeSprint;
  List<Map<String, dynamic>> upcomingSprints = [];
  bool _isLoading = true;
  int _selectedIndex = 1;
  final List<Map<String, dynamic>> _sprint = [];

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sprintService = Provider.of<SprintService>(context, listen: false);
      final loadedSprints = await sprintService.getSprints(widget.project['id']);

      if (mounted) {
        // Separate active and upcoming sprints
        final active = loadedSprints.where((s) => s['status'] == 'Active').toList();
        final upcoming = loadedSprints.where((s) => s['status'] == 'Planning').toList();

        // Add this block to get completed sprints
        final completed = loadedSprints.where((s) => s['status'] == 'Completed').toList();
        // Sort completed sprints by end date, newest first
        completed.sort((a, b) {
          final aDate = a['endDate'] ?? '';
          final bDate = b['endDate'] ?? '';
          return bDate.compareTo(aDate);
        });

        setState(() {
          sprints = loadedSprints;
          activeSprint = active.isNotEmpty ? active.first : null;
          upcomingSprints = upcoming;
          // Add this line to save the most recent completed sprint
          lastCompletedSprint = completed.isNotEmpty ? completed.first : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sprints: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/clientHome');
    if (index == 1) Navigator.pushNamed(context, '/clientProjects');
    if (index == 2) Navigator.pushNamed(context, '/clientTimeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/clientProfile');
  }

  void _navigateToSprintDetails(Map<String, dynamic> sprint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClientSprintDetailsScreen(
              sprint: sprint,
              projectId: widget.project['id'],
              projectName: widget.project['name'],
            ),
      ),
    ).then((_) {
      // Reload sprints when returning from details screen
      _loadSprints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: ClientDrawer(selectedItem: 'Projects'),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BacklogItem.png'),
            fit: BoxFit.cover,
          ),
        ),
        child:
        Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF004AAD),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Sprint Planning',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                    ],
                  ),
                ),

                // Project name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.project['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Sprints list - replaced with categorized sections
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : (activeSprint == null && upcomingSprints.isEmpty)
                      ? Center(
                    child: Text(
                      'No sprints yet. Create a new sprint to get started.',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Active Sprint Section
                        if (activeSprint != null) ...[
                          Text(
                            'Active Sprint',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          SizedBox(height: 8),
                          _buildSprintCard(activeSprint!, isActive: true),
                          SizedBox(height: 24),
                        ],

                        // Upcoming Sprints Section
                        if (upcomingSprints.isNotEmpty) ...[
                          Text(
                            'Up Coming',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          SizedBox(height: 8),
                          ...upcomingSprints.map((sprint) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildSprintCard(
                                    sprint, isActive: false),
                              )
                          ).toList(),
                          // Add this section after the upcoming sprints section
                          if (lastCompletedSprint != null) ...[
                            SizedBox(height: 24),
                            Text(
                              'Recently Completed',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                            ),
                            SizedBox(height: 8),
                            _buildCompletedSprintCard(lastCompletedSprint!),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: clientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Add this method to your class
  Widget _buildCompletedSprintCard(Map<String, dynamic> sprint) {
    return InkWell(
      onTap: () => _navigateToSprintDetails(sprint),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
        child: Row(
          children: [
            // Green vertical line for completed sprint
            Container(
              width: 5,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Sprint details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sprint name with completed badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sprint['name'] ?? 'Sprint Name',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Date information
                    Text(
                      (sprint['startDate'] != null && sprint['endDate'] != null)
                          ? '${sprint['startDate']} - ${sprint['endDate']}'
                          : 'No date information',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow icon
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSprintCard(Map<String, dynamic> sprint,
      {required bool isActive}) {
    // Calculate completion percentage
    final completionPercentage = sprint['progress'] as num? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          // Vertical line on the left
          Container(
            width: 5,
            height: isActive ? 120 : 80, // Shorter for upcoming sprints
            decoration: const BoxDecoration(
              color: Color(0xFF004AAD),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),

          // Sprint details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sprint name
                  Text(
                    sprint['name'] ?? 'Sprint Name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),

                  if (isActive) ...[
                    const SizedBox(height: 8),
                    // Duration and date in a row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            sprint['duration'] != null
                                ? '${sprint['duration']} weeks'
                                : 'Not set',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            (sprint['startDate'] != null &&
                                sprint['endDate'] != null)
                                ? '${sprint['startDate']} - ${sprint['endDate']}'
                                : 'Not set',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress bar for active sprint
                    Row(
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: completionPercentage / 100,
                              backgroundColor: Colors.grey[200],
                              color: const Color(0xFF00D45E),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${completionPercentage.toStringAsFixed(
                              0)}% completed',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    ...[
                      // For upcoming sprints, just show "Up Coming" text
                      const SizedBox(height: 4),
                      Text(
                        'Up Coming',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),

          // Navigation arrow
          Container(
            margin: const EdgeInsets.only(right: 8),
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
              onPressed: () => _navigateToSprintDetails(sprint),
            ),
          ),
        ],
      ),
    );
  }
}

