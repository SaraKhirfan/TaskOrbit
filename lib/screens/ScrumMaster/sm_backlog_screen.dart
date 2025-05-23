import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sm_backlog_details_screen.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../services/project_service.dart';

class ScrumMasterBacklogScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ScrumMasterBacklogScreen({super.key, required this.project});

  @override
  State<ScrumMasterBacklogScreen> createState() =>
      _ScrumMasterBacklogScreenState();
}

class _ScrumMasterBacklogScreenState extends State<ScrumMasterBacklogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedStatus = 'Ready';
  List<Map<String, dynamic>> _userStories = [];
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 1; //  tab in bottom nav
  bool _isLoading = true;

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
  void initState() {
    super.initState();
    _loadBacklogItems();
  }

  Future<void> _loadBacklogItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(
          context, listen: false);
      // Use the specialized method that only gets Ready and In Sprint items
      final backlogItems = await projectService.getScrumMasterBacklogs(
          widget.project['id']);

      if (mounted) {
        setState(() {
          _userStories = backlogItems;
          _isLoading = false;
        });
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: SMDrawer(selectedItem: 'My Projects'),

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
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF004AAD),
                    ),
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
                    textAlign: TextAlign.center,
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
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatusTabs(),
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery
              .of(context)
              .size
              .height * 0.6,
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
      ['Ready', 'In Sprint'].map((status) {
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
    final filteredStories =
    _userStories
        .where((story) => story['status'] == _selectedStatus)
        .toList();

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
            // First load the backlog tasks
            _navigateToBacklogDetails(story);
          },
        );
      },
    );
  }

  Future<void> _navigateToBacklogDetails(Map<String, dynamic> story) async {
    try {
      // Load the tasks for this backlog item
      final projectService = Provider.of<ProjectService>(
          context, listen: false);
      final tasks = await projectService.getBacklogTasks(
          widget.project['id'],
          story['id']
      );

      // Create a copy of the story with tasks included and add projectId
      final storyWithTasks = Map<String, dynamic>.from(story);
      storyWithTasks['tasks'] = tasks;

      // Add the project ID - this is the key fix!
      storyWithTasks['projectId'] = widget.project['id'];

      print('Adding projectId to story before navigation: ${widget
          .project['id']}');

      // Navigate to the details screen
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SMBacklogDetailsScreen(story: storyWithTasks),
        ),
      );

      // Handle the result if the status was changed
      if (result != null && result is Map<String, dynamic>) {
        // Update the backlog item in Firestore
        if (result['status'] != story['status']) {
          await projectService.updateBacklogItem(
              widget.project['id'],
              story['id'],
              {'status': result['status'], 'sprint': result['sprint']}
          );

          // Refresh the list
          _loadBacklogItems();
        }
      }
    } catch (e) {
      print('Error navigating to backlog details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading backlog details: $e')),
      );
    }
  }
}

class _UserStoryCard extends StatelessWidget {
  final Map<String, dynamic> story;
  final VoidCallback onTap;

  const _UserStoryCard({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String priority = story['priority'] ?? 'Medium';
    Color priorityColor = priority == 'High'
        ? Colors.red
        : priority == 'Medium'
        ? Colors.orange
        : Colors.green;

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
        child: IntrinsicHeight( // This ensures the blue line matches card height
          child: Row(
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration( // Removed fixed height
                  color: Color(0xFF004AAD),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['title'] ?? 'Untitled Story', // Changed from 'User Story'
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text('Priority Indicator'),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Due Date'),
                              Text(
                                story['dueDate'] ?? 'No date',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ],
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF004AAD),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.arrow_forward),
                              color: Colors.white,
                              onPressed: onTap,
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
}