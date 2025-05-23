import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:task_orbit/widgets/sm_drawer.dart';
import '../../services/RetrospectiveService.dart';
import 'active_retrospective_form_screen.dart';
import 'create_retrospective_form_screen.dart';
import 'draft_form_details_screen.dart';
import 'closed_retrospective_details_screen.dart';

class RetrospectiveScreen extends StatefulWidget {
  const RetrospectiveScreen({Key? key}) : super(key: key);

  @override
  _RetrospectiveScreenState createState() => _RetrospectiveScreenState();
}

class _RetrospectiveScreenState extends State<RetrospectiveScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  String? selectedProject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize by loading data
    _loadData();
  }

  Future<void> _loadData() async {
    final retroService = Provider.of<RetrospectiveService>(context, listen: false);
    setState(() => _isLoading = true);
    await retroService.loadRetrospectives();
    setState(() => _isLoading = false);
  }



  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushReplacementNamed(context, '/scrumMasterHome');
    if (index == 1)
      Navigator.pushReplacementNamed(context, '/scrumMasterProjects');
    if (index == 2)
      Navigator.pushReplacementNamed(context, '/smTimeScheduling');
    if (index == 3)
      Navigator.pushReplacementNamed(context, '/smMyProfile');
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

  void _createNewForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateRetrospectiveFormScreen()),
    );

    if (result != null) {
      // Refresh data after returning
      _loadData();
    }
  }

  void _viewExistingRetrospective(Map<String, dynamic> retrospective) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveRetrospectiveFormScreen(
          isNew: false,
          retrospective: retrospective,
        ),
      ),
    ).then((result) {
      // ALWAYS refresh data after returning, regardless of result
      _loadData();
    });
  }

  void _viewDraftRetrospective(Map<String, dynamic> draftForm) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DraftFormDetailsScreen(draftForm: draftForm),
      ),
    );

    if (result != null) {
      // Refresh data after returning
      _loadData();
    }
  }

  void _viewClosedRetrospective(Map<String, dynamic> closedForm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClosedRetrospectiveDetailsScreen(
          closedForm: closedForm,
        ),
      ),
    ).then((result) {
      // ALWAYS refresh data after returning
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RetrospectiveService>(
      builder: (context, retroService, child) {
        // Get lists from service
        final projects = ['All Projects']
          ..addAll(retroService.projects.map((p) => p['name'] as String));

        // Get filtered retrospectives based on selected project
        List<Map<String, dynamic>> filteredExisting = [];
        List<Map<String, dynamic>> filteredDrafts = [];
        List<Map<String, dynamic>> filteredClosed = [];

        if (selectedProject == null || selectedProject == 'All Projects') {
          filteredExisting = retroService.activeRetrospectives;
          filteredDrafts = retroService.draftRetrospectives;
          filteredClosed = retroService.closedRetrospectives;
        } else {
          filteredExisting = retroService.activeRetrospectives
              .where((r) => r['projectName'] == selectedProject)
              .toList();
          filteredDrafts = retroService.draftRetrospectives
              .where((r) => r['projectName'] == selectedProject)
              .toList();
          filteredClosed = retroService.closedRetrospectives
              .where((r) => r['projectName'] == selectedProject)
              .toList();
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFFDFDFD),
          appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Retrospective"),
          drawer: SMDrawer(selectedItem: 'Retrospective'),
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/MyProjects.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
              children: [
                // Back button and title
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF004AAD),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Retrospective Feedback',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // New Form Button
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          child: ElevatedButton(
                            onPressed: _createNewForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF004AAD),
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'New Form',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Project filter dropdown
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filter by Project',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF313131),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xFFFDFDFD),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!, width: 1),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: selectedProject ?? 'All Projects',
                                    hint: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 16),
                                      child: Text('Select Project'),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        selectedProject = value;
                                      });

                                      // When project changes, update filter
                                      if (value != null && value != 'All Projects') {
                                        final projectId = retroService.projects
                                            .firstWhere((p) => p['name'] == value,
                                            orElse: () => {'id': ''})['id'];

                                        if (projectId.isNotEmpty) {
                                          retroService.loadRetrospectives(projectId: projectId);
                                        }
                                      } else {
                                        retroService.loadRetrospectives();
                                      }
                                    },
                                    items: projects.map((String project) {
                                      return DropdownMenuItem<String>(
                                        value: project,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            project,
                                            style: const TextStyle(
                                              color: Color(0xFF313131),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Open Retrospectives Section
                        if (filteredExisting.isNotEmpty) ...[
                          _buildSectionHeader('Active Forms'),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredExisting.length,
                            itemBuilder: (context, index) {
                              final retro = filteredExisting[index];
                              return _buildRetroCard(
                                retro,
                                onTap: () => _viewExistingRetrospective(retro),
                              );
                            },
                          ),
                          SizedBox(height: 24),
                        ],

                        // Draft Retrospectives Section
                        if (filteredDrafts.isNotEmpty) ...[
                          _buildSectionHeader('Draft Forms'),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredDrafts.length,
                            itemBuilder: (context, index) {
                              final draft = filteredDrafts[index];
                              return _buildDraftCard(
                                draft,
                                onTap: () => _viewDraftRetrospective(draft),
                              );
                            },
                          ),
                          SizedBox(height: 24),
                        ],

                        // Closed Retrospectives Section
                        if (filteredClosed.isNotEmpty) ...[
                          _buildSectionHeader('Closed Forms'),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredClosed.length,
                            itemBuilder: (context, index) {
                              final closed = filteredClosed[index];
                              return _buildRetroCard(
                                closed,
                                onTap: () => _viewClosedRetrospective(closed),
                              );
                            },
                          ),
                          SizedBox(height: 24),
                        ],

                        // Empty state message
                        if (filteredExisting.isEmpty && filteredDrafts.isEmpty && filteredClosed.isEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.assignment_outlined,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No retrospective forms found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Create your first retrospective form to get started',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Bottom spacing to fill screen
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFDFDFD),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, "Home", 0),
                _buildNavItem(Icons.assignment, "Project", 1),
                _buildNavItem(Icons.access_time_filled_rounded, "Schedule", 2),
                _buildNavItem(Icons.person, "Profile", 3),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF313131),
        ),
      ),
    );
  }

  Widget _buildRetroCard(Map<String, dynamic> retro, {required VoidCallback onTap}) {
    // Calculate number of responses
    final responses = retro['responses'] as List<dynamic>? ?? [];
    final responseCount = responses.length;

    // Get status from retrospective data
    final String status = retro['status']?.toString().toUpperCase() ?? 'UNKNOWN';

    // Determine status color and background
    Color statusColor;
    Color statusBackgroundColor;

    switch (status) {
      case 'OPEN':
      case 'ACTIVE':
        statusColor = Colors.green[700]!;
        statusBackgroundColor = Colors.green.withOpacity(0.1);
        break;
      case 'CLOSED':
        statusColor = Colors.red[700]!;
        statusBackgroundColor = Colors.red.withOpacity(0.1);
        break;
      case 'DRAFT':
        statusColor = Colors.orange[700]!;
        statusBackgroundColor = Colors.orange.withOpacity(0.1);
        break;
      default:
        statusColor = Colors.grey[700]!;
        statusBackgroundColor = Colors.grey.withOpacity(0.1);
    }

    return Card(
      color: Color(0xFFFDFDFD),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      retro['projectName'] ?? 'Unknown Project',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Form title
              Text(
                retro['formTitle'] ?? 'Untitled Form',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004AAD),
                ),
              ),
              SizedBox(height: 4),

              // Sprint name
              if (retro['sprintName'] != null && retro['sprintName'].isNotEmpty) ...[
                Text(
                  retro['sprintName'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
              ],

              // User response count
              Row(
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 18,
                    color: Color(0xFF004AAD),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '$responseCount ${responseCount == 1 ? 'user' : 'users'} responded',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF004AAD),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> draft, {required VoidCallback onTap}) {
    return Card(
      color: Color(0xFFFDFDFD),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets
              .all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      draft['projectName'] ?? 'Unknown Project',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'DRAFT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Form title
              Text(
                draft['formTitle'] ?? 'Untitled Form',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
              SizedBox(height: 4),

              // Sprint name
              if (draft['sprintName'] != null && draft['sprintName'].isNotEmpty) ...[
                Text(
                  draft['sprintName'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClosedCard(Map<String, dynamic> closed, {required VoidCallback onTap}) {
    return Card(
      color: Color(0xFFFDFDFD),
      margin: EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      closed['projectName'] ?? 'Unknown Project',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'CLOSED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Form title
              Text(
                closed['formTitle'] ?? 'Untitled Form',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
              SizedBox(height: 4),

              // Sprint name
              if (closed['sprintName'] != null && closed['sprintName'].isNotEmpty) ...[
                Text(
                  closed['sprintName'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 12),
              ],

              // Completion rate text only for closed forms
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Colors.green[700],
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Completed with ${closed['completionRate'] ?? 0}% response rate',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}