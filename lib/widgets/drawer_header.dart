// File: lib/widgets/drawer_header.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/AuthService.dart';

class CustomDrawerHeader extends StatefulWidget {
  final String name;
  final String email;

  const CustomDrawerHeader({
    super.key,
    required this.name,
    required this.email,
  });

  @override
  State<CustomDrawerHeader> createState() => _CustomDrawerHeaderState();
}

class _CustomDrawerHeaderState extends State<CustomDrawerHeader> {
  String _displayName = '';
  String _displayEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Use the method directly from your service
      final userData = await authService.getUserProfile();

      if (userData != null && mounted) {
        setState(() {
          _displayName = userData['name'] ?? widget.name;
          _displayEmail = userData['email'] ?? widget.email;
          _isLoading = false;
        });
      } else {
        setState(() {
          _displayName = widget.name;
          _displayEmail = widget.email;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _displayName = widget.name;
          _displayEmail = widget.email;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF004AAD)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/images/user_avatar.png'),
          ),
          const SizedBox(height: 10),
          Text(
            _isLoading ? widget.name : _displayName,
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _isLoading ? widget.email : _displayEmail,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}