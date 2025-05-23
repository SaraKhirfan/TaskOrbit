import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/RetrospectiveService.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamMemberRetrospectiveFormScreen extends StatefulWidget {
  final Map<String, dynamic> form;
  final bool viewOnly;

  const TeamMemberRetrospectiveFormScreen({
    Key? key,
    required this.form,
    this.viewOnly = false,
  }) : super(key: key);

  @override
  State<TeamMemberRetrospectiveFormScreen> createState() => _TeamMemberRetrospectiveFormScreenState();
}

class _TeamMemberRetrospectiveFormScreenState extends State<TeamMemberRetrospectiveFormScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  int _selectedIndex = 0;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add this variable to track edit mode
  bool _isEditMode = false;

  // Form responses
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, int?> _multipleChoiceSelections = {};
  final Map<String, int> _ratingSelections = {};

  // User's previous responses (if any)
  Map<String, dynamic>? _previousResponses;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and selections
    _initializeControllers();

    // Load previous responses if view-only mode
    if (widget.viewOnly) {
      _loadPreviousResponses();
    }
  }

  @override
  void dispose() {
    // Dispose all text controllers
    _textControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _initializeControllers() {
    // Initialize controllers based on question types
    if (widget.form['questions'] != null && widget.form['questions'] is List) {
      final questions = List<Map<String, dynamic>>.from(widget.form['questions']);

      for (int i = 0; i < questions.length; i++) {
        final questionId = 'q_$i';
        final questionType = questions[i]['type'];

        // Create appropriate controllers based on type
        if (questionType == 'Open Ended' || questionType == 'text' ||
            questionType.toString().toLowerCase().contains('open')) {
          _textControllers[questionId] = TextEditingController();
        } else if (questionType == 'Multiple Choice' || questionType == 'radio' ||
            questionType.toString().toLowerCase().contains('choice')) {
          _multipleChoiceSelections[questionId] = null;
        } else if (questionType == 'Rating Scale' || questionType == 'rating' ||
            questionType.toString().toLowerCase().contains('rating')) {
          _ratingSelections[questionId] = 0;
        } else {
          // Default to text input for unknown types
          _textControllers[questionId] = TextEditingController();
        }
      }
    }
  }

  Future<void> _loadPreviousResponses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the current user ID
      final currentUserId = _auth.currentUser?.uid;

      // Check if user has previously responded
      if (widget.form.containsKey('responses') &&
          widget.form['responses'] is List &&
          currentUserId != null) {

        final responses = List<Map<String, dynamic>>.from(widget.form['responses']);

        // Find the user's response
        for (var response in responses) {
          if (response.containsKey('userId') &&
              response['userId'] == currentUserId &&
              response.containsKey('answers')) {

            // Convert answers to map for easier access
            final answers = response['answers'];
            if (answers is List) {
              for (var answer in answers) {
                if (answer is Map && answer.containsKey('questionId') && answer.containsKey('answer')) {
                  final questionId = answer['questionId'];
                  final answerValue = answer['answer'];

                  // Update UI controls with previous responses
                  if (_textControllers.containsKey(questionId)) {
                    _textControllers[questionId]!.text = answerValue.toString();
                  } else if (_multipleChoiceSelections.containsKey(questionId)) {
                    _multipleChoiceSelections[questionId] = answerValue as int?;
                  } else if (_ratingSelections.containsKey(questionId)) {
                    _ratingSelections[questionId] = answerValue as int;
                  }
                }
              }
            }
            break;
          }
        }
      }
    } catch (e) {
      print('Error loading previous responses: $e');
    } finally {
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

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Format answers as expected by RetrospectiveService
        final List<Map<String, dynamic>> formattedAnswers = [];

        // Add text responses
        _textControllers.forEach((questionId, controller) {
          formattedAnswers.add({
            'questionId': questionId,
            'answer': controller.text,
          });
        });

        // Add multiple choice responses
        _multipleChoiceSelections.forEach((questionId, selection) {
          if (selection != null) {
            formattedAnswers.add({
              'questionId': questionId,
              'answer': selection,
            });
          }
        });

        // Add rating responses
        _ratingSelections.forEach((questionId, rating) {
          formattedAnswers.add({
            'questionId': questionId,
            'answer': rating,
          });
        });

        // Get the retrospective service and submit response
        final retroService = Provider.of<RetrospectiveService>(context, listen: false);

        // Different success message based on whether it's an update or new submission
        String successMessage;
        if (_isEditMode) {
          // For edit mode, we update the existing response
          await retroService.updateResponse(
            projectId: widget.form['projectId'],
            retrospectiveId: widget.form['id'],
            answers: formattedAnswers,
          );
          successMessage = 'Response updated successfully!';
        } else {
          // For new submissions
          await retroService.submitResponse(
            projectId: widget.form['projectId'],
            retrospectiveId: widget.form['id'],
            answers: formattedAnswers,
          );
          successMessage = 'Retrospective form submitted successfully!';
        }

        setState(() {
          _isLoading = false;
          if (_isEditMode) {
            _isEditMode = false; // Return to view mode after updating
          }
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );

        // Wait a moment before navigating back (only for new submissions)
        if (!widget.viewOnly) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pop(context);
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting form: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Widget> _buildQuestions() {
    final List<Widget> questionWidgets = [];

    if (widget.form['questions'] != null && widget.form['questions'] is List) {
      final questions = List<Map<String, dynamic>>.from(widget.form['questions']);

      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        final questionId = 'q_$i';
        final questionType = question['type'];

        questionWidgets.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Q${i + 1}: ${question['question']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Explicitly handle different question types
              if (questionType == 'Open Ended' ||
                  questionType == 'text' ||
                  questionType.toString().toLowerCase().contains('open'))
                _buildTextInput(questionId, widget.viewOnly && !_isEditMode)
              else if (questionType == 'Multiple Choice' ||
                  questionType == 'radio' ||
                  questionType.toString().toLowerCase().contains('choice'))
                _buildMultipleChoiceInput(questionId, question, widget.viewOnly && !_isEditMode)
              else if (questionType == 'Rating Scale' ||
                    questionType == 'rating' ||
                    questionType.toString().toLowerCase().contains('rating'))
                  _buildRatingInput(questionId, widget.viewOnly && !_isEditMode)
                // Fallback for unknown types - display a text input as default
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Unknown question type: $questionType',
                          style: TextStyle(color: Colors.red, fontSize: 12)),
                      _buildTextInput(questionId, widget.viewOnly && !_isEditMode),
                    ],
                  ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }
    }

    return questionWidgets;
  }

  Widget _buildTextInput(String questionId, bool disabled) {
    return Container(
      width: double.infinity,
      height: 120,
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: disabled ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: TextField(
        controller: _textControllers[questionId],
        enabled: !disabled,
        decoration: InputDecoration(
          hintText: 'Enter your answer here',
          hintStyle: TextStyle(color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
          filled: true,
          fillColor: disabled ? Colors.grey[100] : Colors.white,
        ),
        style: TextStyle(
          color: Colors.black87,
          fontSize: 16.0,
        ),
        maxLines: 5,
      ),
    );
  }

  Widget _buildMultipleChoiceInput(String questionId, Map<String, dynamic> question, bool disabled) {
    final options = question['options'] ?? [];
    if (options is! List) return Container();

    return Column(
      children: List.generate(
        options.length,
            (index) => RadioListTile<int>(
          title: Text(
            options[index].toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: _multipleChoiceSelections[questionId] == index ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          value: index,
          groupValue: _multipleChoiceSelections[questionId],
          onChanged: disabled ? null : (value) {
            setState(() {
              _multipleChoiceSelections[questionId] = value;
            });
          },
          activeColor: const Color(0xFF004AAD),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildRatingInput(String questionId, bool disabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(
        5,
            (index) => IconButton(
          icon: Icon(
            index < _ratingSelections[questionId]! ? Icons.star : Icons.star_border,
            color: index < _ratingSelections[questionId]! ? Colors.amber : Colors.grey,
            size: 32,
          ),
          onPressed: disabled ? null : () {
            setState(() {
              _ratingSelections[questionId] = index + 1;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFormClosed = widget.form['status'] == 'Closed';
    final bool isDisabled = (widget.viewOnly && !_isEditMode) || isFormClosed;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Retrospective"),
      drawer: const TeamMemberDrawer(selectedItem: 'Retrospective'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                        widget.form['sprintName'] ?? 'Retrospective Form',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                    ),

                    // Add Edit/Cancel button for view-only mode when not closed
                    if (widget.viewOnly && !isFormClosed)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditMode = !_isEditMode;
                          });
                        },
                        icon: Icon(
                          _isEditMode ? Icons.cancel : Icons.edit,
                          color: _isEditMode ? Colors.red : Color(0xFF004AAD),
                        ),
                        label: Text(
                          _isEditMode ? 'Cancel' : 'Edit',
                          style: TextStyle(
                            color: _isEditMode ? Colors.red : Color(0xFF004AAD),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),

                // Status indicator
                if (widget.viewOnly)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _isEditMode ? Colors.amber[50] : Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isEditMode ? Colors.amber[200]! : Colors.blue[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isEditMode ? Icons.edit_note : Icons.info_outline,
                          color: _isEditMode ? Colors.amber[700] : Colors.blue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isEditMode
                                ? 'You are editing your previous response.'
                                : 'You are viewing your submitted response.',
                            style: TextStyle(
                              color: _isEditMode ? Colors.amber[700] : Colors.blue[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form metadata
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Due Date',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      Text(
                        widget.form['dueDate'] ?? 'Not specified',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 8),

                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      Text(
                        widget.form['description'] ?? 'No description',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),

                // Questions
                ..._buildQuestions(),

                // Submit Button - show in edit mode or normal mode
                if ((!widget.viewOnly || _isEditMode) && !isFormClosed)
                  Padding(
                    padding: const EdgeInsets.only(top: 32.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AAD),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isEditMode ? 'Update Response' : 'Submit',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}