import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/product_owner_drawer.dart';

class EditProjectScreen extends StatefulWidget {
  final Map<String, dynamic> project;
  final Function(String, Map<String, dynamic>) onProjectUpdated;

  const EditProjectScreen({
    super.key,
    required this.project,
    required this.onProjectUpdated
  });

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSubmitting = false;

  // User details
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Initialize controllers with existing project data
    _nameController = TextEditingController(text: widget.project['name'] ?? '');
    _descriptionController = TextEditingController(text: widget.project['description'] ?? '');

    // Parse existing dates
    if (widget.project['startDate'] != null && widget.project['startDate'].isNotEmpty) {
      try {
        // Try parsing in formats like 'DD-MM-YYYY' or 'DD/MM/YYYY'
        if (widget.project['startDate'].contains('-')) {
          _startDate = DateFormat('dd-MM-yyyy').parse(widget.project['startDate']);
        } else if (widget.project['startDate'].contains('/')) {
          _startDate = DateFormat('dd/MM/yyyy').parse(widget.project['startDate']);
        }
      } catch (e) {
        print('Error parsing start date: $e');
      }
    }

    if (widget.project['endDate'] != null && widget.project['endDate'].isNotEmpty) {
      try {
        // Try parsing in formats like 'DD-MM-YYYY' or 'DD/MM/YYYY'
        if (widget.project['endDate'].contains('-')) {
          _endDate = DateFormat('dd-MM-yyyy').parse(widget.project['endDate']);
        } else if (widget.project['endDate'].contains('/')) {
          _endDate = DateFormat('dd/MM/yyyy').parse(widget.project['endDate']);
        }
      } catch (e) {
        print('Error parsing end date: $e');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getUserProfile();

    if (userData != null && mounted) {
      setState(() {
        _userName = userData['name'] ?? 'User';
        _userEmail = userData['email'] ?? '';
      });
    }
  }

  // Handle logout with Firebase
  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004AAD), // Primary color for header and selected day
              onPrimary: Color(0xFFFDFDFD), // Text color for header and selected day
              surface: Color(0xFFFDFDFD), // Background color of the calendar
              onSurface: Color(0xFF313131), // Text color for days
            ),
            dialogTheme: DialogTheme(
              backgroundColor: const Color(0xFFFDFDFD),
            ), // Background color of the dialog
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004AAD), // Primary color for header and selected day
              onPrimary: Color(0xFFFDFDFD), // Text color for header and selected day
              surface: Color(0xFFFDFDFD), // Background color of the calendar
              onSurface: Color(0xFF313131), // Text color for days
            ),
            dialogTheme: DialogTheme(
              backgroundColor: const Color(0xFFFDFDFD),
            ), // Background color of the dialog
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // Submit form and update project in Firebase
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_isSubmitting) return; // Prevent double submission

      setState(() {
        _isSubmitting = true;
      });

      try {
        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You need to be logged in to update projects')),
          );
          return;
        }

        // Format dates for storage
        final startDateStr = DateFormat('dd-MM-yyyy').format(_startDate!);
        final endDateStr = DateFormat('dd-MM-yyyy').format(_endDate!);

        // Create updated project object
        final updatedProject = {
          'name': _nameController.text,
          'title': _nameController.text, // Add title for consistency
          'description': _descriptionController.text,
          'startDate': startDateStr,
          'endDate': endDateStr,
          'dueDate': endDateStr, // Add dueDate for consistency
          'status': widget.project['status'] ?? 'Not Started',
          'progress': widget.project['progress'] ?? 0.0,
          'members': widget.project['members'] ?? [user.uid],
        };

        // Update project via callback
        widget.onProjectUpdated(widget.project['id'], updatedProject);

        // Return to project details screen
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project updated successfully!')),
        );
      } catch (e) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating project: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

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
                    color: MyProjectsScreen.primaryColor,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Edit Project',  // Changed from 'Add New Project'
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Form content
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Project Name Field with new icon
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      decoration: _getModernInputDecoration(
                        label: 'Project Name',
                        icon: Icons.folder,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter project name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Description Field - now expands when typing
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      minLines: 1, // Starts with single line
                      maxLines: 5, // Expands up to 5 lines when typing
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

                    // Date Fields Row
                    Row(
                      children: [
                        // Start Date Field
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectStartDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF313131),
                                ),
                                decoration: _getModernInputDecoration(
                                  label: 'Start Date',
                                  icon: Icons.calendar_today,
                                ),
                                validator: (value) {
                                  if (_startDate == null) {
                                    return 'Select start date';
                                  }
                                  return null;
                                },
                                controller: TextEditingController(
                                  text: _startDate == null
                                      ? ''
                                      : DateFormat('dd-MM-yyyy').format(_startDate!),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // End Date Field
                        Expanded(
                          child: GestureDetector(
                            onTap: _selectEndDate,
                            child: AbsorbPointer(
                              child: TextFormField(
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF313131),
                                ),
                                decoration: _getModernInputDecoration(
                                  label: 'End Date',
                                  icon: Icons.event_available,
                                ),
                                validator: (value) {
                                  if (_endDate == null) {
                                    return 'Select end date';
                                  }
                                  return null;
                                },
                                controller: TextEditingController(
                                  text: _endDate == null
                                      ? ''
                                      : DateFormat('dd-MM-yyyy').format(_endDate!),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Submit Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        )
                            : const Text('Update Project'),  // Changed from 'Create Project'
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