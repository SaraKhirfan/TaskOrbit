import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../widgets/product_owner_drawer.dart';
import '../../services/sprint_service.dart';
import '../../services/RetrospectiveService.dart';
import 'PODetailedRetroReportScreen.dart';
import '../../services/FeedbackService.dart';

class POReportsAnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const POReportsAnalyticsScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<POReportsAnalyticsScreen> createState() => _POReportsAnalyticsScreenState();
}

class _POReportsAnalyticsScreenState extends State<POReportsAnalyticsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;

  // Services
  late SprintService _sprintService;
  late RetrospectiveService _retroService;

  // Data
  List<Map<String, dynamic>> sprints = [];
  List<Map<String, dynamic>> closedRetrospectives = [];
  Map<String, dynamic>? activeSprint;
  List<Map<String, dynamic>> _clientFeedback = [];
  bool _isLoadingFeedback = false;

  // Loading state
  bool _isLoading = true;

  // Retrospective reports data - will be populated with real data
  List<Map<String, dynamic>> _retrospectiveReports = [];

  @override
  void initState() {
    super.initState();
    _sprintService = Provider.of<SprintService>(context, listen: false);
    _retroService = Provider.of<RetrospectiveService>(context, listen: false);
    _loadProjectData();
    _loadClientFeedback();
  }

  Future<void> _loadProjectData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Add null safety check for project ID
      final projectId = widget.project['id'];
      if (projectId == null) {
        print('ERROR: Project ID is null');
        setState(() {
          sprints = [];
          activeSprint = null;
          closedRetrospectives = [];
          _retrospectiveReports = [];
          _isLoading = false;
        });
        return;
      }

      // Load sprints with null-safe project ID
      final projectSprints = await _sprintService.getSprints(projectId as String);

      // Load retrospectives with null-safe project ID
      await _retroService.loadRetrospectives(projectId: projectId as String);
      final closedRetros = _retroService.closedRetrospectives;

      // Find active sprint safely
      Map<String, dynamic>? foundActiveSprint;
      for (var sprint in projectSprints) {
        if (sprint['status'] == 'Active') {
          foundActiveSprint = sprint;
          break;
        }
      }

      setState(() {
        sprints = projectSprints;
        activeSprint = foundActiveSprint;
        closedRetrospectives = closedRetros;
        _retrospectiveReports = _generateRetroReports();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading project data: $e');
      setState(() {
        sprints = [];
        activeSprint = null;
        closedRetrospectives = [];
        _retrospectiveReports = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadClientFeedback() async {
    setState(() {
      _isLoadingFeedback = true;
    });

    try {
      // Add null safety check for project ID
      final projectId = widget.project['id'];
      if (projectId == null) {
        print('ERROR: Project ID is null for feedback loading');
        setState(() {
          _clientFeedback = [];
          _isLoadingFeedback = false;
        });
        return;
      }

      final feedbackService = Provider.of<FeedbackService>(context, listen: false);
      final projectFeedback = await feedbackService.getProjectFeedback(projectId as String);

      setState(() {
        _clientFeedback = projectFeedback;
        _isLoadingFeedback = false;
      });
    } catch (e) {
      print('ERROR loading client feedback: $e');
      setState(() {
        _clientFeedback = [];
        _isLoadingFeedback = false;
      });
    }
  }

// Generate retrospective reports from real data (fixed DateTime handling)
  List<Map<String, dynamic>> _generateRetroReports() {
    return closedRetrospectives.map((retro) {
      final responses = retro['responses'] as List<dynamic>? ?? [];

      // Handle closedDate safely
      DateTime dateSubmitted = DateTime.now();
      final closedDateValue = retro['closedDate'];
      if (closedDateValue is DateTime) {
        dateSubmitted = closedDateValue;
      } else if (closedDateValue is String) {
        dateSubmitted = DateTime.tryParse(closedDateValue) ?? DateTime.now();
      } else if (retro['timestamp'] != null) {
        // Fallback to timestamp if available
        final timestampValue = retro['timestamp'];
        if (timestampValue is DateTime) {
          dateSubmitted = timestampValue;
        } else if (timestampValue is String) {
          dateSubmitted = DateTime.tryParse(timestampValue) ?? DateTime.now();
        }
      }

      return {
        'name': '${retro['sprintName'] ?? 'Sprint'} Retrospective',
        'isExpanded': false,
        'sprintName': retro['sprintName'] ?? 'Unknown Sprint',
        'dateSubmitted': dateSubmitted,
        'responseCount': responses.length,
        'satisfactionScore': _calculateSatisfactionScore(responses),
        'retroId': retro['id'],
        'projectId': retro['projectId'],
        'formTitle': retro['formTitle'] ?? 'Retrospective Form',
      };
    }).toList();
  }

  // Calculate overall project progress based on sprint completion
  double _calculateProjectProgress() {
    if (sprints.isEmpty) return 0.0;

    int completedSprints = sprints
        .where((s) => s['status'] == 'Completed')
        .length;
    return completedSprints / sprints.length;
  }

  // Calculate active sprint progress (FIXED - using task completion data)
  double _calculateActiveSprintProgress() {
    if (activeSprint == null) return 0.0;

    print('=== SPRINT PROGRESS DEBUG ===');
    print('Active Sprint: ${activeSprint!['name']}');
    print('Sprint Status: ${activeSprint!['status']}');
    print('Sprint Data: $activeSprint');

    // Method 1: If sprint has progress field directly
    if (activeSprint!['progress'] != null) {
      final progress = activeSprint!['progress'];
      print('Direct progress found: $progress');
      if (progress is num) {
        return (progress / 100).clamp(0.0, 1.0);
      }
    }

    // Method 2: Calculate from task completion (you'll need TaskService for this)
    if (activeSprint!['completedTasks'] != null &&
        activeSprint!['totalTasks'] != null) {
      final completed = activeSprint!['completedTasks'] as int? ?? 0;
      final total = activeSprint!['totalTasks'] as int? ?? 0;
      print('Task completion: $completed/$total');
      if (total > 0) {
        return (completed / total).clamp(0.0, 1.0);
      }
    }

    // Method 3: If sprint status indicates completion
    if (activeSprint!['status'] == 'Completed') {
      print('Sprint marked as completed');
      return 1.0;
    }

    // Method 4: Time-based calculation (fallback)
    try {
      DateTime? startDate;
      DateTime? endDate;

      final startDateValue = activeSprint!['startDate'];
      if (startDateValue is DateTime) {
        startDate = startDateValue;
      } else if (startDateValue is String) {
        startDate = DateTime.tryParse(startDateValue);
      }

      final endDateValue = activeSprint!['endDate'];
      if (endDateValue is DateTime) {
        endDate = endDateValue;
      } else if (endDateValue is String) {
        endDate = DateTime.tryParse(endDateValue);
      }

      print('Start Date: $startDate');
      print('End Date: $endDate');

      if (startDate != null && endDate != null) {
        final now = DateTime.now();
        final totalDuration = endDate
            .difference(startDate)
            .inDays;
        final elapsedDuration = now
            .difference(startDate)
            .inDays;

        print('Total Duration: $totalDuration days');
        print('Elapsed Duration: $elapsedDuration days');
        print('Current Date: $now');

        if (totalDuration <= 0) return 0.0;
        if (elapsedDuration <= 0) return 0.0;
        if (elapsedDuration >= totalDuration) return 1.0;

        final timeProgress = (elapsedDuration / totalDuration).clamp(0.0, 1.0);
        print('Time-based progress: ${(timeProgress * 100).toInt()}%');
        return timeProgress;
      }
    } catch (e) {
      print('Error in time calculation: $e');
    }

    print('No calculation method worked, returning 0.0');
    return 0.0;
  }

  // Calculate satisfaction score from responses (simplified)
  double _calculateSatisfactionScore(List<dynamic> responses) {
    if (responses.isEmpty) return 0.0;

    double totalScore = 0.0;
    int ratingCount = 0;

    for (var response in responses) {
      if (response is Map && response.containsKey('answers')) {
        final answers = response['answers'];
        if (answers is List) {
          for (var answer in answers) {
            if (answer is Map && answer.containsKey('answer')) {
              final answerValue = answer['answer'];
              if (answerValue is int && answerValue >= 1 && answerValue <= 5) {
                totalScore += answerValue;
                ratingCount++;
              }
            }
          }
        }
      }
    }

    return ratingCount > 0 ? totalScore / ratingCount : 0.0;
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  void _toggleExpand(int index) {
    setState(() {
      // Close all other reports
      for (int i = 0; i < _retrospectiveReports.length; i++) {
        _retrospectiveReports[i]['isExpanded'] =
            (i == index) && !_retrospectiveReports[index]['isExpanded'];
      }
    });
  }


  void _openReportDetails(Map<String, dynamic> report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PODetailedRetroReportScreen(
              retroReport: report,
            ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final List<Widget> stars = List.generate(5, (index) {
      return Icon(
        index < (feedback['rating'] ?? 0) ? Icons.star : Icons.star_border,
        color: index < (feedback['rating'] ?? 0) ? Colors.amber : Colors.grey,
        size: 16,
      );
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client name and rating row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feedback['clientName'] ?? 'Client',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
              Row(children: stars),
            ],
          ),
          const SizedBox(height: 8),

          // Comment
          if (feedback['comment'] != null && feedback['comment']
              .toString()
              .isNotEmpty)
            Text(
              feedback['comment'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),

          const SizedBox(height: 8),

          // Date and sprint info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                feedback['dateSubmitted'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF999999),
                ),
              ),
              if (feedback['sprintName'] != null)
                Text(
                  feedback['sprintName'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF004AAD),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final projectCompletionRate = _calculateProjectProgress();
    final sprintCompletionRate = _calculateActiveSprintProgress();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
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
          child: ScrollbarTheme(
            data: ScrollbarThemeData(
              thumbColor: MaterialStateProperty.all(
                const Color(0xFF004AAD).withOpacity(0.4),
              ),
            ),
            child: Scrollbar(// Add this Scrollbar widget
              thumbVisibility: true, // Makes scrollbar always visible
              thickness: 8.0, // Scrollbar thickness
              radius: const Radius.circular(4.0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button and Title Row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Color(
                              0xFF004AAD)),
                          onPressed: () => Navigator.pop(context),
                          padding: const EdgeInsets.all(0),
                          constraints: const BoxConstraints(),
                        ),
                        const Text(
                          'Reports & Analytics',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Project Name
                    Padding(
                      padding: const EdgeInsets.only(left: 40),
                      child: Text(
                        widget.project['name'] ?? 'Project Name',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Overall Project Progress Section
                    const Text(
                      'Overall Project Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Row(
                              children: [
                                // Circular progress indicator
                                CircularPercentIndicator(
                                  radius: 35.0,
                                  lineWidth: 8.0,
                                  animation: true,
                                  percent: projectCompletionRate,
                                  center: Text(
                                    "${(projectCompletionRate * 100).toInt()}%",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                      color: Color(0xFF313131),
                                    ),
                                  ),
                                  circularStrokeCap: CircularStrokeCap.round,
                                  progressColor: const Color(0xFF004AAD),
                                  backgroundColor: const Color(0xFFE0E0E0),
                                ),
                                const SizedBox(width: 16),
                                // Text info - using Expanded to prevent overflow
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "${(projectCompletionRate * 100)
                                            .toInt()}% Completed",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF313131),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        sprints.isEmpty
                                            ? 'No sprints yet'
                                            : projectCompletionRate < 0.5
                                            ? 'In progress'
                                            : projectCompletionRate < 1.0
                                            ? 'On track to meet deadline'
                                            : 'Project completed',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF666666),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sprint Completion Rate Section
                    const Text(
                      'Sprint Completion Rate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Linear progress indicator - using layout builder for responsive width
                          LayoutBuilder(
                              builder: (context, constraints) {
                                return LinearPercentIndicator(
                                  width: constraints.maxWidth,
                                  animation: true,
                                  lineHeight: 20.0,
                                  animationDuration: 1000,
                                  percent: sprintCompletionRate,
                                  center: Text(
                                    "${(sprintCompletionRate * 100).toInt()}%",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  linearStrokeCap: LinearStrokeCap.roundAll,
                                  progressColor: const Color(0xFF004AAD),
                                  backgroundColor: const Color(0xFFE0E0E0),
                                );
                              }
                          ),
                          const SizedBox(height: 12),
                          // Sprint info
                          Text(
                            activeSprint != null
                                ? 'Current Sprint: ${activeSprint!['name'] ??
                                'Active Sprint'}'
                                : 'No active sprint',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            activeSprint != null
                                ? 'Sprint progress based on timeline'
                                : 'Create a sprint to track progress',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Retrospective Reports Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Retrospective Reports',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Retrospective reports list
                    if (_retrospectiveReports.isEmpty)
                      Container(
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
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.assessment_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No retrospective reports yet',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Complete sprints and retrospectives to see reports here',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF999999),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._retrospectiveReports
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final report = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(
                                  report['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sprint: ${report['sprintName']}',
                                      style: const TextStyle(
                                        color: Color(0xFF666666),
                                      ),
                                    ),
                                    Text(
                                      'Submitted: ${DateFormat('MMM dd, yyyy')
                                          .format(report['dateSubmitted'])}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF999999),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 16,
                                          color: Color(0xFF004AAD),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${report['responseCount']} responses',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF004AAD),
                                          ),
                                        ),
                                        if (report['satisfactionScore'] > 0) ...[
                                          const SizedBox(width: 16),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                size: 16,
                                                color: Colors.amber,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${report['satisfactionScore']
                                                    .toStringAsFixed(1)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF666666),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    report['isExpanded']
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: const Color(0xFF004AAD),
                                  ),
                                  onPressed: () => _toggleExpand(index),
                                ),
                                onTap: () => _openReportDetails(report),
                              ),
                              if (report['isExpanded'])
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Report Summary',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF313131),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment
                                                  .start,
                                              children: [
                                                Text(
                                                  'Responses: ${report['responseCount']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF666666),
                                                  ),
                                                ),
                                                if (report['satisfactionScore'] >
                                                    0)
                                                  Text(
                                                    'Avg Rating: ${report['satisfactionScore']
                                                        .toStringAsFixed(1)}/5.0',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Color(0xFF666666),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _openReportDetails(report),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                  0xFF004AAD),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8,
                                              ),
                                            ),
                                            child: const Text(
                                              'View Details',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),

                    const SizedBox(height: 24),

                    const Text(
                      'Client Feedback',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    const SizedBox(height: 12),

// Client Feedback Content
                    _isLoadingFeedback
                        ? const Center(child: CircularProgressIndicator())
                        : _clientFeedback.isEmpty
                        ? Container(
                      padding: const EdgeInsets.all(16),
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
                      child: const Center(
                        child: Text(
                          'No client feedback available for this project',
                          style: TextStyle(
                            color: Color(0xFF808080),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                        : Column(
                      children: _clientFeedback
                          .map((feedback) => _buildFeedbackCard(feedback))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
      selectedItemColor: MyProjectsScreen.primaryColor,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(
        fontFamily: 'Poppins-SemiBold',
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: 'Poppins-SemiBold',
        fontWeight: FontWeight.bold,
      ),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects',),
        BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}