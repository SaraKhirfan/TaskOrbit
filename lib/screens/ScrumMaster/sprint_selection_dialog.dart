// lib/screens/scrum_master/sprint_selection_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/sprint_service.dart';

class SprintSelectionDialog extends StatefulWidget {
  final String projectId;

  const SprintSelectionDialog({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  _SprintSelectionDialogState createState() => _SprintSelectionDialogState();
}

class _SprintSelectionDialogState extends State<SprintSelectionDialog> {
  List<Map<String, dynamic>> _sprints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final sprintService = Provider.of<SprintService>(context, listen: false);
      final loadedSprints = await sprintService.getSprints(widget.projectId);

      if (mounted) {
        setState(() {
          _sprints = loadedSprints;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sprints: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _createNewSprint() async {
    // Show dialog to create a new sprint
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddSprintDialog(),
    );

    if (result != null) {
      try {
        final sprintService = Provider.of<SprintService>(context, listen: false);

        // Create sprint in Firestore and get the ID
        final sprintId = await sprintService.createSprint(
          widget.projectId,
          result,
        );

        // Return the newly created sprint's ID
        Navigator.of(context).pop(sprintId);

      } catch (e) {
        print('Error creating sprint: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create sprint: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor:  Color(0xFFFDFDFD),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Sprint',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
            ),
            SizedBox(height: 16),

            if (_isLoading)
              Center(
                child: CircularProgressIndicator(),
              )
            else if (_sprints.isEmpty)
              Text(
                'No active sprints found. Create a new sprint.',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              )
            else
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: _sprints.map((sprint) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop(sprint['id']);
                        },
                        child: Container(
                          margin: EdgeInsets.only(bottom: 8),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Color(0xFF004AAD).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sprint['name'] ?? 'Sprint',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF313131),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Duration: ${sprint['duration']} weeks',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Color(0xFF004AAD),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

            SizedBox(height: 16),

            // Create New Sprint option
            GestureDetector(
              onTap: _createNewSprint,
              child: Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF004AAD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Create New Sprint',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Add Sprint Dialog
class AddSprintDialog extends StatefulWidget {
  @override
  _AddSprintDialogState createState() => _AddSprintDialogState();
}

class _AddSprintDialogState extends State<AddSprintDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final _durationController = TextEditingController();
  String _startDate = 'Select date';
  String _endDate = 'Select date';

  final Color primaryColor = Color(0xFF004AAD);
  final Color errorColor = Colors.red;

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
      fillColor: Color(0xFFFDFDFD),
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
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 14)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = '${picked.day}/${picked.month}/${picked.year}';
      });
    }
  }

  void _createSprint() {
    if (_formKey.currentState!.validate()) {
      if (_startDate == 'Select date' || _endDate == 'Select date') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select both start and end dates')),
        );
        return;
      }

      final newSprint = {
        'name': _nameController.text,
        'goal': _goalController.text,
        'startDate': _startDate,
        'endDate': _endDate,
        'duration': int.parse(_durationController.text),
        'status': 'Planning',
        'progress': 0,
        'backlogItems': [],
      };

      Navigator.of(context).pop(newSprint);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFFFDFDFD),
      title: Text('Add New Sprint'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sprint Name
              TextFormField(
                controller: _nameController,
                decoration: _getModernInputDecoration(
                  label: 'Sprint Name',
                  icon: Icons.notes,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a sprint name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Sprint Goal
              TextFormField(
                controller: _goalController,
                decoration: _getModernInputDecoration(
                  label: 'Sprint Goal',
                  icon: Icons.task_rounded,
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a sprint goal';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              // Duration
              TextFormField(
                controller: _durationController,
                decoration: _getModernInputDecoration(
                  label: 'Duration (weeks)',
                  icon: Icons.access_time_filled_rounded,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter sprint duration';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start Date
                  Text('Start Date'),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectStartDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_startDate),
                          Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12),
                  Text('End Date'),
                  SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectEndDate(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_endDate),
                          Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
          style: TextButton.styleFrom(
            foregroundColor: Color(0xFF004AAD),
          ),
        ),
        ElevatedButton(
          onPressed: _createSprint,
          child: Text('Create Sprint'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF004AAD),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}