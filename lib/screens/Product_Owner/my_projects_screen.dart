import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_orbit/screens/Product_Owner/AddNewProject.dart';
import 'package:task_orbit/screens/Product_Owner/project_details_screen.dart';
import '../../services/project_service.dart';
import '../../services/AuthService.dart';
import '../../widgets/product_owner_drawer.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  static const Color primaryColor = Color(0xFF004AAD);
  static const Color backgroundColor = Color(0xFFF5F5F5);

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  int _selectedIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshProjects();
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userData = await authService.getUserProfile();

    if (userData != null && mounted) {
      setState(() {
        _userName = userData['name'] ?? 'User';
        _userEmail = userData['email'] ?? '';
      });
    }
  }

  // Refresh projects from Firebase
  Future<void> _refreshProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<ProjectService>(context, listen: false).refreshProjects();
    } catch (e) {
      // Handle error silently
      print('Error refreshing projects: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Handle logout with Firebase
  Future<void> _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  @override
  Widget build(BuildContext context) {
    // Get projects from the service
    final projectService = Provider.of<ProjectService>(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFDFD),
        foregroundColor: const Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: MyProjectsScreen.primaryColor,
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
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Projects'),
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
                  'My Projects',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshProjects,
                    child: projectService.projects.isEmpty
                        ? Center(
                      child: Text(
                        'No projects found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                        : ListView.separated(
                      itemCount: projectService.projects.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 15),
                      itemBuilder: (context, index) => _buildProjectCard(projectService.projects[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProjectScreen(
                onProjectAdded: (newProject) {
                  context.read<ProjectService>().addProject(newProject);
                  _refreshProjects(); // Refresh after adding
                },
              ),
            ),
          );
        },
        backgroundColor: MyProjectsScreen.primaryColor,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    // Get the projects list from the service
    final projects = context.read<ProjectService>().projects;

    // Find the index in the service's projects list
    int index = projects.indexOf(project);
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
              builder: (context) => ProjectDetailsScreen(projectId: project['id']),
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
                      project['name'] ?? project['title'] ?? 'Untitled Project',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      project['id'] ?? '',
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
                        builder: (context) => ProjectDetailsScreen(projectId: project['id']),
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

  Widget _buildBottomNavBar() {
    return Container(
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
    );
  }
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = index == _selectedIndex;
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF004AAD) : Colors.grey,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF004AAD) : Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}