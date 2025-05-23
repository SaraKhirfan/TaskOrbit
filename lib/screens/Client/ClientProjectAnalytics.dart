import 'package:flutter/material.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/clientBottomNav.dart';
import '../../widgets/client_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../widgets/sm_drawer.dart';
import '../../widgets/team_member_drawer.dart';

class ClientAnalyticsScreen extends StatefulWidget {
  final Map<String, dynamic> project;

  const ClientAnalyticsScreen({Key? key, required this.project}) : super(key: key);

  @override
  State<ClientAnalyticsScreen> createState() => _ClientAnalyticsScreenState();
}

class _ClientAnalyticsScreenState extends State<ClientAnalyticsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  // Project progress data - would come from project data in real app
  final double _projectCompletionRate = 0.22; // 22%
  final double _sprintCompletionRate = 0.40; // 40%

  // Retrospective reports data - would come from project data in real app
  final List<Map<String, dynamic>> _retrospectiveReports = [
    {
      'name': 'Sprint 1 Retrospective',
      'isExpanded': false,
      'sprintName': 'Sprint 1 - Product Backlog Setup',
      'dateSubmitted': DateTime(2023, 3, 15),
      'satisfactionScore': 4.2,
      'goodPoints': [
        'Team collaboration was excellent',
        'Clear requirements from product owner',
        'Good technical planning'
      ],
      'improvementPoints': [
        'Need more detailed acceptance criteria',
        'Better time estimation needed',
      ],
      'actionItems': [
        'Create acceptance criteria template',
        'Schedule estimation workshop',
      ],
    },
    {
      'name': 'Sprint 2 Retrospective',
      'isExpanded': false,
      'sprintName': 'Sprint 2 - Core Features',
      'dateSubmitted': DateTime(2023, 3, 29),
      'satisfactionScore': 3.8,
      'goodPoints': [
        'Increased velocity from last sprint',
        'Better test coverage',
      ],
      'improvementPoints': [
        'Communication delays between team members',
        'Some technical debt accumulated',
      ],
      'actionItems': [
        'Daily stand-up time adjustment',
        'Schedule tech debt reduction day',
      ],
    },
    {
      'name': 'Sprint 3 Retrospective',
      'isExpanded': false,
      'sprintName': 'Sprint 3 - UI Refinement',
      'dateSubmitted': DateTime(2023, 4, 12),
      'satisfactionScore': 4.5,
      'goodPoints': [
        'UI improvements well received by stakeholders',
        'Team worked well under pressure',
        'Good problem-solving for complex issues',
      ],
      'improvementPoints': [
        'Need more design review time',
        'Better coordination with external teams',
      ],
      'actionItems': [
        'Add design review to sprint planning',
        'Weekly sync with external dependencies',
      ],
    },
  ];

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/clientHome');
    if (index == 1) Navigator.pushNamed(context, '/clientProjects');
    if (index == 2) Navigator.pushNamed(context, '/clientTimeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/clientProfile');
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
    // Navigate to detailed report view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening detailed view for ${report['name']}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: ClientDrawer(selectedItem: 'Projects'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button and Title Row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                          Icons.arrow_back, color: Color(0xFF004AAD)),
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
                              percent: _projectCompletionRate,
                              center: Text(
                                "${(_projectCompletionRate * 100).toInt()}%",
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
                                    "${(_projectCompletionRate * 100)
                                        .toInt()}% Completed",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF313131),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'On track to meet deadline',
                                    style: TextStyle(
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
                              percent: _sprintCompletionRate,
                              center: Text(
                                "${(_sprintCompletionRate * 100).toInt()}%",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              barRadius: const Radius.circular(10),
                              progressColor: Colors.green,
                              backgroundColor: const Color(0xFFE0E0E0),
                            );
                          }
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${(_sprintCompletionRate * 100)
                                .toInt()}% Completed",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          const Text(
                            'Current Sprint: 3/5',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Retrospective Feedback Reports Section
                const Text(
                  'Retrospective Feedback Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                const SizedBox(height: 8),

                // List of retrospective reports with expansion panels
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _retrospectiveReports.length,
                  itemBuilder: (context, index) {
                    final report = _retrospectiveReports[index];
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
                          // Report Header - Always visible
                          InkWell(
                            onTap: () => _toggleExpand(index),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Text(
                                    report['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF313131),
                                    ),
                                  ),
                                  Icon(
                                    report['isExpanded'] ? Icons
                                        .keyboard_arrow_up : Icons
                                        .keyboard_arrow_down,
                                    color: const Color(0xFF004AAD),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expanded content - Only visible when expanded
                          if (report['isExpanded'])
                            Container(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1, thickness: 1),
                                  const SizedBox(height: 16),

                                  // Sprint info row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            const Text(
                                              'Sprint Name',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              report['sprintName'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF313131),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment
                                              .start,
                                          children: [
                                            const Text(
                                              'Date Submitted',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF666666),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              DateFormat('MMM dd, yyyy').format(
                                                  report['dateSubmitted']),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF313131),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // Satisfaction score
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment
                                        .center,
                                    children: [
                                      const Text(
                                        'Satisfaction Score:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF313131),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            Icons.star,
                                            size: 18,
                                            color: i <
                                                report['satisfactionScore']
                                                    .floor()
                                                ? Colors.amber
                                                : i <
                                                report['satisfactionScore']
                                                ? Colors.amber.withOpacity(0.5)
                                                : Colors.grey.withOpacity(0.3),
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        report['satisfactionScore'].toString(),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF313131),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),

                                  // View details button
                                  Center(
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          _openReportDetails(report),
                                      style: ElevatedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        backgroundColor: const Color(
                                            0xFF004AAD),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                        ),
                                      ),
                                      child: const Text(
                                        'View Details',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Bottom Action Bar
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.download,
                          color: Color(0xFF004AAD),
                          size: 24,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Downloading reports as PDF...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.share,
                          color: Color(0xFF004AAD),
                          size: 24,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sharing reports...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: clientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
