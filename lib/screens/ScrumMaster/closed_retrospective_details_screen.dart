import 'package:flutter/material.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:task_orbit/widgets/sm_bottom_nav.dart';
import 'package:task_orbit/widgets/sm_drawer.dart';
import 'package:provider/provider.dart';
import '../../services/RetrospectiveService.dart';

class ClosedRetrospectiveDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> closedForm;

  const ClosedRetrospectiveDetailsScreen({
    Key? key,
    required this.closedForm,
  }) : super(key: key);

  @override
  _ClosedRetrospectiveDetailsScreenState createState() =>
      _ClosedRetrospectiveDetailsScreenState();
}

class _ClosedRetrospectiveDetailsScreenState extends State<ClosedRetrospectiveDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // tab in bottom nav
  bool _isLoading = false;

  // Form data
  Map<String, dynamic> _currentForm = {};
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _responses = [];

  @override
  void initState() {
    super.initState();
    _currentForm = Map<String, dynamic>.from(widget.closedForm);

    if (_currentForm['questions'] != null) {
      _questions = List<Map<String, dynamic>>.from(_currentForm['questions']);
    }

    if (_currentForm['responses'] != null) {
      _responses = List<Map<String, dynamic>>.from(_currentForm['responses']);
    }

    // Fetch the latest retrospective data
    _loadRetrospectiveDetails();
  }

  Future<void> _loadRetrospectiveDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final retroService = Provider.of<RetrospectiveService>(context, listen: false);

      // Get the latest retrospective data
      final retroDetails = await retroService.getRetrospective(
        projectId: _currentForm['projectId'],
        retrospectiveId: _currentForm['id'],
      );

      if (retroDetails != null) {
        setState(() {
          _currentForm = retroDetails;

          if (retroDetails['questions'] != null) {
            _questions = List<Map<String, dynamic>>.from(retroDetails['questions']);
          }

          if (retroDetails['responses'] != null) {
            _responses = List<Map<String, dynamic>>.from(retroDetails['responses']);
          }
        });

        // DEBUG: Print data to see what we're getting
        _debugPrintData();
      } else {
        print('No retrospective details found!');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading retrospective details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _debugPrintData() {
    print('=== DEBUG RETROSPECTIVE DATA ===');
    print('Current Form ID: ${_currentForm['id']}');
    print('Project ID: ${_currentForm['projectId']}');
    print('Questions count: ${_questions.length}');
    print('Responses count: ${_responses.length}');

    print('\n--- Questions ---');
    for (int i = 0; i < _questions.length; i++) {
      print('Q$i: ${_questions[i]}');
    }

    print('\n--- Responses ---');
    for (int i = 0; i < _responses.length; i++) {
      print('Response $i: ${_responses[i]}');
    }
    print('=== END DEBUG ===\n');
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

  Future<void> _deleteForm() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Retrospective'),
        content: Text('Are you sure you want to delete this retrospective? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              setState(() {
                _isLoading = true;
              });

              try {
                // Get retrospective service
                final retroService = Provider.of<RetrospectiveService>(context, listen: false);

                // Delete the form
                await retroService.deleteRetrospective(
                  projectId: _currentForm['projectId'],
                  retrospectiveId: _currentForm['id'],
                );

                setState(() {
                  _isLoading = false;
                });

                // Return to previous screen
                Navigator.pop(context, {'action': 'delete'});
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting retrospective: $e')),
                );
              }
            },
            child: Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionResponseSummary(Map<String, dynamic> question, int index) {
    final String questionText = question['question'] ?? '';
    final String questionType = question['type'] ?? '';
    final String questionId = 'q_$index';

    // Get all responses for this question (FIXED STRUCTURE)
    List<dynamic> questionResponses = [];
    for (var response in _responses) {
      if (response.containsKey('answers') && response['answers'] is List) {
        // Find the answer for this specific question
        final List<dynamic> answers = response['answers'];

        for (var answerObj in answers) {
          if (answerObj is Map &&
              answerObj['questionId'] == questionId) {
            questionResponses.add({
              'userName': response['userName'] ?? 'Unknown User',
              'answer': answerObj['answer']
            });
            break; // Found the answer for this question
          }
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    questionText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    questionType,
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF616161),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Responses
          Padding(
            padding: EdgeInsets.all(16),
            child: questionResponses.isEmpty
                ? Text('No responses yet', style: TextStyle(color: Colors.grey))
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: questionResponses.map((response) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response['userName'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF004AAD),
                        ),
                      ),
                      SizedBox(height: 4),
                      _buildResponseByType(questionType, response['answer'], question),
                      if (questionResponses.indexOf(response) < questionResponses.length - 1)
                        Divider(),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseByType(String type, dynamic answer, Map<String, dynamic> question) {
    if (type == 'Open Ended') {
      return Text(
        answer.toString(),
        style: TextStyle(color: Color(0xFF313131)),
      );
    } else if (type == 'Multiple Choice') {
      final List<dynamic> options = question['options'] ?? [];
      if (answer is int && answer >= 0 && answer < options.length) {
        return Text(
          options[answer].toString(),
          style: TextStyle(color: Color(0xFF313131)),
        );
      } else {
        return Text(answer.toString(), style: TextStyle(color: Color(0xFF313131)));
      }
    } else if (type == 'Rating Scale') {
      return Row(
        children: List.generate(
          question['scale'] ?? 5,
              (index) => Icon(
            index < (answer as int) ? Icons.star : Icons.star_border,
            color: index < (answer as int) ? Colors.amber : Colors.grey,
            size: 20,
          ),
        ),
      );
    } else {
      return Text(answer.toString(), style: TextStyle(color: Color(0xFF313131)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Closed Retrospective"),
      drawer: SMDrawer(selectedItem: 'Retrospective'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button, title and delete button
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Closed Retrospective',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteForm,
                  tooltip: 'Delete Retrospective',
                ),
              ],
            ),
            SizedBox(height: 24),

            // Project & Sprint Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Vertical green line
                  Container(
                    width: 5,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
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
                          // Project
                          Text(
                            'Project',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _currentForm['projectName'] ?? 'Project Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Sprint
                          Text(
                            'Sprint',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _currentForm['sprintName'] ?? 'Sprint Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Form Information Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Vertical green line
                  Container(
                    width: 5,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
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
                          // Form Title
                          Text(
                            'Form Title',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _currentForm['formTitle'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          SizedBox(height: 16),

                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            _currentForm['description'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF313131),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Status Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Vertical green line
                  Container(
                    width: 5,
                    height: 80,
                    decoration: BoxDecoration(
                      color:Colors.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
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
                          // Status
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Closed',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),

                          // Completion rate
                          Row(
                            children: [
                              Text(
                                'Completion Rate',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '${_currentForm['completionRate'] ?? 0}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF313131),
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
            SizedBox(height: 24),

            // Responses Section
            Text(
              'Responses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${_responses.length} team members responded',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 16),

            // Question responses
            ..._questions.asMap().entries.map((entry) {
              return _buildQuestionResponseSummary(entry.value, entry.key);
            }).toList(),

            // Empty state if no questions
            if (_questions.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Text(
                    'No questions in this retrospective',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}