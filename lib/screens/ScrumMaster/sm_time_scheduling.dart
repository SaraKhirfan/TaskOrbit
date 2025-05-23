import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/sm_bottom_nav.dart';
import '../../widgets/sm_drawer.dart';
import 'package:task_orbit/main.dart';

class SMTimeSchedulingScreen extends StatefulWidget {
  const SMTimeSchedulingScreen({Key? key}) : super(key: key);

  @override
  State<SMTimeSchedulingScreen> createState() => _SMTimeSchedulingScreenState();
}

class _SMTimeSchedulingScreenState extends State<SMTimeSchedulingScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 2; // Set index for bottom navigation
  bool _isLoading = false;
  String? _selectedProject;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/scrumMasterHome');
    if (index == 1) Navigator.pushNamed(context, '/scrumMasterProjects');
    if (index == 2) Navigator.pushNamed(context, '/smTimeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/smMyProfile');
  }

  // Calendar variables
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  // Events storage - map date to event details
  Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _loadProjects();
    _loadEvents();
  }

  // Load user's projects
  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final projectService = Provider.of<ProjectService>(context, listen: false);
      await projectService.refreshProjects();

      if (mounted && projectService.projects.isNotEmpty) {
        setState(() {
          // Get the name or title from the first project
          final firstProject = projectService.projects[0];
          _selectedProject = firstProject['name'] ?? firstProject['title'] ?? 'Unnamed Project';
        });
      }
    } catch (e) {
      print('Error loading projects: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Load events from Firestore
  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      // Query events from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('events')
          .where('userId', isEqualTo: userId)
          .get();

      // Clear existing events
      _events.clear();

      // Process Firestore events
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();
        final normalizedDate = DateTime(date.year, date.month, date.day);

        if (_events[normalizedDate] == null) {
          _events[normalizedDate] = [];
        }

        _events[normalizedDate]!.add({
          'id': doc.id,
          'title': data['title'],
          'projectId': data['projectId'],
          'projectName': data['projectName'],
          'createdAt': data['createdAt'],
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading events: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  // Extract event titles for calendar display
  List<String> _getEventTitlesForDay(DateTime day) {
    final events = _getEventsForDay(day);
    return events.map((e) => e['title'] as String).toList();
  }


  void _showAddEventDialog(DateTime selectedDay) {
    showDialog(
      context: context,
      builder: (context) {
        String eventTitle = '';

        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                backgroundColor: Color(0xFFFDFDFD),
                title: Text(
                  'Add Event',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Project dropdown
                      Consumer<ProjectService>(
                        builder: (context, projectService, child) {
                          // If no projects are available
                          if (projectService.projects.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text("No projects available. Please create a project first."),
                            );
                          }

                          // Extract project names
                          final List<DropdownMenuItem<String>> dropdownItems = [];
                          for (var project in projectService.projects) {
                            final name = project['name'] ?? project['title'] ?? 'Unnamed Project';
                            dropdownItems.add(DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ));
                          }

                          return DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFFDFDFD),
                              labelText: 'Project',
                              labelStyle: TextStyle(color: Color(0xFF004AAD)), // Add label color
                              floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)), // Add floating label color
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFF004AAD)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
                              ),
                              // Add icon color
                              iconColor: Color(0xFF004AAD),
                            ),
                            value: _selectedProject,
                            items: dropdownItems,
                            onChanged: (value) {
                              setState(() {
                                _selectedProject = value;
                              });
                            },
                            // Apply blue color to dropdown icon and text
                            dropdownColor: const Color(0xFFFDFDFD),
                            icon: Icon(Icons.arrow_drop_down, color: Color(0xFF004AAD)),
                            style: TextStyle(color: Color(0xFF313131)),
                          );
                        },
                      ),

                      SizedBox(height: 16),

                      // Event title
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'Event Title',
                          labelStyle: TextStyle(color: Color(0xFF004AAD)), // Add label color
                          floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)), // Add floating label color
                          hintText: 'Enter event title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF004AAD)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
                          ),
                          // Add prefix icon for consistency
                          prefixIcon: Icon(Icons.event, color: Color(0xFF004AAD)),
                        ),
                        cursorColor: Color(0xFF004AAD), // Add cursor color
                        onChanged: (value) {
                          eventTitle = value;
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (eventTitle.isNotEmpty && _selectedProject != null) {
                        // Get the current user ID
                        final userId = FirebaseAuth.instance.currentUser?.uid;
                        if (userId == null) {
                          Navigator.pop(context);
                          return;
                        }

                        // Get project ID from project service
                        final projectService = Provider.of<ProjectService>(context, listen: false);
                        final projectIndex = projectService.projects.indexWhere(
                                (p) => (p['name'] ?? p['title'] ?? '') == _selectedProject
                        );

                        if (projectIndex == -1) {
                          Navigator.pop(context);
                          return;
                        }

                        final projectId = projectService.projects[projectIndex]['id'];

                        try {
                          // Add event to Firestore
                          await FirebaseFirestore.instance.collection('events').add({
                            'title': eventTitle,
                            'date': Timestamp.fromDate(selectedDay),
                            'userId': userId,
                            'projectId': projectId,
                            'projectName': _selectedProject,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          // Refresh events from Firestore
                          await _loadEvents();

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Event added'),
                              backgroundColor: Color(0xFF004AAD),
                            ),
                          );
                        } catch (e) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error adding event: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF004AAD),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Add'),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  // Delete an event
  Future<void> _deleteEvent(String eventId) async {
    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .delete();

      // Refresh events
      await _loadEvents();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event deleted'),
          backgroundColor: Color(0xFF004AAD),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting event: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      // Set resizeToAvoidBottomInset to false to prevent resize when keyboard appears
      resizeToAvoidBottomInset: false,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Time Scheduling"),
      drawer: SMDrawer(selectedItem: 'Time Scheduling'),
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF004AAD)))
            : SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Scheduling',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      // Info icon with tooltip instead of descriptive card
                      Tooltip(
                        message: 'Track important dates, deadlines, and team meetings for your projects. Add events to keep your team informed of upcoming activities.',
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF004AAD).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        waitDuration: Duration(milliseconds: 500),
                        showDuration: Duration(seconds: 3),
                        padding: EdgeInsets.all(12),
                        preferBelow: true,
                        child: Icon(
                          Icons.info_outline,
                          color: Color(0xFF004AAD),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8),

                // Calendar Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    color: Color(0xFFFDFDFD),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) {
                          return isSameDay(_selectedDay, day);
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: Color(0xFF004AAD),
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: Color(0xFF004AAD),
                          ),
                        ),
                        daysOfWeekHeight: 25, // Ensure day names have enough height
                        rowHeight: 45, // Reduced row height to prevent overflow
                        eventLoader: _getEventTitlesForDay,

                        calendarStyle: CalendarStyle(
                          outsideDaysVisible: true,
                          weekendTextStyle: TextStyle(color: Colors.red),
                          holidayTextStyle: TextStyle(color: Colors.red),
                          todayDecoration: BoxDecoration(
                            color: Color(0xFF004AAD).withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Color(0xFF004AAD),
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: Color(0xFF004AAD),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                          });

                          // Show events dialog for selected day
                          final events = _getEventsForDay(selectedDay);
                          if (events.isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: Color(0xFFFDFDFD),
                                  title: Text(
                                    'Events for ${DateFormat('MMM d, yyyy').format(selectedDay)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF313131),
                                    ),
                                  ),
                                  content: Container(
                                    color: Color(0xFFFDFDFD),
                                    width: double.maxFinite,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: events
                                            .map((event) => Card(
                                          color: Color(0xFFFDFDFD),
                                          margin: EdgeInsets.only(bottom: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          child: ListTile(
                                            contentPadding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            title: Text(
                                              event['title'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                SizedBox(height: 4),
                                                Text(
                                                  'Project: ${event['projectName']}',
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.delete, color: Colors.red),
                                              onPressed: () {
                                                Navigator.pop(context);
                                                _deleteEvent(event['id']);
                                              },
                                            ),
                                          ),
                                        ))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        'Close',
                                        style: TextStyle(
                                          color: Color(0xFF004AAD),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _showAddEventDialog(selectedDay);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF004AAD),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text('Add Event'),
                                    ),
                                  ],
                                );
                              },
                            );
                          } else {
                            // No events for this day, show add event dialog
                            _showAddEventDialog(selectedDay);
                          }
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                      ),
                    ),
                  ),
                ),

                // Today's events section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Color(0xFFFDFDFD),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Events",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF313131),
                            ),
                          ),
                          Divider(),
                          _getEventsForDay(DateTime.now()).isEmpty
                              ? Container(
                            height: 150, // Fixed height container
                            alignment: Alignment.center,
                            child: Text(
                              'No events scheduled for today',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                              : ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _getEventsForDay(DateTime.now()).length,
                            itemBuilder: (context, index) {
                              final event = _getEventsForDay(DateTime.now())[index];
                              return Card(
                                color: Color(0xFFE3EFFF),
                                margin: EdgeInsets.only(bottom: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: Color(0xFF004AAD),
                                    child: Icon(Icons.event, color: Colors.white),
                                  ),
                                  title: Text(
                                    event['title'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Project: ${event['projectName']}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteEvent(event['id']),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(_selectedDay),
        backgroundColor: MyApp.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: SMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}