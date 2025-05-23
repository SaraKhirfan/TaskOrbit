import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'sm_sprint_backlog_details_screen.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../services/sprint_service.dart';
import 'dart:async';

class SprintDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> sprint;
  final String projectId;
  final String projectName;

  const SprintDetailsScreen({
    Key? key,
    required this.sprint,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _SprintDetailsScreenState createState() => _SprintDetailsScreenState();
}

class _SprintDetailsScreenState extends State<SprintDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> backlogItems = [];
  bool _isLoading = true;
  bool _isMarkingActive = false;
  int _selectedIndex = 1;
  bool _isMarkingCompleted = false;

  StreamSubscription<DocumentSnapshot>? _sprintSubscription;
  Map<String, dynamic> _currentSprintData = {};

  @override
  void initState() {
    super.initState();
    _currentSprintData = Map.from(widget.sprint);
    _loadBacklogItems();
    _setupSprintListener();
  }

  @override
  void dispose() {
    _sprintSubscription?.cancel();
    super.dispose();
  }

  void _setupSprintListener() {
    final sprintService = Provider.of<SprintService>(context, listen: false);

    _sprintSubscription = FirebaseFirestore.instance
        .collection('projects')
        .doc(widget.projectId)
        .collection('sprints')
        .doc(widget.sprint['id'])
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && mounted) {
        setState(() {
          _currentSprintData = {
            'id': snapshot.id,
            ...snapshot.data()!,
          };
        });

        // Trigger progress recalculation
        sprintService.updateSprintProgress(widget.projectId, widget.sprint['id']);
      }
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/scrumMasterProfile');
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

  Future<void> _markSprintAsCompleted() async {
    // Show confirmation dialog first
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
            title: Text('Complete Sprint'),
            content: Text(
                'Are you sure you want to mark this sprint as completed? '
                    'This will move the sprint to the completed sprints section.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Complete Sprint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
    ) ?? false;
    if (!shouldComplete) return;
    try {
      setState(() {
        _isMarkingCompleted = true;
      });
      final sprintService = Provider.of<SprintService>(context, listen: false);

      await sprintService.updateSprint(
          widget.projectId,
          widget.sprint['id'],
          {'status': 'Completed'}
      );

      // Update local sprint data
      setState(() {
        widget.sprint['status'] = 'Completed';
        _isMarkingCompleted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sprint marked as completed!'))
      );

      // Navigate back to sprint planning
      Navigator.pop(context);
    } catch (e) {
      print('Error completing sprint: $e');

      setState(() {
        _isMarkingCompleted = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
              'Error marking sprint as completed: ${e.toString().substring(
                  0, 50)}...'))
      );
    }
  }

  // New method to mark sprint as active
  Future<void> _markSprintAsActive() async {
    try {
      setState(() {
        _isMarkingActive = true;
      });

      final sprintService = Provider.of<SprintService>(context, listen: false);
      await sprintService.markSprintAsActive(
        widget.projectId,
        widget.sprint['id'],
      );

      // Update local sprint status
      setState(() {
        widget.sprint['status'] = 'Active';
        _isMarkingActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sprint marked as active')),
      );
    } catch (e) {
      print('Error marking sprint as active: $e');

      setState(() {
        _isMarkingActive = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark sprint as active: $e')),
      );
    }
  }

  void _editSprint() async {
    // Show dialog to edit the sprint
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditSprintDialog(sprint: widget.sprint),
    );

    if (result != null) {
      try {
        final sprintService = Provider.of<SprintService>(
            context, listen: false);

        // Update sprint in Firestore
        await sprintService.updateSprint(
          widget.projectId,
          widget.sprint['id'],
          result,
        );

        // Update local sprint data
        setState(() {
          widget.sprint.addAll(result);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sprint updated successfully')),
        );
      } catch (e) {
        print('Error updating sprint: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update sprint: $e')),
        );
      }
    }
  }

  // In SprintDetailsScreen.dart
  void _navigateToUserStoryDetails(Map<String, dynamic> story) {
    // Make sure the story has all necessary data for the details screen
    story['projectId'] = widget.projectId;

    // Debug what we're passing to the details screen
    print('Navigating to details with story ID: ${story['id']}');
    print('Navigating to details with projectId: ${widget.projectId}');
    print('Navigating with story data: $story');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SMSprintBacklogDetailsScreen(
              story: story,
              projectId: widget.projectId,
            ),
      ),
    ).then((_) {
      // Reload backlog items when returning from details
      _loadBacklogItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get completion percentage
    final completionPercentage = widget.sprint['progress'] as num? ?? 0;
    final isActive = widget.sprint['status'] == 'Active';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: SMDrawer(selectedItem: 'My Projects'),

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

          // Sprint details card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSprintCard(completionPercentage),
          ),

          // After the "Mark as Active" button in the build method
// (Around line 174 in your SprintDetailsScreen.dart file)

// Show "Mark as Active" button if sprint is not active
          if (!isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: _isMarkingActive ? null : _markSprintAsActive,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF004AAD),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isMarkingActive
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text('Processing...'),
                  ],
                )
                    : Text('Mark as Active'),
              ),
            ),

