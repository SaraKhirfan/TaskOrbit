import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/product_owner_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../services/sprint_service.dart';
import '../Team_Member/NonSMSprintBacklogDetailsScreen.dart';
import 'POsprintBacklogDetailsScreen.dart';

class POSprintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> sprint;
  final String projectId;
  final String projectName;

  const POSprintDetailsScreen({
    Key? key,
    required this.sprint,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _POSprintDetailsScreenState createState() => _POSprintDetailsScreenState();
}

class _POSprintDetailsScreenState extends State<POSprintDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> backlogItems = [];
  bool _isLoading = true;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  @override
  void initState() {
    super.initState();
    _loadBacklogItems();
  }

  Future<void> _loadBacklogItems() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sprintService = Provider.of<SprintService>(context, listen: false);
      final items = await sprintService.getSprintBacklogItems(
        widget.projectId,
        widget.sprint['id'],
      );

      if (mounted) {
        setState(() {
          backlogItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading backlog items for sprint: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToUserStoryDetails(Map<String, dynamic> story) {
    story['projectId'] = widget.projectId;
    print('Navigating to details with story ID: ${story['id']}');
    print('Navigating to details with projectId: ${widget.projectId}');
    print('Navigating with story data: $story');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => POSprintBacklogDetailsScreen(
          story: story,
          projectId: widget.projectId,
        ),
      ),
    ).then((_) {
      _loadBacklogItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final completionPercentage = widget.sprint['progress'] as num? ?? 0;
    final isActive = widget.sprint['status'] == 'Active';
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: AppBar(
        backgroundColor: Color(0xFFFDFDFD),
        foregroundColor: Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: Color(0xFF004AAD),
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
            color: Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSprintCard(completionPercentage),
          ),

          const SizedBox(height: 16),

          // Product Backlog title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sprint Backlog Items',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                Text(
                  '${backlogItems.length} items',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),

          // User stories list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : backlogItems.isEmpty
                ? Center(
              child: Text(
                'No backlog items in this sprint yet.\nAdd items from the Product Backlog.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: backlogItems.length,
              itemBuilder: (context, index) {
                final story = backlogItems[index];
                return _buildBacklogItemCard(story);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(),
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
        BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }


  Widget _buildSprintCard(num completionPercentage) {
    // Check if the sprint is completed
    final bool isCompleted = widget.sprint['status'] == 'Completed';

    return Container(
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
            height: isCompleted ? 210 : 180, // Increase height when showing the feedback button
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : const Color(0xFF313131),
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
                  // Sprint name and status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.sprint['name'] ?? 'Sprint Name',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                      ),
                      if (isCompleted)
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

                  // Sprint goal
                  Text(
                    'Sprint Goal',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),

                  Text(
                    widget.sprint['goal'] ?? 'No goal set for this sprint',
                    style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                    maxLines: null, // Allow any number of lines
                    overflow: TextOverflow.visible, // Don't truncate the text
                  ),

                  const SizedBox(height: 16),

                  // Progress with progress bar
                  Row(
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: completionPercentage / 100,
                            backgroundColor: Colors.grey[200],
                            color: isCompleted ? Colors.green : const Color(0xFF00D45E),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${completionPercentage.toStringAsFixed(0)}% completed',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Duration and date in a row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                            ),
                            Text(
                              widget.sprint['duration'] != null ? '${widget.sprint['duration']} weeks' : 'Not set',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF313131),
                              ),
                            ),
                            Text(
                              (widget.sprint['startDate'] != null && widget.sprint['endDate'] != null)
                                  ? '${widget.sprint['startDate']} - ${widget.sprint['endDate']}'
                                  : 'Not set',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Add View Client Feedback button for completed sprints
                  if (isCompleted) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        Navigator.pushNamed(context, '/clientsFeedback');
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'View Client Feedback',
                            style: TextStyle(
                              color: Color(0xFF004AAD),
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Color(0xFF004AAD),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBacklogItemCard(Map<String, dynamic> backlogItem) {
    final priority = backlogItem['priority'] as String? ?? 'Medium';
    Color priorityColor;

    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      case 'low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    // Get the actual task count from the loaded tasks array
    final tasksList = backlogItem['tasks'] as List?;
    final actualTaskCount = tasksList?.length ?? 0;

    // Debug: Print to see the difference
    print('Backlog item ${backlogItem['id']} reports ${actualTaskCount} tasks');
    if (tasksList != null) {
      print('Task IDs: ${tasksList.map((t) => t['id']).toList()}');
    }

    return GestureDetector(
      onTap: () => _navigateToUserStoryDetails(backlogItem),
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Blue line on the left
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF004AAD),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Title
                      Text(
                        backlogItem['title'] ?? 'User Story',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Bottom row with priority and task count
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Priority
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priority,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Task count with proper count
                          Text(
                            '$actualTaskCount tasks',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Arrow icon
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF004AAD),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}