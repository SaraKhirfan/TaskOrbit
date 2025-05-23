import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/TeamMemberTaskService.dart';
import '../../services/project_service.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_drawer.dart';

class SMResolvedIssuesScreen extends StatefulWidget {
  @override
  _SMResolvedIssuesScreenState createState() => _SMResolvedIssuesScreenState();
}

class _SMResolvedIssuesScreenState extends State<SMResolvedIssuesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _resolvedIssues = [];
  bool _isLoading = true;
  String? _selectedProjectId;
  List<Map<String, dynamic>> _userProjects = [];

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
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
// Method to handle status update
  void _updateIssueStatus(Map<String, dynamic> issue, String newStatus) async {
    try {
      // Check if we have a valid project ID
      if (_selectedProjectId == null || _selectedProjectId!.isEmpty) {
        print('Error: No valid project ID found');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: No valid project ID found'))
        );
        return;
      }

      print('Updating issue ${issue['id']} to status: $newStatus');
      print('Using project ID: $_selectedProjectId');

      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);
      await teamMemberTaskService.updateWorkloadIssueStatus(
          _selectedProjectId!, // Use the class variable since you have it
          issue['id'],
          newStatus
      );

      // Refresh the list
      _loadResolvedIssues();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Issue status updated successfully'))
      );
    } catch (e) {
      print('Error updating issue status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update issue status: ${e.toString()}'))
      );
    }
  }
  Future<void> _loadUserProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the project service
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.refreshProjects();

      setState(() {
        _userProjects = projectService.projects;
        // Set default selected project if available
        if (_userProjects.isNotEmpty && _selectedProjectId == null) {
          _selectedProjectId = _userProjects[0]['id'];
          print('Selected project ID: $_selectedProjectId');
        }
      });

      // Now load the resolved issues
      _loadResolvedIssues();

    } catch (e) {
      print('Error loading projects: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading projects'))
      );
    }
  }
  Future<void> _loadResolvedIssues() async {
    print('Loading resolved issues for project: $_selectedProjectId');
    setState(() => _isLoading = true);

    try {
      final teamMemberTaskService = Provider.of<TeamMemberTaskService>(context, listen: false);
      List<Map<String, dynamic>> issues = await teamMemberTaskService.getResolvedIssues(_selectedProjectId);

      print('Loaded ${issues.length} resolved issues');

      setState(() {
        _resolvedIssues = issues;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading resolved issues: $e');
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading resolved issues: ${e.toString()}'))
      );
    }
  }
  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Unknown time';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Resolved Issues"),
      drawer: SMDrawer(selectedItem: 'Workload Monitoring'),
      body: Column(
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
              Text(
               ' Resolved Issues',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
            ],
          ),

          // Main content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _resolvedIssues.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(
                    'No resolved issues found',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _resolvedIssues.length,
              itemBuilder: (context, index) {
                final issue = _resolvedIssues[index];
                return _buildResolvedIssueItem(issue);
              },
            ),
          ),
        ],
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

  Widget _buildResolvedIssueItem(Map<String, dynamic> issue) {
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: EdgeInsets.only(bottom: 8),
            color: Colors.grey[200],
            child: Text(
              'Status: "${issue['status'] ?? 'null'}" (Raw value)',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
                onSelected: (value) => _updateIssueStatus(issue, value),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'reviewed',
                    child: Text('Mark as Reviewed'),
                    enabled: issue['status'] != 'reviewed' && issue['status'] != 'resolved',
                  ),
                  PopupMenuItem(
                    value: 'resolved',
                    child: Text('Mark as Resolved'),
                    enabled: issue['status'] != 'resolved',
                  ),
                ],
              ),
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
          if (issue['statusUpdatedAt'] != null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Resolved on ${_formatDate(issue['statusUpdatedAt'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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