import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String userEmail;
  final String userName;
  final String profileUrl;

  const ChatRoomPage({
    Key? key,
    required this.roomId,
    required this.userEmail,
    required this.userName,
    this.profileUrl = 'assets/profile1.jpg',
  }) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 로그인한 내 이메일
  String get myEmail => FirebaseAuth.instance.currentUser?.email ?? '';

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. 메시지 저장
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('message')
        .add({
      'sender': myEmail,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
    });

    // 2. chatRooms 문서 갱신 (★ 이게 있어야 리스트에 내용이 보임)
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastMessageSender': myEmail,
      // 예시로 미열람 수를 관리한다면 아래처럼 추가
      // 'unreadCount_${widget.userEmail}': FieldValue.increment(1),
      // 'unreadCount_$myEmail': 0, // 내가 보냈으니 내 미열람 카운트는 0으로
    });

    _controller.clear();
    Future.delayed(Duration(milliseconds: 200), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
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

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: msgs.length,
                  itemBuilder: (context, i) {
                    final data = msgs[i].data() as Map<String, dynamic>;
                    final sender = data['sender'] ?? '알수없음';
                    final text = data['text'] ?? '';
                    final type = data['type'] ?? 'text';

                    final isMe = sender == myEmail;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment:
                        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: CircleAvatar(
                                radius: 18,
                                backgroundImage: widget.profileUrl.startsWith('http')
                                    ? NetworkImage(widget.profileUrl)
                                    : AssetImage(widget.profileUrl) as ImageProvider,
                              ),
                            ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.pink[100] : Colors.pink[50],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomLeft: isMe ? Radius.circular(18) : Radius.circular(4),
                                  bottomRight: isMe ? Radius.circular(4) : Radius.circular(18),
                                ),
                              ),
                              child: Text(
                                text,
                                style: TextStyle(
                                  color: isMe ? Colors.black : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
