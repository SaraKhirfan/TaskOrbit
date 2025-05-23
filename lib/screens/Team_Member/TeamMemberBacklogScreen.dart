import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import '../../widgets/TMBottomNav.dart';
import 'team_member_product_backlog_detail_screen.dart';

class TeamMemberBacklogScreen extends StatefulWidget {
  final String projectId;

  const TeamMemberBacklogScreen({super.key, required this.projectId});

  @override
  State<TeamMemberBacklogScreen> createState() => _TeamMemberBacklogScreenState();
}

class _TeamMemberBacklogScreenState extends State<TeamMemberBacklogScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedStatus = 'In Sprint';  // Default to In Sprint for team members
  List<Map<String, dynamic>> _userStories = [];
  final ScrollController _scrollController = ScrollController();
  int _selectedIndex = 1; // Projects tab in bottom nav
  bool _isLoading = true;
  Map<String, dynamic>? _project;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushReplacementNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushReplacementNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushReplacementNamed(context, '/tmMyProfile');
  }

  @override
  void initState() {
    super.initState();
    _loadProjectData();
    _loadBacklogItems();
  }

  Future<void> _loadProjectData() async {
    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final project = projectService.getProjectById(widget.projectId);

      if (project != null) {
        setState(() {
          _project = project;
        });
      } else {
        // If not found, try to refresh projects from Firebase
        await projectService.refreshProjects();

        // Check again after refresh
        final refreshedProject = projectService.getProjectById(widget.projectId);

        setState(() {
          _project = refreshedProject;
        });
      }
    } catch (e) {
      print('Error loading project data: $e');
    }
  }

  Future<void> _loadBacklogItems() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      // Get backlog items for team members (focus on In Sprint items)
      final backlogItems = await projectService.getTeamMemberBacklogs(widget.projectId);

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
      drawer: TeamMemberDrawer(selectedItem: 'Projects'),
      body: Container(
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
                  const Text(
                    'Product Backlog',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              Text(
                _project != null ? (_project!['name'] ?? '') : '',
                style: const TextStyle(fontSize: 16, color: Color(0xFF313131)),
              ),
              const SizedBox(height: 12),
              _buildBody(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TMBottomNav(
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
          height: MediaQuery.of(context).size.height * 0.6,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
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
      children: ['In Sprint'].map((status) {
        final isSelected = _selectedStatus == status;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFF004AAD) : Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => setState(() => _selectedStatus = status),
              child: Text(
                status,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF004AAD),
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
    final filteredStories = _userStories
        .where((story) => story['status'] == _selectedStatus)
        .toList();

    if (filteredStories.isEmpty) {
      return Center(
        child: Text(
          'No $_selectedStatus backlog items assigned to you',
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
            _navigateToBacklogDetails(story);
          },
        );
      },
    );
  }

  Future<void> _navigateToBacklogDetails(Map<String, dynamic> story) async {
    try {
      // Load the tasks for this backlog item
      final projectService = Provider.of<ProjectService>(context, listen: false);
      final tasks = await projectService.getBacklogTasks(
          widget.projectId,
          story['id']
      );

      // Create a copy of the story with tasks included
      final storyWithTasks = Map<String, dynamic>.from(story);
      storyWithTasks['tasks'] = tasks;

      // Navigate to the details screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamMemberProductBacklogDetailScreen(backlogItem: storyWithTasks),
        ),
      );
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
    Color priorityColor = priority == 'High' ? Colors.red : Colors.green;

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
        child: Row(
          children: [
            Container(
              width: 5,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF004AAD),
                borderRadius: const BorderRadius.only(
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
                    const Text(
                      'User Story',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Priority Indicator'),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            priority,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      story['description'] ?? 'No description',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Due Date'),
                            Text(
                              story['dueDate'] ?? 'No date',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF004AAD),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_forward),
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
    );
  }
}