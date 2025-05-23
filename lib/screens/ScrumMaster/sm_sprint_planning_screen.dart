import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../main.dart';
import 'SprintHistoryScreen.dart';
import 'sprint_details_screen.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../services/sprint_service.dart';

class SMSprintPlanningScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const SMSprintPlanningScreen({Key? key, required this.project})
      : super(key: key);

  @override
  _SMSprintPlanningScreenState createState() => _SMSprintPlanningScreenState();
}

class _SMSprintPlanningScreenState extends State<SMSprintPlanningScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> sprints = [];
  List<Map<String, dynamic>> completedSprints = [];
  Map<String, dynamic>? activeSprint;
  List<Map<String, dynamic>> upcomingSprints = [];
  bool _isLoading = true;
  int _selectedIndex = 1; //  tab in bottom nav

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
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sprintService = Provider.of<SprintService>(context, listen: false);
      final loadedSprints = await sprintService.getSprints(widget.project['id']);

      if (mounted) {
        // Separate sprints by status
        final active = loadedSprints.where((s) => s['status'] == 'Active').toList();
        final upcoming = loadedSprints.where((s) => s['status'] == 'Planning').toList();
        final completed = loadedSprints.where((s) => s['status'] == 'Completed').toList();

        setState(() {
          sprints = loadedSprints;
          activeSprint = active.isNotEmpty ? active.first : null;
          upcomingSprints = upcoming;
          completedSprints = completed; // Added this line
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sprints: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addNewSprint() async {
    // Show dialog to create a new sprint
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddSprintDialog(),
    );

    if (result != null) {
      try {
        final sprintService = Provider.of<SprintService>(context, listen: false);

        // Create sprint in Firestore
        final sprintId = await sprintService.createSprint(
          widget.project['id'],
          result,
        );

        // Reload sprints to get the updated list
        _loadSprints();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sprint created successfully')),
        );
      } catch (e) {
        print('Error creating sprint: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create sprint: $e')),
        );
      }
    }
  }

  void _navigateToSprintDetails(Map<String, dynamic> sprint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SprintDetailsScreen(
          sprint: sprint,
          projectId: widget.project['id'],
          projectName: widget.project['name'],
        ),
      ),
    ).then((_) {
      // Reload sprints when returning from details screen
      _loadSprints();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: SMDrawer(selectedItem: 'My Projects'),

      body:  Container(
    decoration: BoxDecoration(
    image: DecorationImage(
        image: AssetImage('assets/images/BacklogItem.png'),
    fit: BoxFit.cover,
    ),
    ),
      child:
      Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF004AAD),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Sprint Planning',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                  ],
                ),
              ),

              // Project name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  widget.project['name'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF666666),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Sprints list - replaced with categorized sections
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : (activeSprint == null && upcomingSprints.isEmpty)
                    ? Center(
                  child: Text(
                    'No sprints yet. Create a new sprint to get started.',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Sprint Section
                      if (activeSprint != null) ...[
                        Text(
                          'Active Sprint',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildSprintCard(activeSprint!, isActive: true),
                        SizedBox(height: 24),
                      ],

                      // Upcoming Sprints Section
                      if (upcomingSprints.isNotEmpty) ...[
                        Text(
                          'Up Coming',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                        SizedBox(height: 8),
                        ...upcomingSprints.map((sprint) =>
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildSprintCard(sprint, isActive: false),
                            )
                        ).toList(),
                        if (completedSprints.isNotEmpty) ...[
                          SizedBox(height: 24),

                          // Completed sprints header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Completed Sprints',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF313131),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Navigate to Sprint History screen
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SprintHistoryScreen(
                                        projectId: widget.project['id'],
                                        projectName: widget.project['name'],
                                      ),
                                    ),
                                  ).then((_) => _loadSprints());
                                },
                                child: Text('View All'),
                              ),
                            ],
                          ),

                          SizedBox(height: 8),

                          // Show only the first 2 most recent completed sprints
                          ...completedSprints.take(2).map((sprint) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildCompletedSprintCard(sprint),
                              )
                          ).toList(),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSprint,
        backgroundColor: MyApp.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
