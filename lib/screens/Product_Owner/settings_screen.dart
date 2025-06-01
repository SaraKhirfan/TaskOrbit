// File: lib/screens/Product_Owner/settings_screen.dart

import 'package:flutter/material.dart';
import '../../widgets/drawer_header.dart';
import '../../widgets/product_owner_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/productOwnerHome');
    if (index == 1) Navigator.pushNamed(context, '/myProjects');
    if (index == 2) Navigator.pushNamed(context, '/timeScheduling');
    if (index == 3) Navigator.pushNamed(context, '/MyProfile');
  }

  // Settings state variables
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _taskReminders = true;
  bool _meetingReminders = true;
  bool _darkMode = false;
  double _fontSize =
  1.0; // 1.0 is normal, below 1 is smaller, above 1 is larger


  @override
  void initState() {
    super.initState();
  }


  Future<void> _showConfirmDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFFFDFDFD),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Confirm',
                style: TextStyle(color: Color(0xFF004AAD)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Operation completed successfully'),
                    backgroundColor: Color(0xFF004AAD),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
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

  Widget _buildSettingSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF313131),
            ),
          ),
        ),
        Card(
          color: Color(0xFFFDFDFD),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchSetting(
      String title,
      String subtitle,
      bool value,
      Function(bool) onChanged,
      ) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF313131)),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Color(0xFF666666), fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF004AAD),
      ),
    );
  }

  Widget _buildActionSetting(
      String title,
      String subtitle,
      IconData icon,
      Function() onTap,
      ) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF004AAD)),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF313131)),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Color(0xFF666666), fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Color(0xFF004AAD)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFDFD),
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Color(0xFFFDFDFD),
        foregroundColor: Color(0xFFFDFDFD),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: Color(0xFF004AAD),
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
            color: Color(0xFF004AAD),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProductOwnerDrawer(selectedItem: 'Settings'),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button and title
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Settings',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                ],
              ),
            ),

            // Notifications Section
            _buildSettingSection('Notifications', [
              _buildSwitchSetting(
                'Push Notifications',
                'Receive push notifications on this device',
                _pushNotifications,
                    (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),
            ]),
            // Account Section
            _buildSettingSection('Account', [
              _buildActionSetting(
                'Delete Account',
                'Permanently delete your account and data',
                Icons.delete_forever,
                    () {
                  // Show delete account confirmation
                  _showConfirmDialog(
                    'Delete Account',
                    'Are you sure you want to delete your account? This action cannot be undone.',
                  );
                },
              ),
              _buildActionSetting(
                'Change Password',
                'Update your account password',
                Icons.lock,
                    () {
                  Navigator.pushReplacementNamed(context, '/MyProfile');
                },
              ),
            ]),

            // About Section
            _buildSettingSection('About', [
              _buildActionSetting(
                'Help & Support',
                'Get help or contact support',
                Icons.help,
                    () {
                  // Show help and support options
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        backgroundColor: Color(0xFFFDFDFD),
                        title: Text(
                          'Help & Support',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF313131),
                          ),
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.email,
                                color: Color(0xFF004AAD),
                              ),
                              title: Text('Email Support'),
                              subtitle: Text('support@taskorbit.com'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening email client...'),
                                    backgroundColor: Color(0xFF004AAD),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.chat,
                                color: Color(0xFF004AAD),
                              ),
                              title: Text('Live Chat'),
                              subtitle: Text('Chat with our support team'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening live chat...'),
                                    backgroundColor: Color(0xFF004AAD),
                                  ),
                                );
                              },
                            ),
                            ListTile(
                              leading: Icon(
                                Icons.help_center,
                                color: Color(0xFF004AAD),
                              ),
                              title: Text('FAQ'),
                              subtitle: Text('Frequently asked questions'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Opening FAQ section...'),
                                    backgroundColor: Color(0xFF004AAD),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Close',
                              style: TextStyle(color: Color(0xFF004AAD)),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ]),

            // Add some padding at the bottom
            SizedBox(height: 20),
          ],
        ),
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
            _buildNavItem(Icons.access_time_filled_rounded , "Schedule", 2),
            _buildNavItem(Icons.person, "Profile", 3),
          ],
        ),
      ),
      );
  }
}





