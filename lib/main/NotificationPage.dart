import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main/chat_room_page.dart';

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
  bool firstFetchDone = false;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // 스크롤이 바닥 근처(맨 아래) && not loading && more data available && 최소 한 페이지는 있음
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
        firstFetchDone = true;
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

  Widget buildItem(BuildContext context, int idx) {
    if (idx >= notificationDocs.length) {
      // 맨 아래 로딩 인디케이터 (더 불러올 게 있을 때만)
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
    final fromProfileImg = noti['fromProfileImg'];
    final fromNickname = noti['fromNickname'] ?? '알 수 없음';
    final content = noti['content'] ?? '';
    final date = (noti['createdAt'] as Timestamp?)?.toDate();
    final dateStr = date != null
        ? '${date.year.toString().substring(2)}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}'
        : '';
    final isRead = noti['isRead'] ?? false;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.white,
        radius: 24,
        backgroundImage: fromProfileImg == null || fromProfileImg == ''
            ? AssetImage('assets/default_profile.png')
            : (fromProfileImg.startsWith('http')
            ? NetworkImage(fromProfileImg)
            : AssetImage(fromProfileImg)) as ImageProvider,
        onBackgroundImageError: (_, __) {},
      ),
      title: Text(
        fromNickname,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isRead ? Colors.grey : Colors.black),
      ),
      subtitle: Text(content,
          style: TextStyle(color: isRead ? Colors.grey : Colors.black)),
      trailing: Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey)),
      tileColor: isRead ? Colors.grey[100] : Colors.white,
      onTap: () async {
        await FirebaseFirestore.instance
            .collection('notifications')
            .doc(doc.id)
            .update({'isRead': true});

        if (noti['type'] == 'dm' && noti['roomId'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(
                roomId: noti['roomId'],
                targetUid: noti['fromUid'],
                userName: noti['fromNickname'] ?? '',
                profileUrl: noti['fromProfileImg'] ?? '',
              ),
            ),
          );
        }
        setState(() {
          noti['isRead'] = true;
        });
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
