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
  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

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
          // 검색창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.pink[50],
            child: TextField(
              decoration: InputDecoration(
                hintText: "유저 닉네임/UID 검색...",
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
          // 채팅방 리스트
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .where('uids', arrayContains: myUid) // emails → uids
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                List<QueryDocumentSnapshot> rooms = snapshot.data!.docs;

                // lastMessageTime 기준 내림차순 정렬
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
                    final uidsRaw = data['uids'];
                    final List<dynamic> uids = (uidsRaw is List) ? uidsRaw : [];
                    final targetUid = uids.firstWhere((e) => e != myUid, orElse: () => '');

                    final lastMessage = data['lastMessage'] ?? '';
                    final lastMessageTime = data['lastMessageTime'] as Timestamp?;
                    final unreadCount = data['unreadCount_$myUid'] ?? 0;

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

                    // --- 상대방 정보 쿼리 (uid로) ---
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(targetUid)
                          .get(),
                      builder: (context, userSnap) {
                        String nickname = '';
                        String profileUrl = 'assets/profile1.jpg';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>;
                          nickname = userData['nickname'] ?? '닉네임없음';
                          profileUrl = userData['profileImage'] ?? 'assets/profile1.jpg';
                        }

                        // 검색 필터
                        if (searchText.isNotEmpty &&
                            !nickname.toLowerCase().contains(searchText.toLowerCase()) &&
                            !targetUid.toLowerCase().contains(searchText.toLowerCase())) {
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                timeText,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
                              ),
                              const SizedBox(height: 6),
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  margin: const EdgeInsets.only(top: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.2),
                                        blurRadius: 2,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                  child: Text(
                                    unreadCount > 99 ? '99+' : '$unreadCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                                  targetUid: targetUid,
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
