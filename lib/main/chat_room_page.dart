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
    this.profileUrl = 'assets/profile1.jpg',
  }) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String get myUid => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get myName => FirebaseAuth.instance.currentUser?.displayName ?? '';

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

    // 채팅방 메타 정보 갱신
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': myUid,
    });

    _controller.clear();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
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
                  DateFormat('a h:mm', 'ko').format(time),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: widget.profileUrl.startsWith('http')
              ? NetworkImage(widget.profileUrl)
              : AssetImage(widget.profileUrl) as ImageProvider,
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
                DateFormat('a h:mm', 'ko').format(time),
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
              backgroundImage: widget.profileUrl.startsWith('http')
                  ? NetworkImage(widget.profileUrl)
                  : AssetImage(widget.profileUrl) as ImageProvider,
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

                // 👇 메시지 읽음 처리 코드 추가!
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  for (final doc in msgs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final sender = data['sender'] ?? '';
                    final isMe = sender == myUid;
                    final read = data['read'] ?? false;
                    // 내가 보낸 게 아니고, 읽지 않은 메시지라면 읽음 처리
                    if (!isMe && !read) {
                      FirebaseFirestore.instance
                          .collection('chatRooms')
                          .doc(widget.roomId)
                          .collection('message')
                          .doc(doc.id)
                          .update({'read': true});
                    }
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final data = msgs[i].data() as Map<String, dynamic>;
                    final sender = data['sender'] ?? '';
                    final isMe = sender == myUid;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: isMe ? buildMyMsg(data) : buildOtherMsg(data),
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
