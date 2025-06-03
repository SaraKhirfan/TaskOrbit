import 'package:flutter/material.dart';
import '../../services/TeamMemberTaskService.dart';
import '../../services/project_service.dart';
import '../../widgets/sm_drawer.dart';
import 'package:provider/provider.dart';
import 'SMResolvedIssuesScreen.dart';
import 'SMTeamMemberWorkloadDetailsScreen.dart';

class SMTeamWorkloadDashboardScreen extends StatefulWidget {
  static const Color primaryColor = Color(0xFF004AAD);

  const SMTeamWorkloadDashboardScreen({Key? key}) : super(key: key);

  @override
  _SMTeamWorkloadDashboardScreenState createState() => _SMTeamWorkloadDashboardScreenState();
}

class _SMTeamWorkloadDashboardScreenState extends State<SMTeamWorkloadDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Project selection variables
  List<Map<String, dynamic>> _userProjects = [];
  String? _selectedProjectId;
  bool _isProjectsLoading = true;
  bool _dropdownOpen = false;

  // Team member workload data structure
  List<Map<String, dynamic>> _teamMembersWorkload = [];
  List<Map<String, dynamic>> _teamIssues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
  }

  Future<void> _loadUserProjects() async {
    setState(() {
      _isProjectsLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.refreshProjects();

      setState(() {
        _userProjects = projectService.projects;
        // Set default selected project if available
        if (_userProjects.isNotEmpty && _selectedProjectId == null) {
          _selectedProjectId = _userProjects[0]['id'];
        }
        _isProjectsLoading = false;
      });

      // Load team data for the selected project
      _loadTeamData();

    } catch (e) {
      print('Error loading projects: $e');
      setState(() {
        _isProjectsLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects'))
      );
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: const Color(0xFFFDFDFD),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Poppins-SemiBold',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update in _loadTeamData() method in SMTeamWorkloadDashboardScreen.dart
  Future<void> _loadTeamData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get team member task service
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);

      // Fetch tasks for team members based on selected project using the standardized method
      List<Map<String, dynamic>> teamMembers = await teamMemberTaskService.getTeamMembersWithTasks(_selectedProjectId);
      List<Map<String, dynamic>> issues = await teamMemberTaskService.getTeamIssues(_selectedProjectId);

      setState(() {
        _teamMembersWorkload = teamMembers;
        _teamIssues = issues;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading team data: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading team data'))
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
  }

  // Get color based on workload percentage
  Color _getWorkloadColor(int percentage) {
    if (percentage >= 80) return Colors.red;
    if (percentage >= 50) return Colors.orange;
    return Colors.green;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return difference.inDays == 1 ? '1 day ago' : '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return difference.inHours == 1 ? '1 hour ago' : '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return difference.inMinutes == 1 ? '1 minute ago' : '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F3),
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Color(0xFF004AAD)),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFF004AAD)),
            onPressed: _loadTeamData,
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications, color:Color(0xFF004AAD)),
            onPressed: () {
              // Notifications functionality
            },
          ),
        ],
      ),
      drawer: SMDrawer(selectedItem: 'Workload Monitoring'),
      body: _isLoading || _isProjectsLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with project filter
              _buildHeader(),

              SizedBox(height: 16),

              // Team summary metrics
              _buildTeamSummary(),

              SizedBox(height: 24),

              // Team members list (compact view)
              _buildTeamMembersList(),

              SizedBox(height: 24),

              // Reported issues section
              _buildReportedIssuesSection(),

              SizedBox(height: 100), // Bottom padding for scrolling
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
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
            _buildNavItem(Icons.access_time_filled_rounded, "Schedule", 2),
            _buildNavItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title on top
        Text(
          'Team Workload',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 16), // Space between title and dropdown

        // Project filter dropdown below title
        Container(
          width: double.infinity, // Make it full width
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                setState(() {
                  _dropdownOpen = !_dropdownOpen;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.business, color: Color(0xFF004AAD), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isProjectsLoading
                              ? 'Loading projects...'
                              : _userProjects.isEmpty
                              ? 'No projects available'
                              : _selectedProjectId == null
                              ? 'Select a project'
                              : _userProjects
                              .firstWhere(
                                (p) => p['id'] == _selectedProjectId,
                            orElse: () => {'name': 'Select Project'},
                          )['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      AnimatedRotation(
                        turns: _dropdownOpen ? 0.5 : 0.0,
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF004AAD),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    height: _dropdownOpen ? null : 0,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: AnimatedOpacity(
                      opacity: _dropdownOpen ? 1.0 : 0.0,
                      duration: Duration(milliseconds: 150),
                      child: _dropdownOpen ? Container(
                        margin: EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Select Project',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 200, // Maximum height for the dropdown
                              ),
                              child: _userProjects.isEmpty
                                  ? Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: Text(
                                    'No projects available',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              )
                                  : ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _userProjects.length,
                                itemBuilder: (context, index) {
                                  final project = _userProjects[index];
                                  final isSelected = _selectedProjectId == project['id'];

                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          _selectedProjectId = project['id'];
                                          _dropdownOpen = false;
                                        });
                                        _loadTeamData(); // Reload data with new project
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Color(0xFF004AAD).withOpacity(0.08) : Colors.white,
                                          border: Border(
                                            bottom: BorderSide(
                                              color: index == _userProjects.length - 1
                                                  ? Colors.transparent
                                                  : Colors.grey.shade200,
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                project['name'] ?? 'Unnamed Project',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                  color: isSelected ? Color(0xFF004AAD) : Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isSelected)
                                              Container(
                                                padding: EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFF004AAD),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 14,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ) : SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSummary() {
    // Calculate team summary metrics from all members
    int totalTasks = 0;
    int tasksNotStarted = 0;
    int tasksInProgress = 0;
    int tasksDone = 0;

    for (var member in _teamMembersWorkload) {
      totalTasks += member['totalTasks'] as int;
      tasksNotStarted += member['notStarted'] as int;
      tasksInProgress += member['inProgress'] as int;
      tasksDone += member['done'] as int;
    }

    // Calculate velocity percentage
    int velocityPercentage = totalTasks > 0 ? ((tasksDone / totalTasks) * 100).round() : 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Team Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          // Metrics row with fixed width items to prevent overflow
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricItem(Icons.assignment_outlined, totalTasks.toString(), 'Total Tasks', Color(0xFFE3F2FD)),
              _buildMetricItem(Icons.hourglass_empty, tasksNotStarted.toString(), 'Not Started', Color(0xFFF5F5F5)),
              _buildMetricItem(Icons.trending_up, tasksInProgress.toString(), 'In Progress', Color(0xFFE3F2FD)),
              _buildMetricItem(Icons.check_circle_outline, tasksDone.toString(), 'Done', Color(0xFFF5F5F5)),
            ],
          ),
          SizedBox(height: 16),
          // Team velocity row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Velocity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: velocityPercentage / 100,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          velocityPercentage >= 75 ? Colors.green :
                          velocityPercentage >= 50 ? Colors.orange : Colors.red,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${velocityPercentage}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: velocityPercentage >= 75 ? Colors.green :
                      velocityPercentage >= 50 ? Colors.orange : Colors.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String value, String label, Color bgColor) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: Colors.black87),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMembersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 16),

        if (_teamMembersWorkload.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No team members assigned to this project yet.',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ...List.generate(_teamMembersWorkload.length, (index) {
            final member = _teamMembersWorkload[index];
            final workloadPercentage = member['workloadPercentage'] as int;
            final workloadColor = _getWorkloadColor(workloadPercentage);

            return InkWell(
              onTap: () {
                // Navigate to member workload details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SMTeamMemberWorkloadDetailsScreen(
                      memberData: member,
                    ),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      backgroundColor: SMTeamWorkloadDashboardScreen.primaryColor,
                      radius: 20,
                      child: Text(
                        member['avatar'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),

                    // Name and role
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            member['role'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Workload percentage
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: workloadColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${workloadPercentage}%',
                            style: TextStyle(
                              color: workloadColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        // Task status counts
                        Row(
                          children: [
                            _buildTaskCountBadge(member['notStarted'], Colors.grey),
                            SizedBox(width: 6),
                            _buildTaskCountBadge(member['inProgress'], Colors.blue),
                            SizedBox(width: 6),
                            _buildTaskCountBadge(member['done'], Colors.green),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildTaskCountBadge(int count, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count.toString(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildReportedIssuesSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Reported Issues',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextButton.icon(
            icon: Icon(Icons.history, size: 16),
            label: Text('History'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SMResolvedIssuesScreen(),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF004AAD),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ],
        ),
          SizedBox(height: 16),
          _teamIssues.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No issues reported',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
              : Column(
            children: _teamIssues.map((issue) {
              return _buildIssueItem(issue);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(Map<String, dynamic> issue) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info and time
          Row(
            children: [
              // User avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                backgroundImage: issue['userPhotoUrl'] != null && issue['userPhotoUrl'] != ''
                    ? NetworkImage(issue['userPhotoUrl'])
                    : null,
                child: issue['userPhotoUrl'] == null || issue['userPhotoUrl'] == ''
                    ? Icon(Icons.person, size: 16, color: Colors.grey[400])
                    : null,
              ),
              SizedBox(width: 8),
              // User name
              Text(
                issue['userName'] ?? 'Unknown User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              // Time ago
              Text(
                _formatTimeAgo(issue['timestampDate']),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              SizedBox(width: 8),
             // Add three-dot menu
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (value) async {
                  try {
                    // Debug the status value
                    print('Selected action: $value');

                    await Provider.of<TeamMemberTaskService>(context, listen: false)
                        .updateWorkloadIssueStatus(
                        _selectedProjectId!,  // FIXED: Use _selectedProjectId instead of issue['projectId']
                        issue['id'],
                        value
                    );

                    // Refresh the list
                    _loadTeamData();  // FIXED: Call _loadTeamData() to refresh

                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Issue status updated to $value'))
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating status: $e'))
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'reviewed',
                    child: Text('Mark as Reviewed'),
                  ),
                  PopupMenuItem(
                    value: 'resolved',  // Make sure this is lowercase "resolved"
                    child: Text('Mark as Resolved'),
                  ),
                ],
              )
            ],
          ),
          SizedBox(height: 8),
          // Issue description
          Text(
            issue['explanation'] ?? 'No explanation provided',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          // Status chip
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getIssueStatusColor(issue['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getIssueStatusText(issue['status']),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getIssueStatusColor(issue['status']),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateIssueStatus(Map<String, dynamic> issue, String newStatus) async {
    try {
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(
          context, listen: false);
      await teamMemberTaskService.updateWorkloadIssueStatus(
          _selectedProjectId!,
          issue['id'],
          newStatus
      );

      // Refresh the list
      _loadTeamData();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Issue status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update issue status: ${e.toString()}')),
      );
    }
  }

  Color _getIssueStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return Colors.green;
      case 'reviewed':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.red;
    }
  }

  String _getIssueStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'resolved':
        return 'Resolved';
      case 'reviewed':
        return 'Reviewed';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}