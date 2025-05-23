import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity_log_model.dart';
import '../../services/activity_log_service.dart';
import '../../widgets/activity_log_item.dart';


class ActivitylogsScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const ActivitylogsScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  State<ActivitylogsScreen> createState() => _ActivitylogsScreenState();
}

class _ActivitylogsScreenState extends State<ActivitylogsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _filterType = 'all';
  String? _selectedUserId;

  @override
  Widget build(BuildContext context) {
    // Get the ActivityLogService from the provider
    final activityLogService = Provider.of<ActivityLogService>(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        title: Text(
          'Activity Logs',
          style: TextStyle(
            color: Color(0xFF004AAD),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: Color(0xFF004AAD)),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Colors.white, Color(0xFFE3EFFF)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: Color(0xFF004AAD),
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.projectName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Filter chips (if needed)
            if (_filterType != 'all' || _selectedUserId != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    if (_filterType != 'all')
                      Chip(
                        label: Text(
                          'Type: ${_filterType.toUpperCase()}',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Color(0xFF004AAD),
                        onDeleted: () {
                          setState(() {
                            _filterType = 'all';
                          });
                        },
                        deleteIconColor: Colors.white,
                      ),
                    if (_selectedUserId != null)
                      Chip(
                        label: Text(
                          'By User',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Color(0xFF004AAD),
                        onDeleted: () {
                          setState(() {
                            _selectedUserId = null;
                          });
                        },
                        deleteIconColor: Colors.white,
                      ),
                  ],
                ),
              ),

            SizedBox(height: 8),

            // Activity Logs Stream
            Expanded(
              child: StreamBuilder<List<ActivityLog>>(
                stream: _getFilteredStream(activityLogService),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: Color(0xFF004AAD)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.withOpacity(0.7),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error loading activity logs',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                // Refresh the stream
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF004AAD),
                              foregroundColor: Colors.white,
                            ),
                            child: Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  final logs = snapshot.data ?? [];

                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Color(0xFF004AAD).withOpacity(0.5),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No activity logs found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            _filterType != 'all' || _selectedUserId != null
                                ? 'Try removing filters to see more results'
                                : 'There hasn\'t been any activity for this project yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF666666),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      // Use your ActivityLogItem widget here
                      return ActivityLogItem(
                        log: log,
                        onTap: () {
                          // Handle tap if needed
                          // For example, show details of the activity
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get the appropriate filtered stream based on current filter settings
  Stream<List<ActivityLog>> _getFilteredStream(ActivityLogService service) {
    if (_selectedUserId != null) {
      return service.getLogsByUser(widget.projectId, _selectedUserId!);
    } else if (_filterType != 'all') {
      return service.getFilteredLogs(widget.projectId, _filterType);
    } else {
      return service.getProjectActivityLogs(widget.projectId);
    }
  }

  // Show filter options dialog
  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Activity Logs',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'By Activity Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All', 'all', setState),
                      _filterChip('Task', 'task', setState),
                      _filterChip('Sprint', 'sprint', setState),
                      _filterChip('Project', 'project', setState),
                      _filterChip('User', 'user', setState),
                      _filterChip('Backlog', 'backlog', setState),
                      _filterChip('Retrospective', 'retrospective', setState),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          this.setState(() {
                            _filterType = 'all';
                            _selectedUserId = null;
                          });
                        },
                        child: Text('Reset Filters'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF004AAD),
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper to create filter chips
  Widget _filterChip(String label, String value, StateSetter setState) {
    return FilterChip(
      label: Text(label),
      selected: _filterType == value,
      selectedColor: Color(0xFF004AAD).withOpacity(0.2),
      checkmarkColor: Color(0xFF004AAD),
      onSelected: (selected) {
        setState(() {
          _filterType = selected ? value : 'all';
        });

        this.setState(() {
          _filterType = selected ? value : 'all';
        });
      },
    );
  }
}