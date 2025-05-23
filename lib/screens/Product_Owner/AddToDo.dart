import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_orbit/widgets/drawer_header.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/AuthService.dart';
import '../../widgets/product_owner_drawer.dart';

class AddTodo extends StatefulWidget {
  final Function(Map<String, dynamic>) onTodoAdded;
  final Map<String, dynamic>? initialTask;

  const AddTodo({
    super.key,
    required this.onTodoAdded,
    this.initialTask,
  });

  @override
  State<AddTodo> createState() => _AddTodoState();
}

class _AddTodoState extends State<AddTodo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _priority = "High";
  DateTime? _deadline;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialTask != null) {
      _titleController.text = widget.initialTask!['title'] ?? '';
      _descriptionController.text = widget.initialTask!['description'] ?? '';
      _priority = widget.initialTask!['priority'] ?? 'High';
      if (widget.initialTask!['deadline'] != null) {
        _deadline = DateTime.parse(widget.initialTask!['deadline']);
      }
    }
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Color(0xFFFDFDFD),
              surface: Color(0xFFFDFDFD),
              onSurface: Color(0xFF313131),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: Color(0xFFFDFDFD),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _deadline) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  // Form submission handling
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final task = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _priority,
        'deadline': _deadline?.toIso8601String() ?? DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'isCompleted': widget.initialTask != null ? widget.initialTask!['isCompleted'] : false,
      };

      // If editing, include the ID
      if (widget.initialTask != null && widget.initialTask!.containsKey('id')) {
        task['id'] = widget.initialTask!['id'];
      }

      // Use the callback to handle task saving through TaskService
      widget.onTodoAdded(task);
      Navigator.pop(context);
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
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: const Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Tasks'),
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
                    widget.initialTask != null ? 'Edit Task' : 'Add New Task',
                    style: const TextStyle(
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
                    // Task Title Field
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      decoration: _getModernInputDecoration(
                        label: 'Task Title',
                        icon: Icons.task,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      decoration: _getModernInputDecoration(
                        label: 'Description',
                        icon: Icons.description,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Priority Field with Choice Chips
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12.0, bottom: 8.0),
                          child: Text(
                            'Priority',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('High'),
                                selected: _priority == 'High',
                                onSelected: (selected) {
                                  setState(() {
                                    _priority = 'High';
                                  });
                                },
                                selectedColor: Colors.red,
                                backgroundColor: Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: _priority == 'High'
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Medium'),
                                selected: _priority == 'Medium',
                                onSelected: (selected) {
                                  setState(() {
                                    _priority = 'Medium';
                                  });
                                },
                                selectedColor: Colors.orange,
                                backgroundColor: Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: _priority == 'Medium'
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ChoiceChip(
                                label: const Text('Low'),
                                selected: _priority == 'Low',
                                onSelected: (selected) {
                                  setState(() {
                                    _priority = 'Low';
                                  });
                                },
                                selectedColor: Colors.green,
                                backgroundColor: Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: _priority == 'Low'
                                      ? Colors.white
                                      : Colors.black87,
                                  fontFamily: 'Poppins',
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Deadline Field
                    GestureDetector(
                      onTap: _selectDeadline,
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: _getModernInputDecoration(
                            label: 'Deadline',
                            icon: Icons.calendar_today,
                          ),
                          controller: TextEditingController(
                            text: _deadline != null
                                ? DateFormat('yyyy-MM-dd').format(_deadline!)
                                : '',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF004AAD),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.initialTask != null ? 'Update Task' : 'Add Task',
                        style: const TextStyle(
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