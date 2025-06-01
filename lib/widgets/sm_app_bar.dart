// File: lib/widgets/sm_app_bar.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ChatService.dart';

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
        Consumer<ChatService>(
          builder: (context, chatService, child) {
            return StreamBuilder<int>(
              stream: chatService.getUnreadMessageCount(),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat),
                      color: Color(0xFF004AAD),
                      onPressed: () {
                        Navigator.pushNamed(context, '/SMChatlist');
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications),
          color: Color(0xFF004AAD),
          onPressed: () {},
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
