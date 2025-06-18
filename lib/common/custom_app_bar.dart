import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider 필요

import '../main/chat_list_page.dart';
import '../provider/theme_provider.dart';
import '../main/NotificationPage.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  final String? title;
  final VoidCallback? onMessageTap;
  final VoidCallback? onNotificationTap;

  CustomAppBar({
    this.title,
    this.onMessageTap,
    this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;
    final backgroundColor = appBarTheme.backgroundColor ?? Theme.of(context).primaryColor;
    final iconColor = appBarTheme.iconTheme?.color ?? Colors.white;
    final titleTextStyle = appBarTheme.titleTextStyle ??
        TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600);

    // 테마 Provider 읽기
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AppBar(
      title: Text(
        title ?? '',
        style: titleTextStyle,
      ),
      backgroundColor: backgroundColor,
      iconTheme: IconThemeData(color: iconColor),
      actions: [
        IconButton(
          icon: Icon(Icons.message),
          onPressed: onMessageTap ??
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatListPage()),
                );
              },
          color: iconColor,
        ),
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: onNotificationTap ??
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificationPage(userId: '',)), // ← 알림페이지로 이동
                );
              },
          color: iconColor,
        ),
        // IconButton(
        //   icon: Icon(Icons.color_lens_outlined),
        //   tooltip: '색상 테마 변경',
        //   color: iconColor,
        //   onPressed: () {
        //     final current = themeProvider.colorTheme;
        //     ColorTheme newTheme;
        //     if (current == ColorTheme.defaultTheme) {
        //       newTheme = ColorTheme.blueTheme;
        //     } else if (current == ColorTheme.blueTheme) {
        //       newTheme = ColorTheme.blackTheme;
        //     } else {
        //       newTheme = ColorTheme.defaultTheme;
        //     }
        //     themeProvider.setColorTheme(newTheme);
        //   },
        // ),
      ],
    );
  }
}
