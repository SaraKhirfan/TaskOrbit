// project_app_bar.dart
import 'package:flutter/material.dart';

class ProjectAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ProjectAppBar({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFDFDFD),
      foregroundColor: const Color(0xFFFDFDFD),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.menu),
          color: const Color(0xFF004AAD),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chat),
          color: const Color(0xFF004AAD),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          color: const Color(0xFF004AAD),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}