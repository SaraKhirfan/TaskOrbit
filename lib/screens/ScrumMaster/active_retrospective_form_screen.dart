import 'package:flutter/material.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:task_orbit/widgets/sm_bottom_nav.dart';
import 'package:task_orbit/widgets/sm_drawer.dart';
import 'package:provider/provider.dart';
import '../../services/RetrospectiveService.dart';

class ActiveRetrospectiveFormScreen extends StatefulWidget {
  final bool isNew;
  final Map<String, dynamic> retrospective;

  const ActiveRetrospectiveFormScreen({
    Key? key,
    required this.isNew,
    required this.retrospective,
  }) : super(key: key);

  @override
  _ActiveRetrospectiveFormScreenState createState() => _ActiveRetrospectiveFormScreenState();
}

class _ActiveRetrospectiveFormScreenState extends State<ActiveRetrospectiveFormScreen> {
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
    _currentForm = Map<String, dynamic>.from(widget.retrospective);

    if (_currentForm['questions'] != null) {
      _questions = List<Map<String, dynamic>>.from(_currentForm['questions']);
    }

    if (_currentForm['responses'] != null) {
      _responses = List<Map<String, dynamic>>.from(_currentForm['responses']);
    }

    // Load the latest data if viewing existing retrospective
    if (!widget.isNew) {
      _loadRetrospectiveDetails();
    }
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

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/scrumMasterProfile');
  }

  Future<void> _closeForm() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Close Retrospective'),
        content: Text('Are you sure you want to close this retrospective?'),
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

                // Change status to closed
                await retroService.changeStatus(
                  projectId: _currentForm['projectId'],
                  retrospectiveId: _currentForm['id'],
                  newStatus: 'Closed',
                );

                setState(() {
                  _isLoading = false;
                });

                // Return to previous screen
                Navigator.pop(context, {'action': 'close'});
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error closing retrospective: $e')),
                );
              }
            },
            child: Text('Close'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, String questionId, int index) {
    final String questionText = question['question'] ?? '';
    final String questionType = question['type'] ?? '';

    // Get responses for this question
    List<Map<String, dynamic>> questionResponses = [];

    // Process all responses for this question
    for (var response in _responses) {
      if (response.containsKey('answers') && response['answers'] is List) {
        // Find the answer for this specific question in the user's answers list
        final List<dynamic> answers = response['answers'];
        for (var answer in answers) {
          if (answer is Map && answer.containsKey('questionId') && answer['questionId'] == questionId) {
            questionResponses.add({
              'userName': response['userName'] ?? 'Unknown User',
              'answer': answer['answer'],
              'timestamp': response['timestamp'] ?? DateTime.now()
            });
            break; // Found the answer for this question from this user
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Responses (${questionResponses.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004AAD),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                if (questionResponses.isEmpty)
                  Text(
                    'No responses yet',
                    style: TextStyle(color: Colors.grey),
                  )
                else
                  Column(
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
                            Divider(),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseByType(String type, dynamic answer, Map<String, dynamic> question) {
    if (type == 'Open Ended' || type == 'text' ||
        type.toString().toLowerCase().contains('open')) {
      return Text(
        answer.toString(),
        style: TextStyle(color: Color(0xFF313131)),
      );
    } else if (type == 'Multiple Choice' || type == 'radio' ||
        type.toString().toLowerCase().contains('choice')) {
      final List<dynamic> options = question['options'] ?? [];
      if (answer is int && answer >= 0 && answer < options.length) {
        return Text(
          options[answer].toString(),
          style: TextStyle(color: Color(0xFF313131)),
        );
      } else {
        return Text(
            answer.toString(),
            style: TextStyle(color: Color(0xFF313131))
        );
      }
    } else if (type == 'Rating Scale' || type == 'rating' ||
        type.toString().toLowerCase().contains('rating')) {
      int rating = 0;
      if (answer is int) {
        rating = answer;
      } else if (answer is String) {
        rating = int.tryParse(answer) ?? 0;
      }

      return Row(
        children: List.generate(
          5, // Default to 5 if scale not specified
              (index) => Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: index < rating ? Colors.amber : Colors.grey,
            size: 20,
          ),
        ),
      );
    } else {
      return Text(
          answer.toString(),
          style: TextStyle(color: Color(0xFF313131))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublished = _currentForm['status'] == 'Open';
    final isClosed = _currentForm['status'] == 'Closed';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Retrospective Form"),
      drawer: SMDrawer(selectedItem: 'Retrospective'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and title
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
                    isPublished ? 'Retrospective Form' : (isClosed ? 'Closed Retrospective' : 'Form Preview'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
                if (isPublished)
                  ElevatedButton(
                    onPressed: _closeForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
                  // Vertical blue line
                  Container(
                    width: 5,
                    height: 100,
                    decoration: BoxDecoration(
                      color: isClosed ? const Color(0xFF00C853) : const Color(0xFF004AAD),
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
                  // Vertical blue line
                  Container(
                    width: 5,
                    height: 120,
                    decoration: BoxDecoration(
                      color: isClosed ? const Color(0xFF00C853) : const Color(0xFF004AAD),
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

            // Status and Completion Card
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
                  // Vertical line
                  Container(
                    width: 5,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isClosed ? const Color(0xFF00C853) : const Color(0xFF004AAD),
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
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isClosed ? const Color(0xFF00C853) : const Color(0xFF004AAD),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isClosed ? 'Closed' : 'Open',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
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
            ),
            SizedBox(height: 24),

            // Questions Section
            Text(
              'Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
            ),
            SizedBox(height: 12),

            // Questions
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              final questionId = 'q_$index';
              return _buildQuestionCard(question, questionId, index);
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
                    'No questions added yet',
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