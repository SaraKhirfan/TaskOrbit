import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_orbit/widgets/product_owner_drawer.dart';

class ActivityLogsProjectSelectionScreen extends StatefulWidget {
  const ActivityLogsProjectSelectionScreen({Key? key}) : super(key: key);

  @override
  State<ActivityLogsProjectSelectionScreen> createState() => _ActivityLogsProjectSelectionScreenState();
}

class _ActivityLogsProjectSelectionScreenState extends State<ActivityLogsProjectSelectionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1; // Projects tab in bottom nav
  bool _isLoading = false;
  String? _searchQuery;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushReplacementNamed(context, '/myProjects');
    if (index == 2) Navigator.pushReplacementNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushReplacementNamed(context, '/MyProfile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: const Color(0xFF004AAD),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.chat),
            color: Color(0xFF004AAD),
            onPressed: () {
              Navigator.pushNamed(context, '/POChat_list');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'Activity Logs'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFE3EFFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Project',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a project to view activity logs',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
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
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: Icon(Icons.search, color: Color(0xFF004AAD)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.isEmpty ? null : value.toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Projects list
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Color(0xFF004AAD)))
                    : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('projects')
                      .where('members', arrayContains: FirebaseAuth.instance.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator(color: Color(0xFF004AAD)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off,
                              size: 64,
                              color: Color(0xFF004AAD).withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No projects found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'You don\'t have any projects yet',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filter projects by search query if provided
                    var filteredDocs = snapshot.data!.docs;
                    if (_searchQuery != null) {
                      filteredDocs = filteredDocs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final projectName = (data['name'] ?? '').toString().toLowerCase();
                        return projectName.contains(_searchQuery!);
                      }).toList();
                    }

                    if (filteredDocs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Color(0xFF004AAD).withOpacity(0.5),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No matching projects',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Try a different search term',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final project = filteredDocs[index];
                        final projectData = project.data() as Map<String, dynamic>;
                        final projectId = project.id;
                        final projectName = projectData['name'] ?? 'Unnamed Project';

                        // Get project progress data if available
                        final int totalTasks = projectData['totalTasks'] ?? 0;
                        final int completedTasks = projectData['completedTasks'] ?? 0;
                        final double progressPercentage = totalTasks > 0
                            ? (completedTasks / totalTasks) * 100
                            : 0.0;

                        return GestureDetector(
                          onTap: () {
                            // Navigate to activity logs with project info
                            Navigator.pushNamed(
                              context,
                              '/activityLogs',
                              arguments: {
                                'projectId': projectId,
                                'projectName': projectName,
                              },
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 16),
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
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      // Project icon
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF004AAD).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.folder_open,
                                            color: Color(0xFF004AAD),
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      // Project name and status
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              projectName,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF313131),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFF004AAD).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Project',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF004AAD),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8),
                                                if (projectData['status'] != null)
                                                  Container(
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(projectData['status']).withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      projectData['status'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: _getStatusColor(projectData['status']),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // View logs button/icon
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Color(0xFF004AAD),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                  // Show progress bar if data available
                                  if (totalTasks > 0) ...[
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Progress',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF666666),
                                                    ),
                                                  ),
                                                  Text(
                                                    '${progressPercentage.toStringAsFixed(0)}%',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF004AAD),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(2),
                                                child: LinearProgressIndicator(
                                                  value: progressPercentage / 100,
                                                  backgroundColor: Color(0xFFE0E0E0),
                                                  valueColor: AlwaysStoppedAnimation<Color>(
                                                    Color(0xFF004AAD),
                                                  ),
                                                  minHeight: 6,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
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
  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
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

  // Helper method to get color based on project status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'in progress':
        return Colors.green;
      case 'pending':
      case 'on hold':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}