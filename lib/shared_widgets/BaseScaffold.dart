import 'package:flutter/material.dart';
import 'package:task_orbit/shared_widgets/bottom_nav.dart';
import 'package:task_orbit/shared_widgets/app_bars.dart';
import 'package:task_orbit/shared_widgets/CustomeDrawer.dart';

class BaseScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final bool showAppBar;
  final bool showDrawer;
  final bool showBottomNav;

  const BaseScaffold({
    super.key,
    required this.body,
    this.title = '',
    this.showAppBar = true,
    this.showDrawer = true,
    this.showBottomNav = true,
  });

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentBottomNavIndex = 0;

  void _onBottomNavTapped(int index) {
    if (index == _currentBottomNavIndex) return;

    setState(() => _currentBottomNavIndex = index);

    switch (index) {
      case 0:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/productOwnerHome',
              (route) => false,
        );
        break;
      case 1:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/myProjects',
              (route) => false,
        );
        break;
      case 2:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/settings',
              (route) => false,
        );
        break;
      case 3:
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/profile',
              (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: widget.showAppBar
          ? ProjectAppBar(scaffoldKey: _scaffoldKey)
          : null,
      drawer: widget.showDrawer
          ? const CustomDrawer()
          : null,
      body: SafeArea(child: widget.body),
      bottomNavigationBar: widget.showBottomNav
          ? ProjectBottomNav(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
      )
          : null,
    );
  }
}