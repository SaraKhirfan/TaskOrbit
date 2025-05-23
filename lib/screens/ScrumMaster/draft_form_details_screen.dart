import 'package:flutter/material.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:task_orbit/widgets/sm_bottom_nav.dart';
import 'package:task_orbit/widgets/sm_drawer.dart';
import 'package:provider/provider.dart';
import '../../services/RetrospectiveService.dart';

class DraftFormDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> draftForm;

  const DraftFormDetailsScreen({
    Key? key,
    required this.draftForm,
  }) : super(key: key);

  @override
  _DraftFormDetailsScreenState createState() => _DraftFormDetailsScreenState();
}

class _DraftFormDetailsScreenState extends State<DraftFormDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0; // tab in bottom nav
  bool _isLoading = false;
  bool _isEditing = false; // Track if we're in edit mode

  // Controllers
  final _formTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();

  // Form fields
  String? selectedProject;
  String? selectedSprint;
  List<Map<String, dynamic>> questions = [];

  @override
  void initState() {
    super.initState();

    // Initialize form data from the draft
    _formTitleController.text = widget.draftForm['formTitle'] ?? '';
    _descriptionController.text = widget.draftForm['description'] ?? '';
    _dueDateController.text = widget.draftForm['dueDate'] ?? '';
    selectedProject = widget.draftForm['projectName'];
    selectedSprint = widget.draftForm['sprintName'];

    // Load questions if they exist
    if (widget.draftForm['questions'] != null) {
      questions = List<Map<String, dynamic>>.from(
          widget.draftForm['questions'].map((q) => Map<String, dynamic>.from(q)));
    }
  }

  @override
  void dispose() {
    _formTitleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1) Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2) Navigator.pushReplacementNamed(context, '/scrumMasterSettings');
    if (index == 3) Navigator.pushReplacementNamed(context, '/scrumMasterProfile');
  }
  Widget _buildNavItem(IconData icon, String label, int index) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontFamily: 'Poppins-SemiBold',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _showAddQuestionDialog() {
    String questionText = '';
    String questionType = 'Open Ended';
    List<String> options = ['Option 1', 'Option 2', 'Option 3'];
    int scale = 5;

    // Create controllers for the options
    List<TextEditingController> optionControllers = options.map((option) =>
        TextEditingController(text: option)).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Add Question'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text field
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Question',
                      hintText: 'Enter your question',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      questionText = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Question type dropdown
                  Text('Question Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: questionType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Open Ended', child: Text('Open Ended')),
                      DropdownMenuItem(value: 'Multiple Choice', child: Text('Multiple Choice')),
                      DropdownMenuItem(value: 'Rating Scale', child: Text('Rating Scale')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        questionType = value!;
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Show options for multiple choice
                  if (questionType == 'Multiple Choice')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...List.generate(options.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: optionControllers[index],
                                    decoration: InputDecoration(
                                      hintText: 'Option ${index + 1}',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      options[index] = value;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    if (options.length > 1) {
                                      setState(() {
                                        options.removeAt(index);
                                        optionControllers.removeAt(index);
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('At least one option is required')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Option'),
                          onPressed: () {
                            setState(() {
                              String newOption = 'New Option';
                              options.add(newOption);
                              optionControllers.add(TextEditingController(text: newOption));
                            });
                          },
                        ),
                      ],
                    ),

                  // Show scale for rating
                  if (questionType == 'Rating Scale')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rating Scale', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: scale.toDouble(),
                                min: 3,
                                max: 10,
                                divisions: 7,
                                label: scale.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    scale = value.round();
                                  });
                                },
                              ),
                            ),
                            Text(scale.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('Number of stars (3-10)'),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF004AAD),
                ),
                onPressed: () {
                  // Validate question text
                  if (questionText.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a question')),
                    );
                    return;
                  }

                  // Create new question object
                  Map<String, dynamic> newQuestion = {
                    'question': questionText,
                    'type': questionType,
                  };

                  // Add options for multiple choice
                  if (questionType == 'Multiple Choice') {
                    newQuestion['options'] = optionControllers.map((controller) => controller.text).toList();
                  }

                  // Add scale for rating
                  if (questionType == 'Rating Scale') {
                    newQuestion['scale'] = scale;
                  }

                  // Add to questions list
                  this.setState(() {
                    questions.add(newQuestion);
                  });

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }
  Future<void> _deleteForm() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Draft'),
        content: Text('Are you sure you want to delete this draft form?'),
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
                  projectId: widget.draftForm['projectId'],
                  retrospectiveId: widget.draftForm['id'],
                );

                setState(() {
                  _isLoading = false;
                });

                // Return to previous screen with action
                Navigator.pop(context, {'action': 'delete'});
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting form: $e')),
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

  void _showEditQuestionDialog(int index) {
    Map<String, dynamic> question = questions[index];
    String questionText = question['question'] ?? '';
    String questionType = question['type'] ?? 'Open Ended';
    List<String> options = List<String>.from(question['options'] ?? ['Option 1', 'Option 2', 'Option 3']);
    int scale = question['scale'] ?? 5;

    // Create controllers for form fields
    TextEditingController questionController = TextEditingController(text: questionText);
    List<TextEditingController> optionControllers = options.map((option) =>
        TextEditingController(text: option)).toList();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit Question'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question text field
                  TextField(
                    controller: questionController,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      hintText: 'Enter your question',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onChanged: (value) {
                      questionText = value;
                    },
                  ),
                  SizedBox(height: 16),

                  // Question type dropdown
                  Text('Question Type', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: questionType,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'Open Ended', child: Text('Open Ended')),
                      DropdownMenuItem(value: 'Multiple Choice', child: Text('Multiple Choice')),
                      DropdownMenuItem(value: 'Rating Scale', child: Text('Rating Scale')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        questionType = value!;

                        // Reset options if changing to Multiple Choice
                        if (questionType == 'Multiple Choice' && options.isEmpty) {
                          options = ['Option 1', 'Option 2', 'Option 3'];
                          optionControllers = options.map((option) =>
                              TextEditingController(text: option)).toList();
                        }
                      });
                    },
                  ),
                  SizedBox(height: 16),

                  // Show options for multiple choice
                  if (questionType == 'Multiple Choice')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Options', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        ...List.generate(options.length, (i) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: i < optionControllers.length
                                        ? optionControllers[i]
                                        : TextEditingController(text: options[i]),
                                    decoration: InputDecoration(
                                      hintText: 'Option ${i + 1}',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    ),
                                    onChanged: (value) {
                                      options[i] = value;
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    if (options.length > 1) {
                                      setState(() {
                                        options.removeAt(i);
                                        if (i < optionControllers.length) {
                                          optionControllers.removeAt(i);
                                        }
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('At least one option is required')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        TextButton.icon(
                          icon: Icon(Icons.add),
                          label: Text('Add Option'),
                          onPressed: () {
                            setState(() {
                              String newOption = 'Option ${options.length + 1}';
                              options.add(newOption);
                              optionControllers.add(TextEditingController(text: newOption));
                            });
                          },
                        ),
                      ],
                    ),

                  // Show scale for rating
                  if (questionType == 'Rating Scale')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rating Scale', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Slider(
                                value: scale.toDouble(),
                                min: 3,
                                max: 10,
                                divisions: 7,
                                label: scale.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    scale = value.round();
                                  });
                                },
                              ),
                            ),
                            Text(scale.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Text('Number of stars (3-10)'),
                      ],
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: Text('Save'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF004AAD),
                ),
                onPressed: () {
                  // Validate question text
                  if (questionController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a question')),
                    );
                    return;
                  }

                  // Update question
                  Map<String, dynamic> updatedQuestion = {
                    'question': questionController.text,
                    'type': questionType,
                  };

                  // Add options for multiple choice
                  if (questionType == 'Multiple Choice') {
                    updatedQuestion['options'] = optionControllers.map((controller) => controller.text).toList();
                  }

                  // Add scale for rating
                  if (questionType == 'Rating Scale') {
                    updatedQuestion['scale'] = scale;
                  }

                  // Update questions list
                  this.setState(() {
                    questions[index] = updatedQuestion;
                  });

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare form data
      Map<String, dynamic> formData = Map<String, dynamic>.from(widget.draftForm);
      formData['formTitle'] = _formTitleController.text;
      formData['description'] = _descriptionController.text;
      formData['dueDate'] = _dueDateController.text;
      formData['questions'] = questions;
      formData['updatedAt'] = DateTime.now().millisecondsSinceEpoch;

      // Get retrospective service
      final retroService = Provider.of<RetrospectiveService>(context, listen: false);

      // Update the form
      await retroService.updateRetrospective(
        projectId: widget.draftForm['projectId'],
        retrospectiveId: widget.draftForm['id'],
        data: formData,
      );

      setState(() {
        _isLoading = false;
        _isEditing = false; // Exit edit mode
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _publishForm() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Publish Form'),
        content: Text('Are you sure you want to publish this form? Team members will be able to see and respond to it.'),
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

                // Update form status to Open
                await retroService.changeStatus(
                  projectId: widget.draftForm['projectId'],
                  retrospectiveId: widget.draftForm['id'],
                  newStatus: 'Open',
                );

                setState(() {
                  _isLoading = false;
                });

                // Return to previous screen with action
                Navigator.pop(context, {'action': 'publish'});
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error publishing form: $e')),
                );
              }
            },
            child: Text('Publish'),
            style: TextButton.styleFrom(foregroundColor: Color(0xFF004AAD)),
          ),
        ],
      ),
    );
  }

  void _deleteQuestion(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Question'),
        content: Text('Are you sure you want to delete this question?'),
        actions: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Delete'),
            onPressed: () {
              setState(() {
                questions.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Map<String, dynamic> question, int index) {
    final String questionText = question['question'] ?? '';
    final String questionType = question['type'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        questionText,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Color(0xFFE8F1FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          questionType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF004AAD),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Only show edit/delete in edit mode
                if (_isEditing)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF004AAD)),
                        onPressed: () => _showEditQuestionDialog(index),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteQuestion(index),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.all(8),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: SMAppBar(
        scaffoldKey: _scaffoldKey,
        title: _isEditing ? "Edit Form" : "Draft Form",
      ),
      drawer: SMDrawer(selectedItem: 'Retrospective'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button and action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                    ),

                    // Action buttons
                    if (_isEditing)
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _saveChanges,
                            icon: Icon(Icons.check, size: 18),
                            label: Text('Save Changes'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _toggleEditMode,
                        icon: Icon(Icons.edit, size: 18),
                        label: Text('Edit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),

                // Project and sprint info card
                Container(
                  width: double.infinity, // This makes it take the full width
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
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Project',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        selectedProject ?? 'No project selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sprint',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        selectedSprint ?? 'No sprint selected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                // Form fields
                Text(
                  'Form Title',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                TextField(
                  controller: _formTitleController,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                TextField(
                  controller: _descriptionController,
                  enabled: _isEditing,
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 16),

                Text(
                  'Due Date',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                TextField(
                  controller: _dueDateController,
                  enabled: _isEditing,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
                SizedBox(height: 24),

                // Questions section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_isEditing)
                      ElevatedButton.icon(
                        onPressed: _showAddQuestionDialog,
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Add Question'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 12),

                // Question list
                questions.isEmpty
                    ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No questions added yet. Tap the + button to add questions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
                    : Column(
                  children: List.generate(
                    questions.length,
                        (index) => _buildQuestionCard(questions[index], index),
                  ),
                ),
                SizedBox(height: 16),

                // Near the bottom of your build method, add this above the SizedBox(height: 80):
                if (!_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      // Use spaceBetween for 20% margins on both sides
                      children: [
                        SizedBox(width: 20), // Small margin on the left

                        // Delete button on left
                        OutlinedButton.icon(
                          onPressed: _deleteForm,
                          icon: Icon(Icons.delete_outline, size: 18),
                          label: Text('Delete Draft'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                        Spacer(), // This will push the buttons to the sides

                        // Publish button on right
                        ElevatedButton(
                          onPressed: () {
                            if (questions.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please add at least one question before publishing'),
                                ),
                              );
                            } else {
                              _publishForm();
                            }
                          },
                          child: Text('Publish Form'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF004AAD),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),

                        SizedBox(width: 20), // Small margin on the right
                      ],
                    ),
                  ),
                SizedBox(height: 80), // Add extra space at the bottom for FAB
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color(0xFFFDFDFD),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Home", 0),
            _buildNavItem(Icons.assignment, "Project", 1),
            _buildNavItem(Icons.access_time_filled_rounded, "Schedule", 2),
            _buildNavItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
    );
  }
}