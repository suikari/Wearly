import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'chat_room_page.dart';

// 팔로우 알림 전송 함수
Future<void> sendFollowNotification({
  required String fromUid,
  required String fromNickname,
  required String fromProfileImg,
  required String toUid,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'uid': toUid,
    'type': 'follow',
    'fromUid': fromUid,
    'fromNickname': fromNickname,
    'fromProfileImg': fromProfileImg,
    'content': '회원님을 팔로우 합니다.',
    'createdAt': FieldValue.serverTimestamp(),
    'isRead': false,
  });
}

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
        backgroundColor: Colors.white,
        title: const Text('채팅 리스트', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: Column(
        children: [
          buildRecommendedUsersBar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey[100],
            child: TextField(
              decoration: InputDecoration(
                hintText: "유저 닉네임/ID 검색...",
                prefixIcon: Icon(Icons.search, color: Colors.blueGrey),
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
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .where('uids', arrayContains: myUid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                List<QueryDocumentSnapshot> rooms = snapshot.data!.docs;

                // 최근 메시지순 정렬
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

                    // unreadCount_<내UID> 필드로 표시
                    final unreadCount = data['unreadCount_$myUid'] ?? 0;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(targetUid)
                          .get(),
                      builder: (context, userSnap) {
                        String nickname = '';
                        String profileUrl = '';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>;
                          nickname = userData['nickname'] ?? '닉네임없음';
                          profileUrl = userData['profileImage'] ?? '';
                        }

                        if (searchText.isNotEmpty &&
                            !nickname.toLowerCase().contains(searchText.toLowerCase()) &&
                            !targetUid.toLowerCase().contains(searchText.toLowerCase())) {
                          return SizedBox.shrink();
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          leading: buildProfileAvatar(profileUrl, 22),
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
                              if (unreadCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  margin: const EdgeInsets.only(bottom: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.redAccent.withOpacity(0.15),
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
                              Text(
                                timeText,
                                style: const TextStyle(fontSize: 13, color: Colors.grey),
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

  /// 추천 팔로우(스토리 스타일) 바
  Widget buildRecommendedUsersBar() {
    return SizedBox(
      height: 90,
      child: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(myUid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return SizedBox.shrink();
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final following = userData['following'] is List ? userData['following'] as List : [];
          final myUid_ = myUid;

          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('users').get(),
            builder: (context, userSnap) {
              if (!userSnap.hasData) return SizedBox.shrink();
              List<QueryDocumentSnapshot> docs = userSnap.data!.docs;

              docs.removeWhere((doc) => doc.id == myUid_);
              docs.shuffle();

              List<QueryDocumentSnapshot> followingDocs = [];
              List<QueryDocumentSnapshot> recommendDocs = [];
              for (var doc in docs) {
                if (following.contains(doc.id)) {
                  followingDocs.add(doc);
                } else {
                  recommendDocs.add(doc);
                }
              }

              final List<QueryDocumentSnapshot> finalDocs = [
                ...followingDocs,
                ...recommendDocs.take(8 - followingDocs.length)
              ];

              if (finalDocs.isEmpty) {
                return SizedBox.shrink();
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                itemCount: finalDocs.length,
                separatorBuilder: (_, __) => SizedBox(width: 12),
                itemBuilder: (context, idx) {
                  final doc = finalDocs[idx];
                  final user = doc.data() as Map<String, dynamic>;
                  final uid = doc.id;
                  final profileUrl = user['profileImage'] ?? '';
                  final nickname = user['nickname'] ?? '닉네임없음';
                  final isFollowing = following.contains(uid);

                  return GestureDetector(
                    onTap: isFollowing
                        ? () => openChatRoomWith(uid, nickname, profileUrl)
                        : null,
                    child: Column(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            buildProfileAvatar(profileUrl, 26),
                            if (!isFollowing)
                              Positioned(
                                bottom: -4, right: -4,
                                child: GestureDetector(
                                  onTap: () => followUser(uid),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(Icons.person_add, color: Colors.white, size: 17),
                                  ),
                                ),
                              ),
                            if (isFollowing)
                              Positioned(
                                bottom: -8, right: -6,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[200],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white, width: 1),
                                  ),
                                  child: Text(
                                    "팔로잉",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 4),
                        SizedBox(
                          width: 54,
                          child: Text(
                            nickname,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// 프로필 이미지를 안전하게 그려주는 함수
  Widget buildProfileAvatar(String? url, double radius) {
    if (url == null || url.trim().isEmpty || url == 'null') {
      return CircleAvatar(
        backgroundColor: Colors.grey,
        radius: radius,
        child: Icon(Icons.person, color: Colors.white, size: radius),
      );
    } else if (url.startsWith('http')) {
      return CircleAvatar(
        backgroundImage: NetworkImage(url),
        backgroundColor: Colors.grey[200],
        radius: radius,
      );
    } else {
      // asset 경로인데 없을 수 있으니 그냥 빈 원형만
      return CircleAvatar(
        backgroundColor: Colors.grey,
        radius: radius,
        child: Icon(Icons.person, color: Colors.white, size: radius),
      );
    }
  }

  /// 팔로우 함수 + 알림
  void followUser(String targetUid) async {
    if (targetUid == myUid) return;

    final userRef = FirebaseFirestore.instance.collection('users').doc(myUid);
    final targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);

    await FirebaseFirestore.instance.runTransaction((txn) async {
      final mySnap = await txn.get(userRef);
      final targetSnap = await txn.get(targetRef);

      List<dynamic> following;
      if (mySnap.exists && mySnap.data() != null && mySnap.data()!.containsKey('following') && mySnap['following'] is List) {
        following = List.from(mySnap['following']);
      } else {
        following = [];
      }

      List<dynamic> followers;
      if (targetSnap.exists && targetSnap.data() != null && targetSnap.data()!.containsKey('follower') && targetSnap['follower'] is List) {
        followers = List.from(targetSnap['follower']);
      } else {
        followers = [];
      }

      if (!following.contains(targetUid)) following.add(targetUid);
      if (!followers.contains(myUid)) followers.add(myUid);

      txn.update(userRef, {'following': following});
      txn.update(targetRef, {'follower': followers});
    }).catchError((e) {});

    // 팔로우 알림 전송
    final mySnap = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
    final myData = mySnap.data() as Map<String, dynamic>? ?? {};
    final fromNickname = myData['nickname'] ?? '';
    final fromProfileImg = myData['profileImage'] ?? '';

    await sendFollowNotification(
      fromUid: myUid,
      fromNickname: fromNickname,
      fromProfileImg: fromProfileImg,
      toUid: targetUid,
    );

    setState(() {});
  }

  /// 채팅방 생성/이동 함수
  void openChatRoomWith(String targetUid, String nickname, String profileUrl) async {
    String myUid_ = myUid;
    QuerySnapshot chatRoomSnap = await FirebaseFirestore.instance
        .collection('chatRooms')
        .where('uids', arrayContains: myUid_)
        .get();

    DocumentSnapshot? foundRoom;
    for (var doc in chatRoomSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if ((data['uids'] as List).contains(targetUid)) {
        foundRoom = doc;
        break;
      }
    }

    String roomId;
    if (foundRoom != null) {
      roomId = foundRoom.id;
    } else {
      final newRoom = await FirebaseFirestore.instance.collection('chatRooms').add({
        'uids': [myUid_, targetUid],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount_$myUid': 0,
        'unreadCount_$targetUid': 0,
      });
      roomId = newRoom.id;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          roomId: roomId,
          targetUid: targetUid,
          userName: nickname,
          profileUrl: profileUrl,
        ),
      ),
    );
  }
}
