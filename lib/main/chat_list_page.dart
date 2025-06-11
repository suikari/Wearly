import 'package:flutter/material.dart';

import '../common/custom_app_bar.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatelessWidget {
  final List<ChatItem> chatItems = [
    ChatItem("김하나", "안녕하세요", "25.06.09", "assets/images/user1.jpg"),
    ChatItem("이두나", "안녕하세요", "25.05.22", "assets/images/user2.jpg"),
    ChatItem("서세나", "안녕하세요", "25.05.22", "assets/images/user3.jpg"),
    ChatItem("윤사나", "안녕하세요", "25.05.22", "assets/images/user4.jpg"),
    ChatItem("차오나", "안녕하세요", "25.05.22", "assets/images/user5.jpg"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:  CustomAppBar(title: '다이렉트 메세지'),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: chatItems.length,
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: DottedLine(),
        ),
        itemBuilder: (context, index) {
          final chat = chatItems[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: AssetImage(chat.imagePath),
              radius: 25,
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(chat.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(chat.date,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
            subtitle: Text(chat.message),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    userName: chat.name,
                    imagePath: chat.imagePath,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatItem {
  final String name;
  final String message;
  final String date;
  final String imagePath;

  ChatItem(this.name, this.message, this.date, this.imagePath);
}

/// 점선 구분선 컴포넌트
class DottedLine extends StatelessWidget {
  const DottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.redAccent),
              ),
            );
          }),
        );
      },
    );
  }
}