// Add this method to _SMSprintPlanningScreenState class
  Widget _buildCompletedSprintCard(Map<String, dynamic> sprint) {
    return InkWell(
      onTap: () => _navigateToSprintDetails(sprint),
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
        child: Row(
          children: [
            // Vertical line on the left (green for completed)
            Container(
              width: 5,
              height: 80,
              decoration: const BoxDecoration(
                color: Colors.green,
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
                    // Sprint name with badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            sprint['name'] ?? 'Sprint Name',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ),
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
                    SizedBox(height: 8),
                    // Date information
                    Text(
                      (sprint['startDate'] != null && sprint['endDate'] != null)
                          ? '${sprint['startDate']} - ${sprint['endDate']}'
                          : 'No date information',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Arrow icon
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSprintCard(Map<String, dynamic> sprint, {required bool isActive}) {
    // Calculate completion percentage
    final completionPercentage = sprint['progress'] as num? ?? 0;

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
      child: Row(
        children: [
          // Vertical line on the left
          Container(
            width: 5,
            height: isActive ? 120 : 80, // Shorter for upcoming sprints
            decoration: const BoxDecoration(
              color: Color(0xFF004AAD),
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
                  // Sprint name
                  Text(
                    sprint['name'] ?? 'Sprint Name',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),

                  if (isActive) ...[
                    const SizedBox(height: 8),
                    // Duration and date in a row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Duration',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            sprint['duration'] != null ? '${sprint['duration']} weeks' : 'Not set',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            (sprint['startDate'] != null && sprint['endDate'] != null)
                                ? '${sprint['startDate']} - ${sprint['endDate']}'
                                : 'Not set',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Progress bar for active sprint
                    Row(
                      children: [
                        const Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
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
                  ] else ...[
                    // For upcoming sprints, just show "Up Coming" text
                    const SizedBox(height: 4),
                    Text(
                      'Up Coming',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Navigation arrow
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Color(0xFF004AAD),
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _navigateToSprintDetails(sprint),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the existing AddSprintDialog class as is
class AddSprintDialog extends StatefulWidget {
  @override
  _AddSprintDialogState createState() => _AddSprintDialogState();
}

class _AddSprintDialogState extends State<AddSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _durationController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

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
      firstDate: DateTime.now(),
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
        _startDate = picked;

        // If duration is set, calculate end date
        if (_durationController.text.isNotEmpty) {
          int weeks = int.tryParse(_durationController.text) ?? 0;
          _endDate = picked.add(Duration(days: weeks * 7));
        }
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate != null
          ? _startDate!.add(Duration(days: 14))
          : DateTime.now().add(Duration(days: 14)),
      firstDate: _startDate ?? DateTime.now(),
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
        _endDate = picked;

        // Calculate duration based on start and end dates
        if (_startDate != null) {
          final difference = picked.difference(_startDate!).inDays;
          final weeks = (difference / 7).ceil();
          _durationController.text = weeks.toString();
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _createSprint() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both start and end dates')),
        );
        return;
      }

      final newSprint = {
        'name': _nameController.text,
        'goal': _goalController.text,
        'startDate': _formatDate(_startDate!),
        'endDate': _formatDate(_endDate!),
        'duration': int.parse(_durationController.text),
        'status': 'Planning',
        'progress': 0,
        'backlogItems': [],
      };

      Navigator.of(context).pop(newSprint);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use MediaQuery to get screen width
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust padding based on screen width
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(horizontalPadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Text(
                    'Create New Sprint',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Sprint Name
                Text(
                  'Sprint Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter sprint name',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a sprint name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),

                // Sprint Goal
                Text(
                  'Sprint Goal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _goalController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'What is the goal for this sprint?',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a sprint goal';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 12),

                // Duration
                Text(
                  'Duration (weeks)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                SizedBox(height: 6),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Number of weeks',
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
                SizedBox(height: 12),

                // Date Selection Row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Start Date
                    Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _selectStartDate(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _startDate != null ? _formatDate(_startDate!) : 'Select date',
                            ),
                            Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    // End Date
                    Text(
                      'End Date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _selectEndDate(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _endDate != null ? _formatDate(_endDate!) : 'Select date',
                            ),
                            Icon(Icons.calendar_today, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF004AAD),
                        ),
                        child: Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _createSprint,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Create Sprint', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}