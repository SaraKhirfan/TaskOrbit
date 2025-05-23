import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/drawer_header.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/product_owner_drawer.dart';

class AddProjectScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onProjectAdded;

  const AddProjectScreen({super.key, required this.onProjectAdded});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
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
            dialogTheme: DialogThemeData(
              backgroundColor: Color(0xFFFDFDFD),
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
            dialogTheme: DialogThemeData(
              backgroundColor: Color(0xFFFDFDFD),
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

  // Submit form and create project in Firebase
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
            const SnackBar(content: Text('You need to be logged in to create projects')),
          );
          return;
        }

        // Create project ID (you can improve this with a more complex ID generation)
        final projectId = 'PROJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        // Format dates for storage
        final startDateStr = DateFormat('dd-MM-yyyy').format(_startDate!);
        final endDateStr = DateFormat('dd-MM-yyyy').format(_endDate!);

        // Create project object
        final newProject = {
          'id': projectId,
          'name': _nameController.text,
          'title': _nameController.text, // Add title for consistency
          'description': _descriptionController.text,
          'startDate': startDateStr,
          'endDate': endDateStr,
          'dueDate': endDateStr, // Add dueDate for consistency
          'status': 'Not Started',
          'progress': 0.0,
          'createdBy': user.uid,
          'members': [user.uid],
        };

        // Add to ProjectService via callback
        widget.onProjectAdded(newProject);

        // Return to projects screen
        Navigator.pop(context);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project created successfully!')),
        );
      } catch (e) {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating project: $e')),
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
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
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
                    'Add New Project',
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
                        icon: Icons.folder, // Changed from work_outline to folder
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
                                controller: TextEditingController(
                                  text: _startDate == null
                                      ? ''
                                      : DateFormat('dd-MM-yyyy').format(_startDate!),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF313131),
                                ),
                                decoration: _getModernInputDecoration(
                                  label: 'Start Date',
                                  icon: Icons.calendar_month,
                                ),
                                validator: (value) {
                                  if (_startDate == null) {
                                    return 'Please select start date';
                                  }
                                  return null;
                                },
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
                                controller: TextEditingController(
                                  text: _endDate == null
                                      ? ''
                                      : DateFormat('dd-MM-yyyy').format(_endDate!),
                                ),
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF313131),
                                ),
                                decoration: _getModernInputDecoration(
                                  label: 'End Date',
                                  icon: Icons.calendar_month,
                                ),
                                validator: (value) {
                                  if (_endDate == null) {
                                    return 'Please select end date';
                                  }
                                  if (_startDate != null && _endDate!.isBefore(_startDate!)) {
                                    return 'End date must be after start date';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Add Project Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: MyProjectsScreen.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitForm,
                        child: _isSubmitting
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Add Project',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
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