// File: lib/widgets/team_member_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/AuthService.dart';
import '../services/Navigation_service.dart';
import 'drawer_header.dart';

class TeamMemberDrawer extends StatelessWidget {
  final String selectedItem;
  final Function(String)? onItemSelected; // Make this optional

  const TeamMemberDrawer(
      {Key? key, required this.selectedItem, this.onItemSelected})
      : super(key: key);
  static const Color primaryColor = Color(0xFF004AAD);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFDFDFD),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const CustomDrawerHeader(
            name: '',
            email: '',
          ),
          _buildDrawerItem(context, 'Home', Icons.home,
              isSelected: selectedItem == 'Home'),
          _buildDrawerItem(context, 'My Profile', Icons.person,
              isSelected: selectedItem == 'My Profile'),
          _buildDrawerItem(context, 'My To-Do', Icons.task,
              isSelected: selectedItem == 'My To-Do'),
          _buildDrawerItem(context, 'Time Scheduling', Icons.access_time_filled,
              isSelected: selectedItem == 'Time Scheduling'),
          Divider(),
          _buildDrawerItem(context, 'Projects', Icons.assignment,
              isSelected: selectedItem == 'Projects'),
          _buildDrawerItem(context, 'Assigned Tasks', Icons.note_alt_rounded,
              isSelected: selectedItem == 'Assigned Tasks'),
          _buildDrawerItem(context, 'My Workload', Icons.work_history_rounded,
              isSelected: selectedItem == 'My Workload'),
          _buildDrawerItem(context, 'Retrospective', Icons.feedback,
              isSelected: selectedItem == 'Retrospective'),
          Divider(),
          _buildDrawerItem(context, 'Settings', Icons.settings,
              isSelected: selectedItem == 'Settings'),
          _buildDrawerItem(context, 'Log Out', Icons.logout, isLogout: true),
          // Removed the duplicate items that were appearing in the drawer
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      String title,
      IconData icon, {
        bool isSelected = false,
        bool isLogout = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color:
        isLogout
            ? Colors.red
            : isSelected
            ? const Color(0xFF004AAD)
            : const Color(0xFF313131),
      ),
      title: Text(
        title,
        style: TextStyle(
          color:
          isLogout
              ? Colors.red
              : isSelected
              ? const Color(0xFF004AAD)
              : const Color(0xFF313131),
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins-SemiBold',
          fontSize: 15,
        ),
      ),
      onTap: () async {
        Navigator.pop(context); // Close drawer first

        if (isLogout) {
          // Show logout confirmation dialog
          _showLogoutConfirmationDialog(context);
        } else {
          // If custom callback is provided, use it, otherwise use the central navigation service
          if (onItemSelected != null) {
            onItemSelected!(title);
          } else {
            // Use the centralized navigation service
            NavigationService().onTeamMemberDrawerItemSelected(context, title);
          }
        }
      },
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFF5F5F5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red,
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  color: Color(0xFF313131),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF666666),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF666666),
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog

                // Log out user using AuthService
                try {
                  final authService = Provider.of<AuthService>(
                      context, listen: false);
                  await authService.signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/', (route) => false);
                } catch (e) {
                  print("Error during logout: $e");
                  // Show error message if logout fails
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed. Please try again.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:Color(0xFF004AAD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
}