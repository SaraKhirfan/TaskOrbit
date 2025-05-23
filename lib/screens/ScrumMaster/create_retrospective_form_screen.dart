import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/RetrospectiveService.dart';
import 'package:intl/intl.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_drawer.dart';

class CreateRetrospectiveFormScreen extends StatefulWidget {
  final Map<String, dynamic>? existingForm;

  const CreateRetrospectiveFormScreen({
    Key? key,
    this.existingForm,
  }) : super(key: key);

  @override
  _CreateRetrospectiveFormScreenState createState() =>
      _CreateRetrospectiveFormScreenState();
}

class _CreateRetrospectiveFormScreenState
    extends State<CreateRetrospectiveFormScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Form fields
  String? selectedProjectId;
  String? selectedProject;
  String? selectedSprintId;
  String? selectedSprint;
  final _formTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  DateTime? _selectedDate;

  // Questions
  List<Map<String, dynamic>> questions = [];

  // Question being created
  String? selectedQuestionType;
  final _questionTextController = TextEditingController();
  int? selectedRatingScale;
  List<String> multipleChoiceOptions = [''];
  bool showQuestionForm = false;

  // Projects and sprints
  List<Map<String, dynamic>> projects = [];
  List<Map<String, dynamic>> sprints = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();

    // Initialize with existing form data if provided
    if (widget.existingForm != null) {
      _formTitleController.text = widget.existingForm!['formTitle'] ?? '';
      _descriptionController.text = widget.existingForm!['description'] ?? '';
      selectedProject = widget.existingForm!['projectName'];
      selectedProjectId = widget.existingForm!['projectId'];
      selectedSprint = widget.existingForm!['sprintName'];
      selectedSprintId = widget.existingForm!['sprintId'];

      if (widget.existingForm!['dueDate'] != null &&
          widget.existingForm!['dueDate'].isNotEmpty) {
        _dueDateController.text = widget.existingForm!['dueDate'];
        try {
          _selectedDate = DateFormat('dd-MM-yyyy').parse(widget.existingForm!['dueDate']);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }

      // Load questions
      if (widget.existingForm!['questions'] != null) {
        questions = List<Map<String, dynamic>>.from(widget.existingForm!['questions']);
      }
    }
  }

  // Add this method inside _CreateRetrospectiveFormScreenState class
  static const Color primaryColor = Color(0xFF004AAD);
  static const Color errorColor = Color(0xFFE53935);

  InputDecoration _getModernInputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: primaryColor, size: 22),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFDFDFD),
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      constraints: const BoxConstraints(minHeight: 56),
      alignLabelWithHint: true,
      isCollapsed: false,
      prefixIconColor: primaryColor,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: errorColor, width: 2),
      ),
      errorStyle: TextStyle(
        color: errorColor,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
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
  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('Loading projects for Scrum Master: ${user.uid}');

      // Query projects where user is a Scrum Master
      final projectsSnapshot = await _firestore
          .collection('projects')
          .where('roles.scrumMasters', arrayContains: user.uid)  // ✅ FIXED - Correct field for Scrum Master
          .get();

      print('Found ${projectsSnapshot.docs.length} projects for Scrum Master');

      setState(() {
        projects = projectsSnapshot.docs.map((doc) {
          final data = doc.data();
          print('Project: ${data['name']} (${doc.id})');
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Project',
          };
        }).toList();
        _isLoading = false;
      });

      // Load sprints if a project was selected (for editing)
      if (selectedProjectId != null) {
        _loadSprints(selectedProjectId!);
      }
    } catch (e) {
      print('Error loading projects: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSprints(String projectId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading sprints for project: $projectId');

      final sprintsSnapshot = await _firestore
          .collection('projects')
          .doc(projectId)
          .collection('sprints')
          .get();

      print('Found ${sprintsSnapshot.docs.length} sprints for project $projectId');

      setState(() {
        sprints = sprintsSnapshot.docs.map((doc) {
          final data = doc.data();
          print('Sprint: ${data['name']} (${doc.id}) - Status: ${data['status']}');
          return {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Sprint',
            'status': data['status'] ?? 'Planning', // Add status for filtering if needed
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading sprints: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dueDateController.text = DateFormat('dd-MM-yyyy').format(picked);
      });
    }
  }

  void _addQuestion() {
    if (_questionTextController.text.isEmpty || selectedQuestionType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter question text and select a type')),
      );
      return;
    }

    // Create the question based on type
    Map<String, dynamic> newQuestion = {
      'type': selectedQuestionType,
      'question': _questionTextController.text,
    };

    // Add type-specific data
    if (selectedQuestionType == 'Multiple Choice') {
      // Remove any empty options
      final nonEmptyOptions = multipleChoiceOptions
          .where((option) => option.trim().isNotEmpty)
          .toList();

      if (nonEmptyOptions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add at least one choice option')),
        );
        return;
      }

      newQuestion['options'] = nonEmptyOptions;
    } else if (selectedQuestionType == 'Rating Scale') {
      newQuestion['scale'] = selectedRatingScale ?? 5;
    }

    setState(() {
      questions.add(newQuestion);
      _questionTextController.clear();
      selectedQuestionType = null;
      multipleChoiceOptions = [''];
      selectedRatingScale = null;
      showQuestionForm = false;
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      questions.removeAt(index);
    });
  }

  void _addOption() {
    setState(() {
      multipleChoiceOptions.add('');
    });
  }

  void _updateOption(int index, String value) {
    setState(() {
      multipleChoiceOptions[index] = value;
    });
  }

  void _removeOption(int index) {
    setState(() {
      multipleChoiceOptions.removeAt(index);
    });
  }

  Future<void> _saveForm(String status) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (selectedProjectId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a project')),
        );
        return;
      }

      if (status == 'Open' && questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please add at least one question before publishing')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Use the RetrospectiveService to save the form
        final retroService = Provider.of<RetrospectiveService>(context, listen: false);

        final result = await retroService.saveRetrospective(
          projectId: selectedProjectId!,
          retrospectiveId: widget.existingForm?['id'],
          title: _formTitleController.text,
          description: _descriptionController.text,
          sprintId: selectedSprintId ?? '',
          sprintName: selectedSprint ?? '',
          status: status,
          dueDate: _dueDateController.text,
          questions: questions,
        );

        setState(() {
          _isLoading = false;
        });

        Navigator.pop(context, result);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving form: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDF1F3),
      key: _scaffoldKey,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Retrospective"),
      drawer: SMDrawer(selectedItem: 'Retrospective'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF004AAD),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(height: 10),
              Text(
                'Create New Form',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
            ],
          ),
    // Main content
    Expanded(
    child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Form title
              Text(
                'Form Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
              SizedBox(height: 16),

              // Form title field
              TextFormField(
                controller: _formTitleController,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF313131),
                ),
                decoration: _getModernInputDecoration(
                  label: 'Form Title',
                  icon: Icons.assignment, // Form icon
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a form title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF313131),
                ),
                minLines: 1,
                maxLines: 5,
                keyboardType: TextInputType.multiline,
                decoration: _getModernInputDecoration(
                  label: 'Description',
                  icon: Icons.description,
                ),
              ),
              const SizedBox(height: 24),

              // Project selection
              DropdownButtonFormField<String>(
                decoration: _getModernInputDecoration(
                  label: 'Project',
                  icon: Icons.folder,
                ),
                value: selectedProject,
                items: projects.map((project) {
                  return DropdownMenuItem<String>(
                    value: project['name'],
                    child: Text(project['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedProject = value;
                    selectedProjectId = projects.firstWhere(
                          (project) => project['name'] == value,
                      orElse: () => {'id': null},
                    )['id'];
                    selectedSprint = null;
                    selectedSprintId = null;
                    sprints.clear();
                  });

                  if (selectedProjectId != null) {
                    _loadSprints(selectedProjectId!);
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24), // Increased spacing

              // Sprint dropdown with overflow fix
              DropdownButtonFormField<String>(
                isExpanded: true, // ✅ ADD THIS - This is the key fix!
                decoration: _getModernInputDecoration(
                  label: 'Sprint (Optional)',
                  icon: Icons.cached,
                ),
                value: selectedSprint,
                items: sprints.map((sprint) {
                  return DropdownMenuItem<String>(
                    value: sprint['name'],
                    child: Container(
                      width: double.infinity, // ✅ ADD THIS
                      child: Text(
                        sprint['name'],
                        overflow: TextOverflow.ellipsis, // ✅ ADD THIS
                        maxLines: 1, // ✅ ADD THIS
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSprint = value;
                    selectedSprintId = sprints.firstWhere(
                          (sprint) => sprint['name'] == value,
                      orElse: () => {'id': null},
                    )['id'];
                  });
                },
              ),
              const SizedBox(height: 24), // Increased spacing

              TextFormField(
                controller: _dueDateController,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF313131),
                ),
                decoration: _getModernInputDecoration(
                  label: 'Due Date',
                  icon: Icons.calendar_today,
                  suffixIcon: Icon(Icons.arrow_drop_down, color: primaryColor),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
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
                      color: Color(0xFF313131),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showQuestionForm = true;
                      });
                    },
                    icon: Icon(Icons.add),
                    label: Text('Add Question'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004AAD),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Question form
              if (showQuestionForm) ...[
                Card(
                  color: Color(0xFFFDFDFD),
                  elevation: 2,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // In your question form section, update the question text field:
                        TextFormField(
                          controller: _questionTextController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF313131),
                          ),
                          decoration: _getModernInputDecoration(
                            label: 'Question',
                            icon: Icons.help_outline,
                          ),
                          maxLines: 2,
                        ),
                        SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Question Type',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          value: selectedQuestionType,
                          hint: Text('Select Question Type'),
                          onChanged: (value) {
                            setState(() {
                              selectedQuestionType = value;
                              // Reset options when type changes
                              multipleChoiceOptions = [''];
                              selectedRatingScale = 5;
                            });
                          },
                          items: [
                            'Text Input',
                            'Multiple Choice',
                            'Rating Scale',
                          ].map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 16),

                        // Multiple choice options
                        if (selectedQuestionType == 'Multiple Choice') ...[
                          Text(
                            'Options',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          ...List.generate(
                            multipleChoiceOptions.length,
                                (index) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: multipleChoiceOptions[index],
                                      decoration: InputDecoration(
                                        labelText: 'Option ${index + 1}',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onChanged: (value) => _updateOption(index, value),
                                    ),
                                  ),
                                  if (multipleChoiceOptions.length > 1)
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeOption(index),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _addOption,
                            icon: Icon(Icons.add),
                            label: Text('Add Option'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],

                        // Rating scale options
                        if (selectedQuestionType == 'Rating Scale') ...[
                          Text(
                            'Scale (1-10)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Select Scale',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            value: selectedRatingScale ?? 5,
                            onChanged: (value) {
                              setState(() {
                                selectedRatingScale = value;
                              });
                            },
                            items: [3, 5, 7, 10].map((scale) {
                              return DropdownMenuItem<int>(
                                value: scale,
                                child: Text('1-$scale'),
                              );
                            }).toList(),
                          ),
                        ],

                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  showQuestionForm = false;
                                  _questionTextController.clear();
                                  selectedQuestionType = null;
                                  multipleChoiceOptions = [''];
                                  selectedRatingScale = null;
                                });
                              },
                              child: Text('Cancel'),
                            ),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _addQuestion,
                              child: Text('Add Question', style: TextStyle(fontWeight: FontWeight.bold),),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF004AAD),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // List of added questions
              if (questions.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Added Questions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ...List.generate(
                  questions.length,
                      (index) => Card(
                        color: const Color(0xFFFDFDFD),
                    elevation: 1,
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(questions[index]['question']),
                      subtitle: Text(questions[index]['type']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeQuestion(index),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24),

              // Save buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveForm('Draft'),
                      child: Text('Save as Draft', style: TextStyle(fontWeight: FontWeight.bold),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xFF004AAD),
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveForm('Open'),
                      child: Text('Publish', style: TextStyle(fontWeight: FontWeight.bold),),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF004AAD),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    ],
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

  @override
  void dispose() {
    _formTitleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    _questionTextController.dispose();
    super.dispose();
  }
}