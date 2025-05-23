// File: lib/widgets/sm_bottom_nav.dart
import 'package:flutter/material.dart';

class SMBottomNav extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  const SMBottomNav({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFFFDFDFD),
      currentIndex: selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFF004AAD),
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: const TextStyle(
        color: Color(0xFF004AAD),
        fontSize: 12,
        fontFamily: 'Poppins-SemiBold',
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontFamily: 'Poppins-SemiBold',
        fontWeight: FontWeight.bold,
      ),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Projects'),
        BottomNavigationBarItem(icon: Icon(Icons.access_time_filled_rounded), label: 'Scheduling'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: onItemTapped,
    );
  }
}