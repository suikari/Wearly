import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String userName;
  final String profileUrl; // 상대 프로필 url(필요하면 추가)

  const ChatRoomPage({
    Key? key,
    required this.roomId,
    required this.userName,
    this.profileUrl = 'assets/profile1.jpg', // 없으면 기본값
  }) : super(key: key);

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 예시용 내 ID
  final String myId = '내_유저ID';

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('message')
        .add({
      'sender': myId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text', // 텍스트/이미지 구분용
    });

    _controller.clear();
    // 스크롤 맨 아래로
    Future.delayed(Duration(milliseconds: 200), () {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  // 이미지 보내기 예시 (실제 파일 업로드 로직은 생략)
  void sendImage(String imageUrl) async {
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .collection('message')
        .add({
      'sender': myId,
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'image',
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
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // 메시지 영역
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
                    final imageUrl = data['imageUrl'];

                    final isMe = sender == myId;

                    return Container(
                      margin: EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
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
                            child: type == 'text'
                                ? Container(
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
                            )
                                : Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.pink[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: imageUrl != null
                                  ? Image.network(imageUrl, width: 120)
                                  : const Text('이미지 오류'),
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
          // 입력창
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
                  IconButton(
                    icon: const Icon(Icons.photo, color: Colors.pink),
                    onPressed: () async {
                      // TODO: 실제 이미지 업로드 구현 (예시: 파일 피커 등)
                      // 여기선 임시로 이미지 url 보내기
                      sendImage("https://i.imgur.com/OtY9b1E.png");
                    },
                  ),
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
