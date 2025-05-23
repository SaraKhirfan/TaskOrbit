// custom_drawer.dart
import 'package:flutter/material.dart';
import 'package:task_orbit/widgets/drawer_header.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFDFDFD),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const CustomDrawerHeader(
            name: 'Sara Khirfan',
            email: 'sara.khirfan@outlook.com',
          ),
          _buildDrawerItem(context, Icons.person, 'My Profile', '/profile'),
          _buildDrawerItem(context, Icons.task, 'My Tasks', '/tasks'),
          _buildDrawerItem(context, Icons.assignment, 'My Projects', '/myProjects'),
          _buildDrawerItem(context, Icons.group_add, 'Add Members', '/addMembers'),
          _buildDrawerItem(context, Icons.schedule, 'Time Scheduling', '/scheduling'),
          _buildDrawerItem(context, Icons.history, 'Activity Logs', '/activityLogs'),
          _buildDrawerItem(context, Icons.settings, 'Settings', '/settings'),
          _buildDrawerItem(context, Icons.logout, 'Log Out', '/', isLogout: true),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context,
      IconData icon,
      String title,
      String routeName, {
        bool isLogout = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : const Color(0xFF004AAD),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : const Color(0xFF313131),
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins-SemiBold',
          fontSize: 15,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        if (isLogout) {
          Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
        } else {
          Navigator.pushNamed(context, routeName);
        }
      },
    );
  }
}