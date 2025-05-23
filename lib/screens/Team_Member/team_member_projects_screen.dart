import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/project_service.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/sm_app_bar.dart';
import '../../widgets/team_member_drawer.dart';
import 'team_member_project_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeamMemberProjectsScreen extends StatefulWidget {
  const TeamMemberProjectsScreen({Key? key}) : super(key: key);

  @override
  State<TeamMemberProjectsScreen> createState() => _TeamMemberProjectsScreenState();
}

class _TeamMemberProjectsScreenState extends State<TeamMemberProjectsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 1;
  bool _isLoading = true;
  List<Map<String, dynamic>> _userProjects = [];

  @override
  void initState() {
    super.initState();
    _loadUserProjects();
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
        // Check legacy members array
        if (project.containsKey('members') && project['members'] is List) {
          if ((project['members'] as List).contains(user.uid)) {
            return true;
          }
        }

        // Check new role-based structure
        if (project.containsKey('roles') && project['roles'] != null) {
          final roles = project['roles'];

          // Check if user is in teamMembers array
          if (roles.containsKey('teamMembers') && roles['teamMembers'] is List) {
            if ((roles['teamMembers'] as List).contains(user.uid)) {
              return true;
            }
          }

          // Check if user is in scrumMasters array
          if (roles.containsKey('scrumMasters') && roles['scrumMasters'] is List) {
            if ((roles['scrumMasters'] as List).contains(user.uid)) {
              return true;
            }
          }

          // Check if user is productOwner
          if (roles.containsKey('productOwner') && roles['productOwner'] == user.uid) {
            return true;
          }

          // Check if user is in clients array
          if (roles.containsKey('clients') && roles['clients'] is List) {
            if ((roles['clients'] as List).contains(user.uid)) {
              return true;
            }
          }
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
      backgroundColor: Colors.white,
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "Projects"),
      drawer: TeamMemberDrawer(selectedItem: 'Projects'),
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
                  'Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: Color(0xFF004AAD),))
                      : _userProjects.isEmpty
                      ? Center(
                    child: Text(
                      'No projects assigned to you yet.',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  )
                      : ListView.separated(
                    itemCount: _userProjects.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 15),
                    itemBuilder: (context, index) =>
                        _buildProjectCard(_userProjects[index], index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project, int index) {
    Color lineColor =
    (index % 2 == 0) ? const Color(0xFF004AAD) : const Color(0xFF545454);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFFFDFDFD),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                  TeamMemberProjectDetailsScreen(projectId: project['id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: lineColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      project['id'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF004AAD),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  color: Colors.white,
                  iconSize: 20,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                            TeamMemberProjectDetailsScreen(
                              projectId: project['id'],
                            ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}