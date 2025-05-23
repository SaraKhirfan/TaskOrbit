// File: lib/widgets/sm_app_bar.dart
import 'package:flutter/material.dart';

class SMAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final String? title;

  const SMAppBar({Key? key, required this.scaffoldKey, this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFDFDFD),
      foregroundColor: const Color(0xFFFDFDFD),
      automaticallyImplyLeading: false,
      title:
      title != null
          ? Text(
        title!,
        style: const TextStyle(
          color: Color(0xFF313131),
          fontWeight: FontWeight.bold,
        ),
      )
          : null,
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
