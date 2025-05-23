import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/team_member_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../services/sprint_service.dart';
import 'NonSMSprintBacklogDetailsScreen.dart';

class NonSmSprintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> sprint;
  final String projectId;
  final String projectName;

  const NonSmSprintDetailsScreen({
    Key? key,
    required this.sprint,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _NonSmSprintDetailsScreenState createState() => _NonSmSprintDetailsScreenState();
}

class _NonSmSprintDetailsScreenState extends State<NonSmSprintDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> backlogItems = [];
  bool _isLoading = true;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
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
        builder: (context) =>
            NonSMSprintBacklogDetailsScreen(
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
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: TeamMemberDrawer(selectedItem: 'Projects'),
      body: SingleChildScrollView( // Make the entire body scrollable
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                        Icons.arrow_back, color: Color(0xFF004AAD)),
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

            // User stories list - Remove Expanded and use ListView with shrinkWrap
            _isLoading
                ? Container(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
                : backlogItems.isEmpty
                ? Container(
              height: 200,
              child: Center(
                child: Text(
                  'No backlog items in this sprint yet.\nAdd items from the Product Backlog.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              // Allow ListView to take only needed space
              physics: NeverScrollableScrollPhysics(),
              // Disable ListView scrolling since parent scrolls
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: backlogItems.length,
              itemBuilder: (context, index) {
                final story = backlogItems[index];
                return _buildBacklogItemCard(story);
              },
            ),

            // Add bottom padding to ensure content is not cut off
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildSprintCard(num completionPercentage) {
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
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF313131),
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
                  // Sprint name and edit button
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
                            color: const Color(0xFF00D45E),
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
                              widget.sprint['duration'] != null ? '${widget
                                  .sprint['duration']} weeks' : 'Not set',
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
                              (widget.sprint['startDate'] != null &&
                                  widget.sprint['endDate'] != null)
                                  ? '${widget.sprint['startDate']} - ${widget
                                  .sprint['endDate']}'
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

    return GestureDetector(
      onTap: () => _navigateToUserStoryDetails(backlogItem),
      child: Container(
        // Remove fixed height to allow flexible sizing
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
        child: IntrinsicHeight( // Allow container to size based on content
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
                    children: [
                      // Title with proper text wrapping
                      Text(
                        backlogItem['title'] ?? 'User Story',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                        maxLines: null, // Allow unlimited lines
                        overflow: TextOverflow.visible, // Don't truncate
                      ),

                      const SizedBox(height: 8),

                      // Description with proper text wrapping
                      Text(
                        backlogItem['description'] ??
                            'No description available',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                        maxLines: null, // Allow unlimited lines
                        overflow: TextOverflow.visible, // Don't truncate
                      ),

                      const SizedBox(height: 12),

                      // Priority and task count row
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

                          // Task count
                          Text(
                            '${(backlogItem['tasks'] as List?)?.length ??
                                0} tasks',
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