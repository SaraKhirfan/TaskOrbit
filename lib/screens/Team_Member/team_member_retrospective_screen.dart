import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Team_Member/team_member_retrospective_form_screen.dart';
import '../../services/RetrospectiveService.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamMemberRetrospectiveScreen extends StatefulWidget {
  const TeamMemberRetrospectiveScreen({Key? key}) : super(key: key);

  @override
  State<TeamMemberRetrospectiveScreen> createState() => _TeamMemberRetrospectiveScreenState();
}

class _TeamMemberRetrospectiveScreenState extends State<TeamMemberRetrospectiveScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    // Load retrospectives from Firebase when screen initializes
    _loadRetrospectives();
  }

  Future<void> _loadRetrospectives() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load retrospectives using the service
      final retroService = Provider.of<RetrospectiveService>(context, listen: false);
      await retroService.loadRetrospectives();
    } catch (e) {
      print('Error loading retrospectives: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading retrospective forms. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Retrospective"),
      drawer: const TeamMemberDrawer(selectedItem: 'Retrospective'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF004AAD),))
          : Consumer<RetrospectiveService>(
        builder: (context, retroService, child) {
          // Get only active retrospectives
          final activeForms = retroService.activeRetrospectives;
          final closedForms = retroService.closedRetrospectives;

          return RefreshIndicator(
            onRefresh: _loadRetrospectives,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Retrospective',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF313131),
                      ),
                    ),
                    SizedBox(height: 12,),
                    const Text(
                      'Please answer the available retrospective forms to track your work',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Active forms section
                    if (activeForms.isNotEmpty) ...[
                      const Text(
                        'Active Forms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...activeForms.map((form) => _buildRetrospectiveCard(form, true)).toList(),
                      const SizedBox(height: 24),
                    ],

                    // Closed forms section
                    if (closedForms.isNotEmpty) ...[
                      const Text(
                        'Closed Forms',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...closedForms.map((form) => _buildRetrospectiveCard(form, false)).toList(),
                    ],

                    // No forms message
                    if (activeForms.isEmpty && closedForms.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No retrospective forms available',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildRetrospectiveCard(Map<String, dynamic> form, bool isActive) {
    final bool hasResponded = _checkIfUserResponded(form);

    return Card(
      color: Color(0xFFFDFDFD),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colored border
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? hasResponded
                    ? Colors.green
                    : Color(0xFF004AAD)
                    : Colors.grey,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),

            // Form content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Project and Sprint Name
                    Text(
                      form['projectName'] ?? 'Project Name',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      form['sprintName'] ?? 'Sprint Name',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Form Title
                    Text(
                      form['formTitle'] ?? 'Form Title',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Status and Due Date
                    Row(
                      children: [
                        // Status
                        const Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive
                                ? hasResponded
                                ? Colors.green
                                : Color(0xFF004AAD)
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isActive
                                ? hasResponded
                                ? 'Completed'
                                : 'Open'
                                : 'Closed',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        Spacer(),

                        // Due Date (if available)
                        if (form['dueDate'] != null && form['dueDate'].toString().isNotEmpty)
                          Text(
                            'Due: ${form['dueDate']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Forward button (only for active forms that aren't completed)
            if (isActive && !hasResponded)
              Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF004AAD),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamMemberRetrospectiveFormScreen(
                          form: form,
                          viewOnly: false, // CHANGED from readOnly to viewOnly
                        ),
                      ),
                    ).then((_) {
                      // Refresh the list when returning from form screen
                      _loadRetrospectives();
                    });
                  },
                ),
              ),

            // View icon for completed or closed forms
            if ((isActive && hasResponded) || !isActive)
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive && hasResponded ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamMemberRetrospectiveFormScreen(
                          form: form,
                          viewOnly: true, // CHANGED from readOnly to viewOnly
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _checkIfUserResponded(Map<String, dynamic> form) {
    // Check if current user has already responded to this form
    if (form.containsKey('responses') && form['responses'] is List) {
      final responses = List<Map<String, dynamic>>.from(form['responses']);
      final currentUserId = _auth.currentUser?.uid;

      if (currentUserId != null) {
        return responses.any((response) =>
        response.containsKey('userId') && response['userId'] == currentUserId);
      }
    }
    return false;
  }
}