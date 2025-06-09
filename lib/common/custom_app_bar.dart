import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  // PreferredSizeWidget 구현 필수 (AppBar 높이 지정)
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  final VoidCallback? onMessageTap;
  final VoidCallback? onNotificationTap;

  CustomAppBar({this.onMessageTap, this.onNotificationTap});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(''), // 필요시 제목 넣기
      backgroundColor: Color.fromRGBO(255, 193, 204, 1.0),
      actions: [
        IconButton(
          icon: Icon(Icons.message),
          onPressed: onMessageTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('메시지 아이콘 클릭됨')),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: onNotificationTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('알림 아이콘 클릭됨')),
            );
          },
        ),
      ],
    );
  }
}
