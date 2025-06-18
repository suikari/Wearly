import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_room_page.dart';

class ChatListPage extends StatefulWidget {
  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  String searchText = '';
  String get myEmail => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        title: const Text('채팅 리스트', style: TextStyle(color: Colors.black)),
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
                hintText: "유저 이름/이메일 검색...",
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
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .where('emails', arrayContains: myEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                List<QueryDocumentSnapshot> rooms = snapshot.data!.docs;

                // lastMessageTime 기준 내림차순 정렬 (필드가 없으면 맨 뒤로)
                rooms.sort((a, b) {
                  final at = (a.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
                  final bt = (b.data() as Map<String, dynamic>)['lastMessageTime'] as Timestamp?;
                  if (at == null && bt == null) return 0;
                  if (at == null) return 1;
                  if (bt == null) return -1;
                  return bt.toDate().compareTo(at.toDate());
                });

                if (rooms.isEmpty) {
                  return const Center(child: Text("채팅방이 없습니다."));
                }

                return ListView.separated(
                  itemCount: rooms.length,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(),
                  ),
                  itemBuilder: (context, idx) {
                    final data = rooms[idx].data() as Map<String, dynamic>;
                    final emailsRaw = data['emails'];
                    final List<dynamic> emails = (emailsRaw is List) ? emailsRaw : [];
                    final targetEmail = emails.firstWhere((e) => e != myEmail, orElse: () => '');

                    // 마지막 메시지
                    final lastMessage = data['lastMessage'] ?? '';
                    final lastMessageTime = data['lastMessageTime'] as Timestamp?;
                    final unreadCount = data['unreadCount_$myEmail'] ?? 0;

                    // 시간 포맷팅
                    String timeText = '';
                    if (lastMessageTime != null) {
                      final dt = lastMessageTime.toDate();
                      final now = DateTime.now();
                      if (now.difference(dt).inDays == 0) {
                        timeText = DateFormat('a h:mm', 'ko').format(dt);
                      } else {
                        timeText = DateFormat('MM/dd').format(dt);
                      }
                    }

                    // --- 상대방 정보 쿼리 방식 (이메일로 가져오기) ---
                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: targetEmail)
                          .limit(1)
                          .get(),
                      builder: (context, userSnap) {
                        String nickname = '';
                        String profileUrl = 'assets/profile1.jpg';
                        if (userSnap.hasData && userSnap.data!.docs.isNotEmpty) {
                          final userData = userSnap.data!.docs.first.data() as Map<String, dynamic>;
                          nickname = userData['nickname'] ?? '닉네임없음';
                          profileUrl = userData['profileImage'] ?? 'assets/profile1.jpg';
                        }

                        // 검색 필터 (상대방)
                        if (searchText.isNotEmpty &&
                            !nickname.toLowerCase().contains(searchText.toLowerCase()) &&
                            !targetEmail.toLowerCase().contains(searchText.toLowerCase())) {
                          return SizedBox.shrink();
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: CircleAvatar(
                            backgroundImage: profileUrl.toString().startsWith('http')
                                ? NetworkImage(profileUrl)
                                : AssetImage(profileUrl) as ImageProvider,
                            radius: 22,
                          ),
                          title: Text(
                            nickname,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeText,
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                              if (unreadCount > 0)
                                Container(
                                  margin: EdgeInsets.only(top: 6),
                                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    '$unreadCount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomPage(
                                  roomId: rooms[idx].id,
                                  userEmail: targetEmail,
                                  userName: nickname,
                                  profileUrl: profileUrl,
                                ),
                              ),
                            );
                          },
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


// 점선 위젯 등은 동일하게 사용

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
