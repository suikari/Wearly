import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String searchText = '';

  // 실제 로그인된 내 userId로 바꿔줘!
  final String myUserId = '내_유저ID';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        title: const Text('다이렉트 메세지', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- 검색창 ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.pink[50],
            child: TextField(
              decoration: InputDecoration(
                hintText: "검색어를 입력하세요....",
                prefixIcon: Icon(Icons.search, color: Colors.pink[300]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              ),
              onChanged: (v) => setState(() => searchText = v),
            ),
          ),
          // --- 채팅방 리스트 ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chatRooms').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                List<QueryDocumentSnapshot> rooms = snapshot.data!.docs;

                // 검색 필터
                if (searchText.isNotEmpty) {
                  rooms = rooms.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['targetName'] ?? data['creatorId'] ?? '';
                    return name.toLowerCase().contains(searchText.toLowerCase());
                  }).toList();
                }

                if (rooms.isEmpty) {
                  return const Center(child: Text("채팅방이 없습니다."));
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: DottedLine(),
                  ),
                  itemBuilder: (context, idx) {
                    final data = rooms[idx].data() as Map<String, dynamic>;
                    final roomId = rooms[idx].id;
                    final name = data['targetName'] ?? data['creatorId'] ?? '이름없음'; // Firestore에 따라 수정
                    final profileUrl = data['profileImg'] ?? 'assets/profile1.jpg';

                    // 마지막 메시지 정보
                    final lastMsg = data['lastMessage'] ?? '';
                    final lastSenderId = data['lastMessageSenderId'] ?? '';
                    final lastMsgTime = data['lastMessageTime'] ?? '';
                    final lastSenderName = lastSenderId == myUserId
                        ? '나'
                        : (data['targetName'] ?? '상대');

                    final unread = data['unreadCount'] ?? 0;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: profileUrl.startsWith('http')
                            ? NetworkImage(profileUrl)
                            : AssetImage(profileUrl) as ImageProvider,
                        radius: 24,
                      ),
                      title: Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '$lastSenderName: $lastMsg',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            lastMsgTime,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (unread > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              roomId: roomId,
                              userName: name,
                              profileUrl: profileUrl,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- 점선 구분선 위젯 ---
class DottedLine extends StatelessWidget {
  const DottedLine({Key? key}) : super(key: key);

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
                decoration: BoxDecoration(color: Colors.pinkAccent),
              ),
            );
          }),
        );
      },
    );
  }
}
