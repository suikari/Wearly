import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main/chat_room_page.dart';

// 프로필 캐시 (fromUid 기준)
final Map<String, Map<String, dynamic>> userCache = {};

class NotificationPage extends StatefulWidget {
  final String uid;
  final Function? onUserTap; // 마이페이지 이동 콜백

  const NotificationPage({
    Key? key,
    required this.uid,
    required this.onUserTap,
  }) : super(key: key);

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

  // 1. 5분 중복 DM 제거용 함수
  List<DocumentSnapshot> filterDuplicateDM(List<DocumentSnapshot> docs) {
    final List<DocumentSnapshot> result = [];
    final Map<String, DateTime> lastDmTimeByUser = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['type'] != 'dm') {
        result.add(doc); // dm이 아니면 무조건 추가
        continue;
      }
      final fromUid = data['fromUid'];
      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
      if (fromUid == null || createdAt == null) continue;

      final lastTime = lastDmTimeByUser[fromUid];
      if (lastTime == null || createdAt.difference(lastTime).inMinutes > 5) {
        result.add(doc); // 5분 넘었으면 추가
        lastDmTimeByUser[fromUid] = createdAt;
      }
      // 5분 이내 중복 DM은 무시!
    }
    return result;
  }

  Future<void> fetchNotifications() async {
    if (isLoading || !hasMore) return;
    setState(() => isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: widget.uid)
        .orderBy('createdAt', descending: true)
        .limit(pageSize * 5);

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc!);
    }

    final snap = await query.get();

    if (mounted) {
      final docs = filterDuplicateDM(snap.docs);

      setState(() {
        if (docs.isNotEmpty) {
          notificationDocs.addAll(docs);
          lastDoc = snap.docs.isNotEmpty ? snap.docs.last : null;
        }
        if (snap.docs.length < pageSize * 5) hasMore = false;
        isLoading = false;
      });
    }
  }

  /// 모두 읽기
  Future<void> markAllAsRead() async {
    final unreadQuery = await FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: widget.uid)
        .where('isRead', isEqualTo: false)
        .get();
    if (unreadQuery.docs.isEmpty) return;

    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in unreadQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();

    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      notificationDocs.clear();
      lastDoc = null;
      hasMore = true;
      isLoading = false;
    });
    await fetchNotifications();
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

  // ✅ fromUid 기준 유저 정보 로드(profileImage 필드 주의!)
  Future<Map<String, dynamic>> fetchUserInfo(String uid) async {
    if (userCache.containsKey(uid)) return userCache[uid]!;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    String nickname = '알 수 없음';
    String profileImg = '';
    if (doc.exists) {
      final data = doc.data();
      nickname = data?['nickname'] ?? nickname;
      profileImg = data?['profileImage'] ?? '';
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
          leading: GestureDetector(
            onTap: () async {
              // 마이페이지 이동 (팝 + 콜백)
              Navigator.of(context).pop();
              await Future.delayed(Duration(milliseconds: 50));
              if (widget.onUserTap != null) widget.onUserTap!(fromUid);
            },
            child: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 24,
              backgroundImage: profileImg.isEmpty
                  ? AssetImage('assets/default_profile.jpg')
                  : (profileImg.startsWith('http')
                  ? NetworkImage(profileImg)
                  : AssetImage(profileImg)) as ImageProvider,
              onBackgroundImageError: (_, __) {},
            ),
          ),
          title: GestureDetector(
            onTap: () async {
              Navigator.of(context).pop();
              await Future.delayed(Duration(milliseconds: 50));
              if (widget.onUserTap != null) widget.onUserTap!(fromUid);
            },
            child: Text(
              '${typeLabel(noti['type'])}$nickname',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isRead ? Colors.grey : Colors.black,
              ),
            ),
          ),
          subtitle: Text(
            content,
            style: TextStyle(color: isRead ? Colors.grey : Colors.black),
          ),
          trailing: Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey)),
          tileColor: isRead ? Colors.grey[100] : Colors.white,
          onTap: () async {
            if (noti['type'] == 'dm' &&
                noti['fromUid'] != null &&
                noti['createdAt'] != null &&
                noti['roomId'] != null) {
              // DM이면 여러개 읽음 처리 후 채팅방 이동
              final fromUid = noti['fromUid'];
              final baseTime = (noti['createdAt'] as Timestamp).toDate();
              final lowerBound = baseTime.subtract(Duration(minutes: 5));
              final upperBound = baseTime.add(Duration(minutes: 5));
              final dmSnap = await FirebaseFirestore.instance
                  .collection('notifications')
                  .where('uid', isEqualTo: widget.uid)
                  .where('fromUid', isEqualTo: fromUid)
                  .where('type', isEqualTo: 'dm')
                  .where('isRead', isEqualTo: false)
                  .get();

              WriteBatch batch = FirebaseFirestore.instance.batch();
              for (var d in dmSnap.docs) {
                final dData = d.data() as Map<String, dynamic>;
                final dTime = (dData['createdAt'] as Timestamp?)?.toDate();
                if (dTime != null &&
                    dTime.isAfter(lowerBound) &&
                    dTime.isBefore(upperBound)) {
                  batch.update(d.reference, {'isRead': true});
                }
              }
              await batch.commit();

              // 채팅방 이동 (pop 하지 않음)
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChatRoomPage(
                  roomId: noti['roomId'],
                  targetUid: noti['fromUid'],
                  userName: nickname,
                  profileUrl: profileImg,
                ),
              ));
            } else {
              // 기타(팔로우/댓글/좋아요) → 읽음 처리 & 마이페이지 이동
              await FirebaseFirestore.instance
                  .collection('notifications')
                  .doc(doc.id)
                  .update({'isRead': true});
              Navigator.of(context).pop();
              await Future.delayed(Duration(milliseconds: 50));
              if (widget.onUserTap != null) widget.onUserTap!(fromUid);
            }

            // 새로고침
            setState(() {
              noti['isRead'] = true;
              notificationDocs.clear();
              lastDoc = null;
              hasMore = true;
              isLoading = false;
            });
            await fetchNotifications();
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
