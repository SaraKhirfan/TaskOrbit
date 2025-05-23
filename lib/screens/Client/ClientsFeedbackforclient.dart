import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../services/FeedbackService.dart';
import '../../widgets/clientBottomNav.dart';
import '../../widgets/client_drawer.dart';
import '../../widgets/sm_app_bar.dart';
import 'client_project_details_screen.dart';

class ClientFeedbackScreen extends StatefulWidget {
  const ClientFeedbackScreen({Key? key}) : super(key: key);

  @override
  State<ClientFeedbackScreen> createState() => _ClientFeedbackScreenState();
}

class _ClientFeedbackScreenState extends State<ClientFeedbackScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userProjects = [];
  List<Map<String, dynamic>> _clientFeedback = []; // New list to store client feedback

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
    _loadClientFeedback(); // Load client feedback
  }

  Future<void> _loadUserProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _userProjects = [];
        });
        return;
      }

      // Force refresh of projects from Firestore
      final projectService = Provider.of<ProjectService>(
          context, listen: false);
      await projectService.refreshProjects();

      // Get all projects
      final allProjects = projectService.projects;

      // Filter projects to get only those where current user is a member
      final userProjects = allProjects.where((project) {
        if (project.containsKey('members') && project['members'] is List) {
          return (project['members'] as List).contains(user.uid);
        }
        return false;
      }).toList();

      if (mounted) {
        setState(() {
          _userProjects = userProjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user projects: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Update the _loadClientFeedback method in ClientFeedbackScreen
  Future<void> _loadClientFeedback() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('DEBUG: User is null in _loadClientFeedback');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('DEBUG: Current user ID: ${user.uid}');

      final feedbackService = Provider.of<FeedbackService>(context, listen: false);

      // Try the direct method first
      List<Map<String, dynamic>> feedback = await feedbackService.getClientFeedbackDirect();

      print('DEBUG: Fetched feedback count (direct method): ${feedback.length}');

      // If direct method finds nothing, try the original method
      if (feedback.isEmpty) {
        print('DEBUG: Direct method found no feedback, trying original method...');
        feedback = await feedbackService.getClientFeedback();
        print('DEBUG: Fetched feedback count (original method): ${feedback.length}');
      }

      if (feedback.isEmpty) {
        print('DEBUG: No feedback found for user, checking if any feedback exists...');
        // Check if any feedback exists at all to help debug
        final projectsService = Provider.of<ProjectService>(context, listen: false);
        final projects = projectsService.projects;

        if (projects.isNotEmpty) {
          // Check the first project for any feedback
          final anyFeedback = await feedbackService.checkFeedbackCollectionExists(projects[0]['id']);
          print('DEBUG: Any feedback exists in first project: $anyFeedback');
        }
      }

      if (mounted) {
        setState(() {
          _clientFeedback = feedback;
          _isLoading = false;
        });

      }
    } catch (e) {
      print('ERROR loading client feedback: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/clientHome');
    if (index == 1) Navigator.pushNamed(context, '/clientProjects');
    if (index == 2) Navigator.pushNamed(context, '/clientTimeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/clientProfile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Feedback"),
      drawer: ClientDrawer(selectedItem: 'Feedback'),
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/MyProjects.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Feedback',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'View your submitted feedback and any responses',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _clientFeedback.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.feedback_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No feedback submitted yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your feedback will appear here after you submit it for completed sprints',
                          style: TextStyle(color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/clientProjects');
                          },
                          label: Text('Go to Projects', style: TextStyle(color: Colors.white),),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF004AAD),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: () async {
                      await _loadClientFeedback();
                    },
                    child: ListView.separated(
                      itemCount: _clientFeedback.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 15),
                      itemBuilder: (context, index) =>
                          _buildFeedbackCard(_clientFeedback[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: clientBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  // Build a feedback card
  Widget _buildFeedbackCard(Map<String, dynamic> feedback) {
    final hasResponse = feedback['response'] != null && feedback['response'].toString().isNotEmpty;
    final int rating = feedback['rating'] ?? 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFFDFDFD),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Project and Sprint info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_outlined, size: 16, color: Color(0xFF004AAD)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              feedback['projectName'] ?? 'Unknown Project',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF004AAD),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.running_with_errors, size: 16, color: Colors.grey[700]),
                          SizedBox(width: 4),
                          Text(
                            feedback['sprintName'] ?? 'Unknown Sprint',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Date
                Text(
                  feedback['dateSubmitted'] ?? 'No date',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),

            // Divider
            Divider(height: 24),

            // Rating
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your Rating: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  ...List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: index < rating ? Colors.amber : Colors.grey,
                      size: 16,
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 12),

            // Comment
            Text(
              'Your Feedback:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 4),
            Text(
              feedback['comment'] ?? 'No comment provided',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),

            // Response (if available)
            if (hasResponse) ...[
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Color(0xFF004AAD)),
                        SizedBox(width: 4),
                        Text(
                          'Product Owner Response:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004AAD),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      feedback['response'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF004AAD).withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}