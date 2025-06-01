import 'package:flutter/material.dart';
import 'package:task_orbit/widgets/drawer_header.dart';
import 'package:intl/intl.dart';

import '../../widgets/product_owner_drawer.dart';

class AddTaskScreen extends StatefulWidget {
  final String storyTitle;

  const AddTaskScreen({super.key, required this.storyTitle});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _whatController = TextEditingController();
  final _whyController = TextEditingController();
  final _howController = TextEditingController();
  final _acceptanceCriteriaController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  String _priority = 'Medium';
  DateTime? _dueDate;
  final List<String> _attachments = [];

  @override
  void dispose() {
    _titleController.dispose();
    _whatController.dispose();
    _whyController.dispose();
    _howController.dispose();
    _acceptanceCriteriaController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final newTask = {
        'title': _titleController.text,
        'what': _whatController.text,
        'why': _whyController.text,
        'how': _howController.text,
        'acceptanceCriteria': _acceptanceCriteriaController.text,
        'priority': _priority,
        'dueDate': _dueDate != null ? DateFormat('yyyy-MM-dd').format(_dueDate!) : '',
        'attachments': _attachments,
      };

      Navigator.pop(context, newTask); // Return the new task to previous screen
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

  void _addAttachment() {
    // Placeholder for file attachment functionality
    setState(() {
      _attachments.add('File ${_attachments.length + 1}');
    });
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
                  const Text(
                    'Add Task',
                    style: TextStyle(
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
                  widget.storyTitle,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF313131)),
                ),
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
                        icon: Icons.assignment,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter task title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Divider(),
                    const SizedBox(height: 8),
                    // Description Section Label
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // What Field
                    TextFormField(
                      controller: _whatController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: _getModernInputDecoration(
                        label: 'What?',
                        icon: Icons.help_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe what this task is about';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Why Field
                    TextFormField(
                      controller: _whyController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: _getModernInputDecoration(
                        label: 'Why?',
                        icon: Icons.info_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please explain why this task is necessary';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // How Field
                    TextFormField(
                      controller: _howController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      minLines: 1,
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                      decoration: _getModernInputDecoration(
                        label: 'How?',
                        icon: Icons.build_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please describe how this task will be completed';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Divider(),
                    const SizedBox(height: 8),

                    // Acceptance Criteria Field
                    TextFormField(
                      controller: _acceptanceCriteriaController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF313131),
                      ),
                      minLines: 1,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      decoration: _getModernInputDecoration(
                        label: 'Acceptance Criteria',
                        icon: Icons.check_circle_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter acceptance criteria';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Divider(),
                    const SizedBox(height: 8),
                    // Priority Selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Priority',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
                                  setState(() {
                                    _priority = 'High';
                                  });
                                },
                                selectedColor: Colors.red,
                                backgroundColor: Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: _priority == 'High' ? Colors.white : Colors.black87,
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
                                  color: _priority == 'Medium' ? Colors.white : Colors.black87,
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
                                  color: _priority == 'Low' ? Colors.white : Colors.black87,
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
                    const SizedBox(height: 8),
                    Divider(),
                    const SizedBox(height: 8),

                    // Due Date Field
                    GestureDetector(
                      onTap: _selectDueDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text: _dueDate == null
                                ? ''
                                : DateFormat('dd-MM-yyyy').format(_dueDate!),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF313131),
                          ),
                          decoration: _getModernInputDecoration(
                            label: 'Due Date',
                            icon: Icons.calendar_month,
                          ),
                          validator: (value) {
                            if (_dueDate == null) {
                              return 'Please select due date';
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(),
                    const SizedBox(height: 8),

                    // Attachments Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Attachments',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Color(0xFF004AAD)),
                              onPressed: _addAttachment,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ..._attachments.map((attachment) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.insert_drive_file, color: Color(0xFF004AAD)),
                              const SizedBox(width: 8),
                              Text(attachment),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    _attachments.remove(attachment);
                                  });
                                },
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Add Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: const Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _saveTask,
                        child: const Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFFFDFDFD),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF004AAD),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins-SemiBold',
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'Poppins-SemiBold',
          fontWeight: FontWeight.bold,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects',),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

