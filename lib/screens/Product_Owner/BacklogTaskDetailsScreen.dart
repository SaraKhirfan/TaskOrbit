import 'package:flutter/material.dart';
import 'package:task_orbit/widgets/drawer_header.dart';
import 'package:intl/intl.dart';

import '../../widgets/product_owner_drawer.dart';

class BacklogTaskDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> task;
  final String storyTitle;
  final bool isReadOnly;

  const BacklogTaskDetailsScreen({
    Key? key,
    required this.task,
    required this.storyTitle,
    this.isReadOnly = false,
  }) : super(key: key);

  @override
  State<BacklogTaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<BacklogTaskDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isEditing = false;


  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _whatController;
  late TextEditingController _whyController;
  late TextEditingController _howController;
  late TextEditingController _acceptanceCriteriaController;
  late String _priority;
  late DateTime? _dueDate;
  late List<String> _attachments;


  @override
  void initState() {
    super.initState();

    // Initialize controllers with task data
    _titleController = TextEditingController(text: widget.task['title'] ?? '');
    _whatController = TextEditingController(text: widget.task['what'] ?? '');
    _whyController = TextEditingController(text: widget.task['why'] ?? '');
    _howController = TextEditingController(text: widget.task['how'] ?? '');
    _acceptanceCriteriaController = TextEditingController(text: widget.task['acceptanceCriteria'] ?? '');
    _priority = widget.task['priority'] ?? 'Medium';

    // Parse date if available
    _dueDate = widget.task['dueDate'] != null && widget.task['dueDate'].isNotEmpty
        ? DateFormat('yyyy-MM-dd').parse(widget.task['dueDate'])
        : null;

    // Initialize attachments
    _attachments = List<String>.from(widget.task['attachments'] ?? []);
  }

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
    if (index == 2) Navigator.pushNamed(context, '/settings');
    if (index == 3) Navigator.pushNamed(context, '/profile');
  }

  void _toggleEditMode() {
    // Don't allow editing if in read-only mode
    if (widget.isReadOnly) return;

    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveTask() {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedTask = {
        'title': _titleController.text,
        'what': _whatController.text,
        'why': _whyController.text,
        'how': _howController.text,
        'acceptanceCriteria': _acceptanceCriteriaController.text,
        'priority': _priority,
        'dueDate': _dueDate != null ? DateFormat('yyyy-MM-dd').format(_dueDate!) : '',
        'attachments': _attachments,
      };

      Navigator.pop(context, updatedTask);
    }
  }

  void _deleteTask() {
    // Don't allow deleting if in read-only mode
    if (widget.isReadOnly) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${widget.task['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Return with delete flag
              Navigator.pop(context, {'delete': true});
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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
    if (!_isEditing) return;

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
    if (!_isEditing) return;

    // Placeholder for file attachment functionality
    setState(() {
      _attachments.add('File ${_attachments.length + 1}');
    });
  }

  void _removeAttachment(String attachment) {
    if (!_isEditing) return;

    setState(() {
      _attachments.remove(attachment);
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
      drawer: const ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFEDF1F3), Color(0xFFE3EFFF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF004AAD),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _isEditing ? 'Edit Task' : 'Task Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                    ),
                    // Edit button - only show if not in read-only mode
                    if (!widget.isReadOnly)
                      IconButton(
                        icon: Icon(_isEditing ? Icons.check : Icons.edit),
                        color: const Color(0xFF004AAD),
                        onPressed: _isEditing ? _saveTask : _toggleEditMode,
                      ),
                    // Delete button (only show when editing and not in read-only mode)
                    if (_isEditing && !widget.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Colors.red,
                        onPressed: _deleteTask,
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
                const SizedBox(height: 24),

                // Form content
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Task Title Field
                      _isEditing
                          ? TextFormField(
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
                      )
                          : _buildInfoCard(
                        title: 'Task Title',
                        content: _titleController.text,
                        icon: Icons.assignment,
                      ),
                      const SizedBox(height: 24),

                      // What Field
                      _isEditing
                          ? TextFormField(
                        controller: _whatController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF313131),
                        ),
                        decoration: _getModernInputDecoration(
                          label: 'What (Task Description)',
                          icon: Icons.description,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter what the task is about';
                          }
                          return null;
                        },
                      )
                          : _buildInfoCard(
                        title: 'What',
                        content: _whatController.text,
                        icon: Icons.description,
                      ),
                      const SizedBox(height: 24),

                      // Why Field
                      _isEditing
                          ? TextFormField(
                        controller: _whyController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF313131),
                        ),
                        decoration: _getModernInputDecoration(
                          label: 'Why (Task Purpose)',
                          icon: Icons.help_outline,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter why this task is needed';
                          }
                          return null;
                        },
                      )
                          : _buildInfoCard(
                        title: 'Why',
                        content: _whyController.text,
                        icon: Icons.help_outline,
                      ),
                      const SizedBox(height: 24),

                      // How Field
                      _isEditing
                          ? TextFormField(
                        controller: _howController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF313131),
                        ),
                        decoration: _getModernInputDecoration(
                          label: 'How (Implementation Details)',
                          icon: Icons.settings,
                        ),
                      )
                          : _buildInfoCard(
                        title: 'How',
                        content: _howController.text,
                        icon: Icons.settings,
                      ),
                      const SizedBox(height: 24),

                      // Acceptance Criteria Field
                      _isEditing
                          ? TextFormField(
                        controller: _acceptanceCriteriaController,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF313131),
                        ),
                        decoration: _getModernInputDecoration(
                          label: 'Acceptance Criteria',
                          icon: Icons.checklist,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter acceptance criteria';
                          }
                          return null;
                        },
                      )
                          : _buildInfoCard(
                        title: 'Acceptance Criteria',
                        content: _acceptanceCriteriaController.text,
                        icon: Icons.checklist,
                      ),
                      const SizedBox(height: 24),

                      // Priority Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.flag,
                                  color: Color(0xFF004AAD),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Priority',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _isEditing
                                ? Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildPriorityChip('High', Colors.red),
                                _buildPriorityChip(
                                    'Medium', Colors.orange),
                                _buildPriorityChip('Low', Colors.green),
                              ],
                            )
                                : Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(_priority),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _priority,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Due Date Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF004AAD),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Due Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _isEditing
                                    ? ElevatedButton.icon(
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(_dueDate == null
                                      ? 'Select Date'
                                      : DateFormat('yyyy-MM-dd')
                                      .format(_dueDate!)),
                                  onPressed: _selectDueDate,
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                    const Color(0xFF004AAD),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                                    : Text(
                                  _dueDate == null
                                      ? 'Not set'
                                      : DateFormat('yyyy-MM-dd')
                                      .format(_dueDate!),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF313131),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Attachments Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_file,
                                      color: Color(0xFF004AAD),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Attachments',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF313131),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isEditing)
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    color: const Color(0xFF004AAD),
                                    onPressed: _addAttachment,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _attachments.isEmpty
                                ? const Center(
                              child: Text(
                                'No attachments',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            )
                                : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _attachments.length,
                              itemBuilder: (context, index) {
                                final attachment = _attachments[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.insert_drive_file,
                                    color: Color(0xFF004AAD),
                                  ),
                                  title: Text(attachment),
                                  trailing: _isEditing
                                      ? IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _removeAttachment(
                                        attachment),
                                  )
                                      : null,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF004AAD),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.isEmpty ? 'Not specified' : content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChip(String label, Color color) {
    final isSelected = _priority == label;
    return InkWell(
      onTap: () {
        if (_isEditing) {
          setState(() {
            _priority = label;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return const Color(0xFF004AAD);
    }
  }

  BottomNavigationBar _buildBottomNavBar() {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFDFDFD),
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF004AAD),
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home',),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects',),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile',),
      ],
    );
  }
}