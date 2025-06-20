import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String targetUid;
  final String userName;
  final String profileUrl;

  const ChatRoomPage({
    Key? key,
    required this.roomId,
    required this.targetUid,
    required this.userName,
    this.profileUrl = 'assets/default_profile.png',
  }) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get myName => FirebaseAuth.instance.currentUser?.displayName ?? '';

  @override
  void initState() {
    super.initState();
    _markMyUnreadZero();
  }

  // 항상 최신으로 이동
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _markMyUnreadZero() async {
    final roomRef = FirebaseFirestore.instance.collection('chatRooms').doc(widget.roomId);
    await roomRef.update({'unreadCount_$myUid': 0});
  }

  String formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.year == time.year && now.month == time.month && now.day == time.day) {
      return DateFormat('a h:mm', 'ko').format(time);
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }

  Widget buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: Color(0xFFFBCFD5),
              thickness: 1,
              endIndent: 10,
            ),
          ),
          Text(
            DateFormat('yyyy년 M월 d일', 'ko').format(date),
            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
          const Expanded(
            child: Divider(
              color: Color(0xFFFBCFD5),
              thickness: 1,
              indent: 10,
            ),
          ),
        ],
      ),
    );
  }

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('message')
        .add({
      'sender': myUid,
      'senderName': myName,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
      'type': 'text',
    });

    // 채팅방 메타 정보 갱신 + 상대방 unreadCount 증가
    await FirebaseFirestore.instance.runTransaction((txn) async {
      final roomRef = FirebaseFirestore.instance.collection('chatRooms').doc(widget.roomId);
      final roomSnap = await txn.get(roomRef);

      if (!roomSnap.exists) return;

      final roomData = roomSnap.data() as Map<String, dynamic>;
      final uids = roomData['uids'] as List;
      final targetUid = uids.firstWhere((uid) => uid != myUid);

      final fieldName = 'unreadCount_$targetUid';
      final curUnread = roomData[fieldName] ?? 0;

      txn.update(roomRef, {
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': myUid,
        fieldName: curUnread + 1,
      });
    });

    _controller.clear();
    // 메시지 보낸 뒤에도 아래로
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Widget buildMyMsg(Map<String, dynamic> data) {
    final text = data['text'] ?? '';
    final time = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final read = data['read'] ?? false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: Colors.pink[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(text, style: const TextStyle(color: Colors.black)),
            ),
            Row(
              children: [
                Text(
                  formatTime(time),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(width: 2),
                Icon(
                  read ? Icons.done_all : Icons.done,
                  size: 15,
                  color: read ? Colors.blue : Colors.grey,
                ),
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget buildOtherMsg(Map<String, dynamic> data) {
    final text = data['text'] ?? '';
    final time = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final senderName = data['senderName'] ?? widget.userName;

    ImageProvider getProfileImage() {
      if (widget.profileUrl.isEmpty || widget.profileUrl == 'null') {
        return const AssetImage('assets/default_profile.png');
      } else if (widget.profileUrl.startsWith('http')) {
        return NetworkImage(widget.profileUrl);
      } else {
        return AssetImage(widget.profileUrl);
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: getProfileImage(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                senderName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                margin: const EdgeInsets.only(top: 2, bottom: 2),
                decoration: BoxDecoration(
                  color: Colors.pink[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: Text(text, style: const TextStyle(color: Colors.black87)),
              ),
              Text(
                formatTime(time),
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(width: 30),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        elevation: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: (widget.profileUrl.isEmpty || widget.profileUrl == 'null')
                  ? const AssetImage('assets/default_profile.png')
                  : (widget.profileUrl.startsWith('http')
                  ? NetworkImage(widget.profileUrl)
                  : AssetImage(widget.profileUrl)) as ImageProvider,
              radius: 20,
            ),
            const SizedBox(width: 10),
            Text(
              '${widget.userName} 님',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(widget.roomId)
                  .collection('message')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!.docs;

                // 새 데이터가 들어올 때마다 최신으로 이동!
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                // 읽지 않은 메시지는 읽음 처리 + unreadCount 0
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  for (final doc in msgs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final sender = data['sender'] ?? '';
                    final isMe = sender == myUid;
                    final read = data['read'] ?? false;
                    if (!isMe && !read) {
                      FirebaseFirestore.instance
                          .collection('chatRooms')
                          .doc(widget.roomId)
                          .collection('message')
                          .doc(doc.id)
                          .update({'read': true});
                    }
                  }
                  await _markMyUnreadZero();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final data = msgs[i].data() as Map<String, dynamic>;
                    final sender = data['sender'] ?? '';
                    final isMe = sender == myUid;
                    final time = data['createdAt'] is Timestamp
                        ? (data['createdAt'] as Timestamp).toDate()
                        : DateTime.now();

                    bool showDateSeparator = false;
                    if (i == 0) {
                      showDateSeparator = true;
                    } else {
                      final prev = msgs[i - 1].data() as Map<String, dynamic>;
                      final prevTime = prev['createdAt'] is Timestamp
                          ? (prev['createdAt'] as Timestamp).toDate()
                          : DateTime.now();
                      if (time.difference(prevTime).inDays > 0 ||
                          time.day != prevTime.day ||
                          time.month != prevTime.month ||
                          time.year != prevTime.year) {
                        showDateSeparator = true;
                      }
                    }

                    List<Widget> widgets = [];
                    if (showDateSeparator) {
                      final dayTime = DateTime(time.year, time.month, time.day, 0, 0, 0);
                      widgets.add(buildDateSeparator(dayTime));
                    }
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: isMe ? buildMyMsg(data) : buildOtherMsg(data),
                      ),
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widgets,
                    );
                  },
                );
              },
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color.fromRGBO(255, 111, 97, 1.0), width: 2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: "메시지 보내기...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.pink[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
