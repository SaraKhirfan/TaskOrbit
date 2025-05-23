import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sprint_details_screen.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../services/sprint_service.dart';
import '../../main.dart';

class SprintHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const SprintHistoryScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _SprintHistoryScreenState createState() => _SprintHistoryScreenState();
}

class _SprintHistoryScreenState extends State<SprintHistoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> completedSprints = [];
  bool _isLoading = true;
  int _selectedIndex = 1;

  // Filter options
  String _sortBy = 'date'; // 'date', 'name'
  bool _sortAscending = false; // true for ascending, false for descending

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1) Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2) Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
    if (index == 3) Navigator.pushReplacementNamed(context, '/scrumMasterProfile');
  }

  @override
  void initState() {
    super.initState();
    _loadCompletedSprints();
  }

  Future<void> _loadCompletedSprints() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sprintService = Provider.of<SprintService>(context, listen: false);
      final loadedSprints = await sprintService.getSprints(widget.projectId);

      // Filter to only include completed sprints
      final completed = loadedSprints.where((s) => s['status'] == 'Completed').toList();

      // Sort sprints based on current sort settings
      _sortSprints(completed);

      setState(() {
        completedSprints = completed;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading completed sprints: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortSprints(List<Map<String, dynamic>> sprints) {
    if (_sortBy == 'date') {
      sprints.sort((a, b) {
        final aDate = a['endDate'] ?? '';
        final bDate = b['endDate'] ?? '';
        return _sortAscending
            ? aDate.compareTo(bDate)
            : bDate.compareTo(aDate);
      });
    } else if (_sortBy == 'name') {
      sprints.sort((a, b) {
        final aName = a['name'] ?? '';
        final bName = b['name'] ?? '';
        return _sortAscending
            ? aName.compareTo(bName)
            : bName.compareTo(aName);
      });
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortAscending = !_sortAscending;
      _sortSprints(completedSprints);
    });
  }

  void _changeSortBy(String? newSortBy) {
    if (newSortBy != null && newSortBy != _sortBy) {
      setState(() {
        _sortBy = newSortBy;
        _sortSprints(completedSprints);
      });
    }
  }

  void _navigateToSprintDetails(Map<String, dynamic> sprint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SprintDetailsScreen(
          sprint: sprint,
          projectId: widget.projectId,
          projectName: widget.projectName,
        ),
      ),
    ).then((_) {
      // Reload sprints when returning from details screen
      _loadCompletedSprints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Sprint History"),
      drawer: SMDrawer(selectedItem: 'My Projects'),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BacklogItem.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button and title
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Sprint History',
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
                widget.projectName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Sort controls
            if (!_isLoading && completedSprints.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Sort by:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _sortBy,
                      onChanged: _changeSortBy,
                      items: [
                        DropdownMenuItem(
                          value: 'date',
                          child: Text('End Date'),
                        ),
                        DropdownMenuItem(
                          value: 'name',
                          child: Text('Sprint Name'),
                        ),
                      ],
                      underline: Container(
                        height: 1,
                        color: MyApp.primaryColor,
                      ),
                    ),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        _sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: MyApp.primaryColor,
                      ),
                      onPressed: _toggleSortOrder,
                      tooltip: _sortAscending ? 'Ascending' : 'Descending',
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : completedSprints.isEmpty
                  ? Center(
                child: Text(
                  'No completed sprints yet.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: completedSprints.length,
                itemBuilder: (context, index) {
                  final sprint = completedSprints[index];
                  return _buildCompletedSprintCard(sprint);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildCompletedSprintCard(Map<String, dynamic> sprint) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToSprintDetails(sprint),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Green vertical line for completed sprints
            Container(
              width: 5,
              height: 120,
              decoration: BoxDecoration(
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
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sprint name and completed badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sprint['name'] ?? 'Sprint',
                            style: TextStyle(
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
                    SizedBox(height: 12),

                    // Sprint duration
                    Row(
                      children: [
                        Text(
                          'Duration:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          sprint['duration'] != null
                              ? '${sprint['duration']} weeks'
                              : 'Not specified',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // Sprint dates
                    Row(
                      children: [
                        Text(
                          'Dates:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (sprint['startDate'] != null && sprint['endDate'] != null)
                                ? '${sprint['startDate']} - ${sprint['endDate']}'
                                : 'Not specified',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Show task completion stats if available
                    if (sprint.containsKey('totalTasks') && sprint.containsKey('completedTasks')) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Tasks:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${sprint['completedTasks']}/${sprint['totalTasks']} completed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Arrow icon
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}