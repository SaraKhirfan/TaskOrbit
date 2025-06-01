import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:task_orbit/screens/Product_Owner/backlog_details_screen.dart';
import 'package:task_orbit/widgets/drawer_header.dart';
import 'package:task_orbit/screens/Product_Owner/AddBacklog.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:task_orbit/services/AuthService.dart';

import '../../widgets/product_owner_drawer.dart';

class ProductBacklogScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ProductBacklogScreen({super.key, required this.project});

  @override
  State<ProductBacklogScreen> createState() => _ProductBacklogScreenState();
}

class _ProductBacklogScreenState extends State<ProductBacklogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  String _selectedStatus = 'Draft';
  List<Map<String, dynamic>> _userStories = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    print('ProductBacklogScreen.initState for project: ${widget.project['id']}');
    _loadUserData();
    _loadBacklogItems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We don't want to call this here to avoid duplicate loading
    // and potential race conditions
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserProfile();

      if (userData != null && mounted) {
        setState(() {
          _userName = userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  // Load backlog items from Firebase
  Future<void> _loadBacklogItems() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading backlog items for project: ${widget.project['id']}');
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final backlogItems = await projectService.getProjectBacklogs(widget.project['id']);
      print('Loaded ${backlogItems.length} backlog items from Firebase');

      // Log the backlog items for debugging
      for (var item in backlogItems) {
        print('Backlog item: ${item['title']} (${item['id']}) - Status: ${item['status']}');
      }

      if (mounted) {
        setState(() {
          _userStories = backlogItems;
          _isLoading = false;
        });
        print('State updated with ${_userStories.length} backlog items');
      }
    } catch (e) {
      print('Error loading backlog items: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: MyProjectsScreen.primaryColor,
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
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BacklogItem.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Product Backlog',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                    textAlign : TextAlign.center,
                  ),
                ],
              ),
              Text(
                widget.project['name'],
                style: const TextStyle(fontSize: 16, color: Color(0xFF313131)),
              ),
              const SizedBox(height: 12),
              _buildBody(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF004AAD),
        onPressed: () => _navigateToAddStoryScreen(),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _navigateToAddStoryScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddBacklogScreen(
          projectId: widget.project['id'],
          projectName: widget.project['name'],
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      print('Backlog item added, refreshing list');
      // THIS IS THE KEY CHANGE - completely reload the list from Firestore
      await _loadBacklogItems();
    }
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusTabs(),
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6, // Adjust height as needed
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            thickness: 6,
            radius: const Radius.circular(10),
            child: _buildUserStoryList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTabs() {
    return Row(
      children:
      ['Draft', 'Ready', 'In Sprint'].map((status) {
        final isSelected = _selectedStatus == status;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor:
                isSelected
                    ? const Color(0xFF004AAD)
                    : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => setState(() => _selectedStatus = status),
              child: Text(
                status,
                style: TextStyle(
                  color:
                  isSelected ? Colors.white : const Color(0xFF004AAD),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserStoryList() {
    // Print all stories for debugging
    print('Building user story list with ${_userStories.length} total items');

    final filteredStories = _userStories.where((story) {
      print('Checking story: ${story['title']} with status: ${story['status']} against selected: $_selectedStatus');
      return story['status'] == _selectedStatus;
    }).toList();

    print('Filtered to ${filteredStories.length} stories with status: $_selectedStatus');

    if (filteredStories.isEmpty) {
      return Center(
        child: Text(
          'No $_selectedStatus backlog items yet',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(right: 8),
      itemCount: filteredStories.length,
      itemBuilder: (context, index) {
        final story = filteredStories[index];
        return _UserStoryCard(
          story: story,
          onTap: () {
            // Navigate to details screen with project ID
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BacklogDetailsScreen(
                  projectId: widget.project['id'],
                  story: {
                    ...story,
                    'projectId': widget.project['id'],
                  },
                ),
              ),
            ).then((updatedStory) async {
              if (updatedStory != null && updatedStory is Map<String, dynamic>) {
                // Refresh the list
                await _loadBacklogItems();
              }
            });
          },
        );
      },
    );
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFDFDFD),
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: MyProjectsScreen.primaryColor,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects',),
        BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

class _UserStoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback onTap;

  const _UserStoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Blue vertical line
              Container(
                width: 5,
                color: const Color(0xFF004AAD),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        story['description'] ?? 'No description',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildPriorityChip(story['priority'] ?? 'Medium'),
                          if (story['dueDate'] != null && story['dueDate'].isNotEmpty)
                            Text(
                              story['dueDate'],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color color;
    switch (priority) {
      case 'High':
        color = Colors.red;
        break;
      case 'Medium':
        color = Colors.orange;
        break;
      case 'Low':
        color = Colors.green;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        priority,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}