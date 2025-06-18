import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationPage extends StatelessWidget {
  final String userId; // 현재 로그인 유저 ID

  const NotificationPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('알림')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('알림이 없습니다.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.pink[100]),
            itemBuilder: (context, idx) {
              final noti = docs[idx].data() as Map<String, dynamic>;
              final type = noti['type'];
              final fromProfileImg = noti['fromProfileImg'];
              final fromNickname = noti['fromNickname'] ?? '알 수 없음';
              final content = noti['content'] ?? '';
              final date = (noti['createdAt'] as Timestamp?)?.toDate();
              final dateStr = date != null
                  ? '${date.year.toString().substring(2)}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}'
                  : '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 24,
                  backgroundImage: fromProfileImg == null
                      ? AssetImage('assets/default_profile.png')
                      : (fromProfileImg.startsWith('http')
                      ? NetworkImage(fromProfileImg)
                      : AssetImage(fromProfileImg)) as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                ),
                title: Text(fromNickname, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(content, style: TextStyle(color: Colors.grey[700])),
                trailing: Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey)),
                onTap: () {
                  // postId/commentId 등으로 해당 게시글 or DM 이동
                  // 예시: Navigator.push(...);
                },
              );
            },
          );
        },
      ),
    );
  }
}
