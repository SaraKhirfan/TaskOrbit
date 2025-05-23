import 'package:flutter/material.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import 'package:task_orbit/widgets/drawer_header.dart';

import '../../widgets/product_owner_drawer.dart';

class TeamPerformanceScreen extends StatefulWidget {
  const TeamPerformanceScreen({super.key});

  @override
  State<TeamPerformanceScreen> createState() => _TeamPerformanceScreenState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _TeamPerformanceScreenState extends State<TeamPerformanceScreen> {
  int _selectedIndex = 1; // To highlight the "Projects" tab

  // Sample team member data
  final List<Map<String, dynamic>> teamMembers = [
    {'name': 'Adam Hynn', 'tasksCompleted': '8/10', 'workload': 'High'},
    {'name': 'Abbey Boris', 'tasksCompleted': '5/10', 'workload': 'Low'},
    {'name': 'Benson Coleman', 'tasksCompleted': '10/10', 'workload': 'Low'},
    {'name': 'Bobby Kim', 'tasksCompleted': '4/10', 'workload': 'High'},
  ];
  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFDFDFD),
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
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            color: MyProjectsScreen.primaryColor,
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'My Projects'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF004AAD)),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Team Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // DataTable
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 40,
                columns: const [
                  DataColumn(label: Text('Team Member')),
                  DataColumn(label: Text('Tasks Completed')),
                  DataColumn(label: Text('Workload level')),
                ],
                rows:
                teamMembers.map((member) {
                  return DataRow(
                    cells: [
                      DataCell(Text(member['name'])),
                      DataCell(Text(member['tasksCompleted'])),
                      DataCell(
                        Text(member['workload']),
                        // Add color based on workload
                        onTap: () {
                          // Handle cell tap if needed
                        },
                      ),
                    ],
                  );
                }).toList(),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),

            // View Roadblocks button
            const SizedBox(height: 24),
            _buildNavigationButton(
              'View Roadblocks',
                  () => Navigator.pushNamed(
                context,
                '/roadblocks',
                //arguments: widget.project,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      bottomNavigationBar: _buildBottomNavBar(),
    );
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
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects',),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

Widget _buildNavigationButton(String text, VoidCallback onPressed) {
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    color: Color(0xFF004AAD),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    ),
  );
}
