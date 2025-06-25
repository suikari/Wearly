import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main/chat_room_page.dart';
import '../main/mypage_tab.dart';

// uid → 닉네임/프로필 캐싱
final Map<String, Map<String, dynamic>> userCache = {};

class NotificationPage extends StatefulWidget {
  final String uid;
  const NotificationPage({Key? key, required this.uid}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final int pageSize = 10;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> notificationDocs = [];
  bool isLoading = false;
  bool hasMore = true;
  DocumentSnapshot? lastDoc;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !isLoading &&
        hasMore &&
        notificationDocs.length >= pageSize) {
      fetchNotifications();
    }
  }

  Future<void> fetchNotifications() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('createdAt', descending: true)
        .limit(pageSize);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc!);
    }

    final snap = await query.get();

    if (mounted) {
      setState(() {
        if (snap.docs.isNotEmpty) {
          notificationDocs.addAll(snap.docs);
          lastDoc = snap.docs.last;
        }
        if (snap.docs.length < pageSize) hasMore = false;
        isLoading = false;
      });
    }
  }

  Future<void> markAllAsRead() async {
    final unread = notificationDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['isRead'] != true;
    }).toList();

    if (unread.isEmpty) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in unread) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    setState(() {
      for (var doc in unread) {
        (doc.data() as Map<String, dynamic>)['isRead'] = true;
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String typeLabel(String? type) {
    switch (type) {
      case 'dm':
        return '[DM] ';
      case 'comment':
        return '[댓글] ';
      case 'like':
        return '[좋아요] ';
      case 'follow':
        return '[팔로우] ';
      default:
        return '';
    }
  }

  Future<Map<String, dynamic>> fetchUserInfo(String uid) async {
    if (userCache.containsKey(uid)) return userCache[uid]!;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    String nickname = '알 수 없음';
    String profileImg = '';
    if (doc.exists) {
      final data = doc.data();
      nickname = data?['nickname'] ?? nickname;
      profileImg = data?['profileImg'] ?? '';
    }
    userCache[uid] = {'nickname': nickname, 'profileImg': profileImg};
    return userCache[uid]!;
  }

  Widget buildItem(BuildContext context, int idx) {
    if (idx >= notificationDocs.length) {
      if (isLoading && hasMore) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: CircularProgressIndicator(),
          ),
        );
      }
      return SizedBox.shrink();
    }

    final doc = notificationDocs[idx];
    final noti = doc.data() as Map<String, dynamic>;
    final fromUid = noti['fromUid'];
    final content = noti['content'] ?? '';
    final date = (noti['createdAt'] as Timestamp?)?.toDate();
    final dateStr = date != null
        ? '${date.year.toString().substring(2)}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}'
        : '';
    final isRead = noti['isRead'] ?? false;

    return FutureBuilder<Map<String, dynamic>>(
      future: fetchUserInfo(fromUid),
      builder: (context, snapshot) {
        final nickname = snapshot.data?['nickname'] ?? '알 수 없음';
        final profileImg = snapshot.data?['profileImg'] ?? '';

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 24,
            backgroundImage: profileImg.isEmpty
                ? AssetImage('assets/default_profile.jpg')
                : (profileImg.startsWith('http')
                ? NetworkImage(profileImg)
                : AssetImage(profileImg)) as ImageProvider,
            onBackgroundImageError: (_, __) {},
          ),
          title: Text(
            '${typeLabel(noti['type'])}$nickname',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isRead ? Colors.grey : Colors.black,
            ),
          ),
          subtitle: Text(
            content,
            style: TextStyle(color: isRead ? Colors.grey : Colors.black),
          ),
          trailing: Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey)),
          tileColor: isRead ? Colors.grey[100] : Colors.white,
          onTap: () async {
            // 알림을 읽음 처리
            await FirebaseFirestore.instance
                .collection('notifications')
                .doc(doc.id)
                .update({'isRead': true});

            setState(() {
              noti['isRead'] = true;
            });

            // 화면 이동
            Future<void> navigate;
            if (noti['type'] == 'dm' && noti['roomId'] != null) {
              navigate = Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomPage(
                    roomId: noti['roomId'],
                    targetUid: noti['fromUid'],
                    userName: nickname,
                    profileUrl: profileImg,
                  ),
                ),
              );
            } else if (noti['type'] == 'follow' && noti['fromUid'] != null) {
              navigate = Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyPageTab(
                    userId: noti['fromUid'],
                    onUserTap: (uid) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyPageTab(
                            userId: uid,
                            onUserTap: (uid) {},
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            } else if ((noti['type'] == 'comment' || noti['type'] == 'like') &&
                noti['postId'] != null &&
                noti['fromUid'] != null) {
              navigate = Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyPageTab(
                    userId: noti['fromUid'],
                    onUserTap: (uid) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MyPageTab(
                            userId: uid,
                            onUserTap: (uid) {},
                          ),
                        ),
                      );
                    },
                    // 필요시 selectedFeedId, showDetail 등 파라미터 추가
                  ),
                ),
              );
            } else {
              // 아무 이동이 없는 경우
              navigate = Future.value();
            }

            // 여기서 await 후 새로고침!
            await navigate;
            // 상태 초기화 후 새로고침
            setState(() {
              notificationDocs.clear();
              lastDoc = null;
              hasMore = true;
              isLoading = false;
            });
            fetchNotifications();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('알림'),
        actions: [
          IconButton(
            icon: Icon(Icons.mark_email_read_outlined),
            tooltip: '모두 읽기',
            onPressed: markAllAsRead,
          ),
        ],
      ),
      body: notificationDocs.isEmpty
          ? (isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(child: Text('알림이 없습니다.')))
          : ListView.separated(
        controller: _scrollController,
        itemCount: notificationDocs.length + ((isLoading && hasMore) ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: buildItem,
      ),
    );
  }
}
