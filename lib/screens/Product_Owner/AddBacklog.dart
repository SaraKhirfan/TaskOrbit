import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/widgets/drawer_header.dart';
import 'package:task_orbit/services/project_service.dart';
import 'package:task_orbit/services/AuthService.dart';
import 'package:intl/intl.dart';

import '../../widgets/product_owner_drawer.dart';

class AddBacklogScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const AddBacklogScreen({
    super.key,
    required this.projectId,
    required this.projectName
  });

  @override
  State<AddBacklogScreen> createState() => _AddBacklogScreenState();
}

class _AddBacklogScreenState extends State<AddBacklogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _estimatedEffort = TextEditingController();
  String _priority = 'Medium';
  DateTime? _dueDate;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _estimatedEffort.dispose();
    super.dispose();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserProfile();

      if (userData != null && mounted) {
        setState(() {
          _userName = userData['name'] ?? 'User';
          _userEmail = userData['email'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  Future<void> _saveUserStory() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Show loading
      setState(() {
        _isLoading = true;
      });
      try {
        print('Project ID before saving: ${widget.projectId}');
        // Verify project exists before adding
        final projectDoc = await FirebaseFirestore.instance
            .collection('projects')
            .doc(widget.projectId)
            .get();
        if (!projectDoc.exists) {
          print('Project document does not exist in Firestore: ${widget.projectId}');

          // Try to fetch project details from ProjectService
          final projectService = Provider.of<ProjectService>(context, listen: false);
          final project = projectService.getProjectById(widget.projectId);

          if (project != null) {
            print('Project found in local data: ${project['name']}');

            // Create the project in Firestore with its own ID
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              print('Attempting to create missing project in Firestore');

              await FirebaseFirestore.instance.collection('projects').doc(widget.projectId).set({
                'id': widget.projectId,
                'name': widget.projectName,
                'createdBy': user.uid,
                'members': [user.uid],
                'createdAt': FieldValue.serverTimestamp(),
              });

              print('Created missing project in Firestore');
            }
          } else {
            print('Project not found in local data either');
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Project not found')),
            );
            return;
          }
        }
        final newStory = {
          'title': _titleController.text,
          'description': _descriptionController.text,
          'estimatedEffort': _estimatedEffort.text,
          'priority': _priority,
          'status': 'Draft', // Set the status to Draft
          'dueDate': _dueDate != null
              ? DateFormat('yyyy-MM-dd').format(_dueDate!)
              : '',
        };
        print('New story data: $newStory');
        // Add to Firestore through service
        final projectService = Provider.of<ProjectService>(context, listen: false);
        final addedStory = await projectService.addBacklogItem(widget.projectId, newStory);
        if (addedStory != null) {
          print('Successfully added story: ${addedStory['id']}');
          Navigator.pop(context, addedStory);
        } else {
          // Show error
          print('Failed to add backlog item - returned null');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add backlog item')),
          );
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error saving backlog item: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _getModernInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF004AAD), size: 22),
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
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF004AAD), width: 2),
      ),
    );
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Color(0xFFFDFDFD),
              surface: Color(0xFFFDFDFD),
              onSurface: Color(0xFF313131),
            ),
            dialogTheme: const DialogTheme(
              backgroundColor: Color(0xFFFDFDFD),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: const Color(0xFF004AAD),
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
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button and title section
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: const Color(0xFF004AAD),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Add Backlog Item',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  widget.projectName,
                  style: const TextStyle(
                      fontSize: 16, color: Color(0xFF313131)),
                ),
              ),
              const SizedBox(height: 32),

              // Form content
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Field
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      decoration: _getModernInputDecoration(
                        label: 'User Story',
                        icon: Icons.assignment,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter user story title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Description Field
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Estimated Effort Field
                    TextFormField(
                      controller: _estimatedEffort,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      keyboardType: TextInputType.number,
                      decoration: _getModernInputDecoration(
                        label: 'Estimated Effort (In hours)',
                        icon: Icons.timer,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Priority Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('High'),
                                selected: _priority == 'High',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _priority = 'High';
                                    });
                                  }
                                },
                                selectedColor: Colors.red[100],
                                labelStyle: TextStyle(
                                  color: _priority == 'High'
                                      ? Colors.red[700]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Medium'),
                                selected: _priority == 'Medium',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _priority = 'Medium';
                                    });
                                  }
                                },
                                selectedColor: Colors.orange[100],
                                labelStyle: TextStyle(
                                  color: _priority == 'Medium'
                                      ? Colors.orange[700]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Low'),
                                selected: _priority == 'Low',
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _priority = 'Low';
                                    });
                                  }
                                },
                                selectedColor: Colors.green[100],
                                labelStyle: TextStyle(
                                  color: _priority == 'Low'
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Due Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.calendar_today,
                        color: const Color(0xFF004AAD),
                      ),
                      title: const Text(
                        'Due Date',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        _dueDate == null
                            ? 'No date selected'
                            : DateFormat('yyyy-MM-dd').format(_dueDate!),
                        style: TextStyle(
                          color: const Color(0xFF313131),
                        ),
                      ),
                      onTap: _selectDueDate,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveUserStory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004AAD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        'Save Backlog Item',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}