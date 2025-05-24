import 'package:flutter/material.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/RetrospectiveService.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/clientBottomNav.dart';
import '../../widgets/client_drawer.dart';
import '../../widgets/team_member_drawer.dart';

class CDetailedRetroReportScreen extends StatefulWidget {
  final Map<String, dynamic> retroReport;

  const CDetailedRetroReportScreen({
    Key? key,
    required this.retroReport,
  }) : super(key: key);

  @override
  _CDetailedRetroReportScreenState createState() => _CDetailedRetroReportScreenState();
}

class _CDetailedRetroReportScreenState extends State<CDetailedRetroReportScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isLoading = false;

  // Form data
  Map<String, dynamic> _currentRetro = {};
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _responses = [];

  @override
  void initState() {
    super.initState();
    _loadRetrospectiveDetails();
  }

  Future<void> _loadRetrospectiveDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final retroService = Provider.of<RetrospectiveService>(context, listen: false);

      // Get the full retrospective data using the IDs from the report
      final retroDetails = await retroService.getRetrospective(
        projectId: widget.retroReport['projectId'],
        retrospectiveId: widget.retroReport['retroId'],
      );

      if (retroDetails != null) {
        setState(() {
          _currentRetro = retroDetails;

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
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  Widget _buildQuestionAnalysis(Map<String, dynamic> question, int index) {
    final String questionText = question['question'] ?? '';
    final String questionType = question['type'] ?? '';
    final String questionId = 'q_$index';

    // Get all responses for this question (WITHOUT user names)
    List<dynamic> questionResponses = [];
    for (var response in _responses) {
      if (response.containsKey('answers') && response['answers'] is List) {
        final List<dynamic> answers = response['answers'];
        for (var answer in answers) {
          if (answer is Map && answer['questionId'] == questionId) {
            questionResponses.add(answer['answer']);
            break;
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

          // Analysis content based on question type
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Analysis (${questionResponses.length} responses)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004AAD),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                if (questionResponses.isEmpty)
                  Text('No responses collected', style: TextStyle(color: Colors.grey))
                else
                  _buildAnalysisByType(questionType, questionResponses, question),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisByType(String type, List<dynamic> responses, Map<String, dynamic> question) {
    if (type == 'Rating Scale' || type == 'rating' || type.toString().toLowerCase().contains('rating')) {
      return _buildRatingAnalysis(responses, question);
    } else if (type == 'Multiple Choice' || type == 'radio' || type.toString().toLowerCase().contains('choice')) {
      return _buildMultipleChoiceAnalysis(responses, question);
    } else {
      // Open-ended questions
      return _buildOpenEndedAnalysis(responses);
    }
  }

  Widget _buildRatingAnalysis(List<dynamic> responses, Map<String, dynamic> question) {
    Map<int, int> ratingCounts = {};
    double totalRating = 0;
    int validResponses = 0;

    // Count ratings
    for (var response in responses) {
      int rating = 0;
      if (response is int) {
        rating = response;
      } else if (response is String) {
        rating = int.tryParse(response) ?? 0;
      }

      if (rating > 0 && rating <= 5) {
        ratingCounts[rating] = (ratingCounts[rating] ?? 0) + 1;
        totalRating += rating;
        validResponses++;
      }
    }

    double averageRating = validResponses > 0 ? totalRating / validResponses : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average rating
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Average Rating: ${averageRating.toStringAsFixed(1)}/5.0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Rating distribution
        Text(
          'Rating Distribution:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF313131),
          ),
        ),
        SizedBox(height: 8),

        ...List.generate(5, (index) {
          int rating = 5 - index; // Start from 5 stars down to 1
          int count = ratingCounts[rating] ?? 0;
          double percentage = validResponses > 0 ? (count / validResponses) * 100 : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Stars
                Row(
                  children: List.generate(rating, (i) =>
                      Icon(Icons.star, color: Colors.amber, size: 16)
                  ),
                ),
                SizedBox(width: 8),

                // Progress bar
                Expanded(
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF004AAD),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),

                // Count and percentage
                Text(
                  '$count (${percentage.toInt()}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMultipleChoiceAnalysis(List<dynamic> responses, Map<String, dynamic> question) {
    final List<dynamic> options = question['options'] ?? [];
    Map<String, int> optionCounts = {};

    // Count option selections
    for (var response in responses) {
      String selectedOption = '';
      if (response is int && response >= 0 && response < options.length) {
        selectedOption = options[response].toString();
      } else {
        selectedOption = response.toString();
      }

      if (selectedOption.isNotEmpty) {
        optionCounts[selectedOption] = (optionCounts[selectedOption] ?? 0) + 1;
      }
    }

    int totalResponses = responses.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Response Distribution:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF313131),
          ),
        ),
        SizedBox(height: 12),

        ...optionCounts.entries.map((entry) {
          double percentage = totalResponses > 0 ? (entry.value / totalResponses) * 100 : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF313131),
                        ),
                      ),
                    ),
                    Text(
                      '${entry.value} (${percentage.toInt()}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF004AAD),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildOpenEndedAnalysis(List<dynamic> responses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'All Responses:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF313131),
          ),
        ),
        SizedBox(height: 8),

        ...responses.asMap().entries.map((entry) {
          int index = entry.key;
          String response = entry.value.toString();

          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Color(0xFF004AAD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    response,
                    style: TextStyle(
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: ClientDrawer(selectedItem: 'Projects'),
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
                    'Retrospective Report',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Report info card
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
                    height: 100,
                    decoration: BoxDecoration(
                      color: Color(0xFF004AAD),
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
                          Text(
                            widget.retroReport['name'] ?? 'Retrospective Report',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Sprint: ${widget.retroReport['sprintName'] ?? 'Unknown Sprint'}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Submitted: ${DateFormat('MMM dd, yyyy').format(widget.retroReport['dateSubmitted'])}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF999999),
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.people_outline, size: 16, color: Color(0xFF004AAD)),
                              SizedBox(width: 4),
                              Text(
                                '${widget.retroReport['responseCount']} responses',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF004AAD),
                                  fontWeight: FontWeight.w500,
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

            // Questions analysis
            if (_questions.isNotEmpty) ...[
              Text(
                'Detailed Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
              SizedBox(height: 16),

              Column(
                children: _questions.asMap().entries.map((entry) {
                  final int index = entry.key;
                  final Map<String, dynamic> question = entry.value;
                  return _buildQuestionAnalysis(question, index);
                }).toList(),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No data available for analysis',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],

            SizedBox(height: 80), // Space for bottom navigation
          ],
        ),
      ),
      bottomNavigationBar: clientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}