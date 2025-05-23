import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';
import '../../widgets/clientBottomNav.dart';
import '../../widgets/client_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../services/sprint_service.dart';
import '../../services/FeedbackService.dart';

class ClientSprintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> sprint;
  final String projectId;
  final String projectName;

  const ClientSprintDetailsScreen({
    Key? key,
    required this.sprint,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _ClientSprintDetailsScreenState createState() => _ClientSprintDetailsScreenState();
}

class _ClientSprintDetailsScreenState extends State<ClientSprintDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> backlogItems = [];
  bool _isLoading = true;
  bool _hasFeedback = false;
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/clientHome');
    if (index == 1) Navigator.pushNamed(context, '/clientProjects');
    if (index == 2) Navigator.pushNamed(context, '/clientTimeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/clientProfile');
  }

  @override
  void initState() {
    super.initState();
    _loadBacklogItems();
    _checkExistingFeedback();
  }

  Future<void> _checkExistingFeedback() async {
    if (widget.sprint['status'] == 'Completed') {
      try {
        final feedbackService = Provider.of<FeedbackService>(context, listen: false);
        final hasProvided = await feedbackService.hasProvidedFeedback(
          widget.projectId,
          widget.sprint['id'],
        );

        if (mounted) {
          setState(() {
            _hasFeedback = hasProvided;
          });
        }
      } catch (e) {
        print('Error checking feedback status: $e');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final completionPercentage = widget.sprint['progress'] as num? ?? 0;
    final isCompleted = widget.sprint['status'] == 'Completed';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: ClientDrawer(selectedItem: 'Projects'),
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
            child: _buildSprintCard(completionPercentage, isCompleted),
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
      // Add floating feedback button for completed sprints
      floatingActionButton: isCompleted
          ? FloatingActionButton.extended(
        onPressed: _hasFeedback
            ? () => _showFeedbackAlreadyProvidedDialog()
            : () => _showFeedbackDialog(),
        label: Text(_hasFeedback ? 'Feedback Provided' : 'Provide Feedback', style: TextStyle(color: Colors.white),),
        icon: Icon(_hasFeedback ? Icons.check_circle : Icons.feedback, color: Colors.white,),
        backgroundColor: _hasFeedback ? Colors.green : Color(0xFF004AAD),
      )
          : null,
      bottomNavigationBar: clientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildSprintCard(num completionPercentage, bool isCompleted) {
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
          // Vertical line on the left - green for completed
          Container(
            width: 5,
            height: 180,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : Color(0xFF313131),
              borderRadius: const BorderRadius.only(
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
                  // Sprint name and status
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

    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical priority indicator
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: Color(0xFF004AAD),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backlogItem['title'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                  if (backlogItem['description'] != null && backlogItem['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        backlogItem['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                  SizedBox(height: 8),
                  // Priority and status badges
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: priorityColor, width: 1),
                        ),
                        child: Text(
                          priority,
                          style: TextStyle(
                            fontSize: 12,
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Color(0xFF004AAD).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Color(0xFF004AAD), width: 1),
                        ),
                        child: Text(
                          backlogItem['status'] ?? 'No Status',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF004AAD),
                            fontWeight: FontWeight.bold,
                          ),
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

  // Add this method to ClientSprintDetailsScreen to get the user name
  Future<String> _getUserName() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserProfile();
      return userData?['name'] ?? 'Client';
    } catch (e) {
      print('Error getting user name: $e');
      return 'Client';
    }
  }

  void _showFeedbackDialog() async {
    int rating = 3; // Default rating
    final commentController = TextEditingController();

    // Get the current user's name
    final clientName = await _getUserName();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          // Set constraints to make dialog narrower
          insetPadding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          // Set max width to prevent overflow
          contentPadding: EdgeInsets.fromLTRB(20, 20, 20, 0),
          title: Text(
            'Sprint Feedback',
            style: TextStyle(
              color: Color(0xFF004AAD),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            width: double.maxFinite, // Constrains width to parent
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Project and Sprint info with client name - USE COLUMN INSTEAD OF ROW
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Project name - use Wrap instead of Row
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.folder_outlined, size: 16, color: Color(0xFF004AAD)),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.projectName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF004AAD),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Sprint name - use Wrap instead of Row
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.sprint['name'] ?? 'Sprint',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Client name - use Wrap instead of Row
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.grey[700]),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Feedback by: $clientName',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Rating UI - keep centered
                  Text(
                    'How would you rate this sprint?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Stars - use smaller padding
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 2, // Reduced spacing
                    children: List.generate(5, (index) {
                      return IconButton(
                        padding: EdgeInsets.all(2), // Reduced padding
                        constraints: BoxConstraints(),
                        iconSize: 28, // Smaller icon
                        icon: Icon(
                          index < rating ? Icons.star : Icons.star_border,
                          color: index < rating ? Colors.amber : Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            rating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 4),
                  Center(
                    child: Text(
                      '$rating out of 5 stars',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: rating >= 4 ? Colors.green :
                        rating >= 2 ? Colors.orange : Colors.red,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Comment
                  Text(
                    'Your feedback',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 4, // Reduced from 5
                    decoration: InputDecoration(
                      hintText: 'Share your thoughts...',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF004AAD)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final comment = commentController.text.trim();
                if (comment.isNotEmpty) {
                  _submitFeedback(rating, comment);
                  Navigator.of(context).pop();
                } else {
                  // Show validation error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter your feedback comment'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF004AAD),
              ),
              child: Text('Submit', style: TextStyle(color: Colors.white),),
            ),
          ],
        ),
      ),
    );
  }

  // Dialog shown when user has already provided feedback
  void _showFeedbackAlreadyProvidedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFF004AAD)),
            SizedBox(width: 8),
            Text('Feedback Already Provided'),
          ],
        ),
        content: Text(
          'You have already provided feedback for this sprint. Thank you for your input!',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF004AAD),
            ),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Method to submit feedback
  Future<void> _submitFeedback(int rating, String comment) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final feedbackService = Provider.of<FeedbackService>(context, listen: false);

      await feedbackService.submitFeedback(
        projectId: widget.projectId,
        projectName: widget.projectName,
        sprintId: widget.sprint['id'],
        sprintName: widget.sprint['name'] ?? 'Sprint',
        rating: rating,
        comment: comment,
      );

      if (mounted) {
        setState(() {
          _hasFeedback = true;
          _isLoading = false;
        });

        // Show success message
        _showSuccessDialog();
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit feedback. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show success message
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Thank You!'),
          ],
        ),
        content: Text(
          'Your feedback has been submitted successfully. The Product Owner will review your comments.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF004AAD),
            ),
            child: Text('OK', style: TextStyle(color: Colors.white),),
          ),
        ],
      ),
    );
  }
}