// Add "Complete Sprint" button if sprint is active
          if (isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _markSprintAsCompleted,
                icon: Icon(Icons.check_circle_outline),
                label: Text('Complete Sprint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
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
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }


  Widget _buildSprintCard(num completionPercentage) {
    // Use real-time data instead of static widget.sprint data
    final sprintData = _currentSprintData.isNotEmpty ? _currentSprintData : widget.sprint;
    final progress = sprintData['progress'] as num? ?? 0;

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
              color: Color(0xFF004AAD),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),

          // Sprint content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sprint title and status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          sprintData['name'] ?? 'Sprint',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(sprintData['status']),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sprintData['status'] ?? 'Planning',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Sprint description
                  if (sprintData['description'] != null && sprintData['description'].isNotEmpty)
                    Text(
                      sprintData['description'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 16),

                  // ENHANCED: Progress section with real-time updates
                  _buildEnhancedProgressSection(progress),

                  const SizedBox(height: 12),

                  // Sprint dates
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        '${_formatDate(sprintData['startDate'])} - ${_formatDate(sprintData['endDate'])}',
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
    );
  }

// NEW: Enhanced progress section with percentage and task count
  Widget _buildEnhancedProgressSection(num progress) {
    return FutureBuilder<Map<String, int>>(
      future: _getTaskCounts(),
      builder: (context, snapshot) {
        final taskData = snapshot.data ?? {'total': 0, 'completed': 0};
        final totalTasks = taskData['total']!;
        final completedTasks = taskData['completed']!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress label with percentage and task count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '${progress.toInt()}% • $completedTasks of $totalTasks tasks',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF004AAD),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (progress / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getProgressColor(progress),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

// NEW: Get task counts for display
  Future<Map<String, int>> _getTaskCounts() async {
    try {
      int totalTasks = 0;
      int completedTasks = 0;

      for (final backlogItem in backlogItems) {
        if (backlogItem['tasks'] is List) {
          final tasks = backlogItem['tasks'] as List;
          totalTasks += tasks.length;

          for (final task in tasks) {
            final status = (task['status'] ?? '').toString().toLowerCase();
            if (status == 'done' || status == 'completed' ||
                status == 'finished' || status == 'closed') {
              completedTasks++;
            }
          }
        }
      }

      return {'total': totalTasks, 'completed': completedTasks};
    } catch (e) {
      return {'total': 0, 'completed': 0};
    }
  }

// NEW: Get progress bar color based on completion
  Color _getProgressColor(num progress) {
    if (progress >= 80) return Colors.green;
    if (progress >= 50) return Colors.orange;
    if (progress >= 25) return Color(0xFF004AAD);
    return Colors.red;
  }

// Helper method for status colors (you might already have this)
  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'planning':
      default:
        return Colors.orange;
    }
  }

// Helper method for date formatting (you might already have this)
  String _formatDate(dynamic date) {
    if (date == null) return 'No date';
    if (date is Timestamp) {
      return DateFormat('MMM dd').format(date.toDate());
    }
    if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return DateFormat('MMM dd').format(parsedDate);
      } catch (e) {
        return date;
      }
    }
    return date.toString();
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

class EditSprintDialog extends StatefulWidget {
  final Map<String, dynamic> sprint;

  const EditSprintDialog({Key? key, required this.sprint}) : super(key: key);

  @override
  _EditSprintDialogState createState() => _EditSprintDialogState();
}

class _EditSprintDialogState extends State<EditSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _goalController;
  late TextEditingController _durationController;
  String _startDate = 'Select date';
  String _endDate = 'Select date';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.sprint['name']);
    _goalController = TextEditingController(text: widget.sprint['goal']);
    _durationController = TextEditingController(
        text: widget.sprint['duration']?.toString() ?? '');
    _startDate = widget.sprint['startDate'] ?? 'Select date';
    _endDate = widget.sprint['endDate'] ?? 'Select date';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 14)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _updateSprint() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == 'Select date' || _endDate == 'Select date') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both start and end dates')),
        );
        return;
      }

      final updatedSprint = {
        'name': _nameController.text,
        'goal': _goalController.text,
        'startDate': _startDate,
        'endDate': _endDate,
        'duration': int.tryParse(_durationController.text) ?? 2,
      };

      Navigator.of(context).pop(updatedSprint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFFFDFDFD),
      title: Text(
        'Edit Sprint',
        style: TextStyle(
          color: Color(0xFF313131),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sprint Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Sprint Name',
                  labelStyle: TextStyle(color: Color(0xFF004AAD)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF004AAD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                cursorColor: Color(0xFF004AAD),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a sprint name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Sprint Goal
              TextFormField(
                controller: _goalController,
                decoration: InputDecoration(
                  labelText: 'Sprint Goal',
                  labelStyle: TextStyle(color: Color(0xFF004AAD)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF004AAD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                cursorColor: Color(0xFF004AAD),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a sprint goal';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Duration
              TextFormField(
                controller: _durationController,
                decoration: InputDecoration(
                  labelText: 'Duration (weeks)',
                  labelStyle: TextStyle(color: Color(0xFF004AAD)),
                  floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF004AAD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                cursorColor: Color(0xFF004AAD),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sprint duration';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Date Row - Converted to Column to avoid overflow
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start Date
                  Text(
                    'Start Date',
                    style: TextStyle(
                      color: Color(0xFF004AAD),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF004AAD)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_startDate),
                          Icon(Icons.calendar_today, size: 16, color: Color(
                              0xFF004AAD)),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // End Date
                  Text(
                    'End Date',
                    style: TextStyle(
                      color: Color(0xFF004AAD),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Color(0xFF004AAD)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_endDate),
                          Icon(Icons.calendar_today, size: 16, color: Color(
                              0xFF004AAD)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
        ),
        ElevatedButton(
          onPressed: _updateSprint,
          child: Text('Update Sprint'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF004AAD),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}