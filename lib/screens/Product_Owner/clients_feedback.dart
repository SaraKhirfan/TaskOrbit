import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Product_Owner/project_details_screen.dart';
import '../../services/FeedbackService.dart';
import '../../services/project_service.dart';
import '../../services/AuthService.dart';
import '../../widgets/product_owner_drawer.dart';

class POClientsFeedbackScreen extends StatefulWidget {
  const POClientsFeedbackScreen({super.key});

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  @override
  State<POClientsFeedbackScreen> createState() => _POClientsFeedbackScreenState();
}

class _POClientsFeedbackScreenState extends State<POClientsFeedbackScreen> {
  int _selectedIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';
  List<Map<String, dynamic>> _feedbackItems = [];
  List<Map<String, dynamic>> _filteredFeedbackItems = []; // For filtered items
  String _selectedProjectId = 'all'; // Default to show all projects
  List<Map<String, dynamic>> _projects = []; // To store available projects

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadProjects(); // Load projects first
    _loadFeedback();
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

  // Load projects for filter dropdown
  Future<void> _loadProjects() async {
    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      // Use the projects getter from ProjectService instead of a getProjects() method
      final projects = projectService.projects;

      if (mounted) {
        setState(() {
          // Add "All Projects" option at the beginning
          _projects = [
            {'id': 'all', 'name': 'All Projects'},
            ...projects
          ];
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  // Refresh projects from Firebase
  Future<void> _refreshProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<ProjectService>(context, listen: false).refreshProjects();
      // Reload projects after refresh
      _loadProjects();
      // Also reload feedback
      await _loadFeedback();
    } catch (e) {
      // Handle error silently
      print('Error refreshing projects: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFeedback() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final feedbackService = Provider.of<FeedbackService>(context, listen: false);
      final feedbackItems = await feedbackService.getAllProjectsFeedback();

      if (mounted) {
        setState(() {
          _feedbackItems = feedbackItems;
          _applyProjectFilter(); // Apply initial filter
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading feedback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _applyProjectFilter(); // Apply initial filter
        });
      }
    }
  }

  // Apply project filter
  void _applyProjectFilter() {
    if (_selectedProjectId == 'all') {
      _filteredFeedbackItems = List.from(_feedbackItems);
    } else {
      _filteredFeedbackItems = _feedbackItems
          .where((item) => item['projectId'] == _selectedProjectId)
          .toList();
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  Future<void> _updateFeedbackResponse(String projectId, String feedbackId, String response) async {
    try {
      final feedbackService = Provider.of<FeedbackService>(context, listen: false);

      // Update in database first
      await feedbackService.updateFeedbackResponse(projectId, feedbackId, response);

      // FIXED: Update both lists properly
      setState(() {
        // Update in main feedback list
        final mainIndex = _feedbackItems.indexWhere((item) => item['id'] == feedbackId);
        if (mainIndex != -1) {
          _feedbackItems[mainIndex]['response'] = response;
        }

        // Update in filtered list
        final filteredIndex = _filteredFeedbackItems.indexWhere((item) => item['id'] == feedbackId);
        if (filteredIndex != -1) {
          _filteredFeedbackItems[filteredIndex]['response'] = response;
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Response submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating feedback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update response. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: POClientsFeedbackScreen.primaryColor,
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
            color: POClientsFeedbackScreen.primaryColor,
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'Clients Feedback'),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/MyProjects.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clients Feedback',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                const SizedBox(height: 16),

                // Project filter dropdown
                // Project filter dropdown
                Container(
                  width: double.infinity, // Make container full width
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFE0E0E0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list,
                        size: 18,
                        color: Color(0xFF004AAD),
                      ),
                      SizedBox(width: 8),
                      Expanded( // Wrap DropdownButton with Expanded
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProjectId,
                            hint: Text('Filter by Project'),
                            icon: Icon(Icons.arrow_drop_down, color: Color(0xFF004AAD)),
                            isDense: true,
                            isExpanded: true, // Add this to make dropdown expand
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedProjectId = newValue;
                                  _applyProjectFilter();
                                });
                              }
                            },
                            items: _projects.map<DropdownMenuItem<String>>((Map<String, dynamic> project) {
                              return DropdownMenuItem<String>(
                                value: project['id'],
                                child: Text(
                                  project['name'],
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis, // Handle long text
                                  maxLines: 1,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _isLoading
                    ? const Expanded(child: Center(child: CircularProgressIndicator()))
                    : Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadFeedback,
                    child: _filteredFeedbackItems.isEmpty
                        ? Center(
                      child: Text(
                        _selectedProjectId == 'all'
                            ? 'No feedback found'
                            : 'No feedback found for this project',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                        : ListView.separated(
                      itemCount: _filteredFeedbackItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 15),
                      itemBuilder: (context, index) => _buildFeedbackCard(_filteredFeedbackItems[index]),
                    ),
                  ),
                ),
              ],
            ),
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
  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    // Get the rating stars
    final List<Widget> stars = List.generate(5, (index) {
      return Icon(
        index < (feedback['rating'] ?? 0) ? Icons.star : Icons.star_border,
        color: index < (feedback['rating'] ?? 0) ? Colors.amber : Colors.grey,
        size: 18,
      );
    });

    // Format the date
    final dateString = feedback['dateSubmitted'] ?? '';
    String formattedDate = '';
    try {
      if (dateString.isNotEmpty) {
        final date = DateTime.parse(dateString);
        formattedDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      formattedDate = dateString; // Fallback to original string if parsing fails
    }

    // Responsive width calculation
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth - 32; // Full width minus padding

    return Container(
      width: cardWidth, // Ensure the card has the correct width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project info and sprint section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Project name with folder icon
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.folder_outlined, color: Color(0xFF004AAD), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedback['projectName'] ?? 'Project',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF004AAD),
                        ),
                        overflow: TextOverflow.ellipsis, // Handle text overflow
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Sprint info
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feedback['sprintName'] ?? 'Sprint',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis, // Handle text overflow
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Client name
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF004AAD),
                      radius: 14,
                      child: Text(
                        (feedback['clientName'] ?? 'C').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        feedback['clientName'] ?? 'Client',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis, // Handle text overflow
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Rating stars and date in a row
                Row(
                  children: [
                    // Star rating (wrap in a flexible widget)
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: stars,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Date
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Feedback comment section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              feedback['comment'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
              // No maxLines to allow full comment, but ensure it wraps properly
            ),
          ),

          const SizedBox(height: 16),

          // Response section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: feedback['response'] != null && feedback['response'].toString().isNotEmpty
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Response:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    feedback['response'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showResponseDialog(feedback),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Response'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF004AAD),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
              ],
            )
                : Center(
              child: ElevatedButton.icon(
                onPressed: () => _showResponseDialog(feedback),
                icon: const Icon(Icons.reply),
                label: const Text('Add Response'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004AAD),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResponseDialog(Map<String, dynamic> feedback) {
    final TextEditingController responseController = TextEditingController();

    // Pre-fill with existing response if any
    if (feedback['response'] != null && feedback['response'].toString().isNotEmpty) {
      responseController.text = feedback['response'];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFDFD),
        title: Text('Response to ${feedback['clientName']}'),
        content: TextField(
          controller: responseController,
          decoration: InputDecoration(
            hintText: 'Enter your response...',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateFeedbackResponse(
                feedback['projectId'],
                feedback['id'],
                responseController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF004AAD),
              foregroundColor: Colors.white,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFDFDFD),
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF004AAD),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment), label: 'Projects',),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}