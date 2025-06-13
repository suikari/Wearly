import 'package:flutter/material.dart';

class DetailPage extends StatefulWidget {
  final String imagePath;
  final VoidCallback? onBack;

  const DetailPage({Key? key, required this.imagePath, this.onBack}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late List<Comment> comments;
  Map<int, bool> showReplyInput = {};
  Map<int, TextEditingController> replyControllers = {};

  final TextEditingController commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // 댓글 데이터를 새로 할당 (필요하면 widget으로부터 받아올 수도 있음)
    comments = [
      Comment(
        userImage: "assets/w1.jpg",
        userName: "이두나",
        comment: "빈티지 하면 사나 사나하면 빈티지",
        replies: [
          CommentReply(userName: "지나", comment: "ㅋㅋ 완전 공감이요"),
        ],
      ),
      Comment(
        userImage: "assets/w2.jpg",
        userName: "서서나",
        comment: "진짜 스타일 미쳤다",
        replies: [],
      ),
    ];

    // 대댓글 입력 상태 초기화
    showReplyInput = {};
    replyControllers = {};

    // 스크롤 위치 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });
  }

  @override
  void dispose() {
    commentController.dispose();
    for (var ctrl in replyControllers.values) {
      ctrl.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 앱바
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                ),
                Text("상세 페이지", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // 이 부분 추가
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 메뉴
                    Row(
                      children: [
                        Text(
                          "오늘의 코디는 미니멀하게~",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Spacer(),
                        Icon(Icons.more_vert),
                      ],
                    ),
                    SizedBox(height: 8),

                    // 날씨 정보
                    Row(
                      children: [
                        Chip(
                          label: Text("더워요"),
                          backgroundColor: Colors.pink.shade100,
                          labelStyle: TextStyle(color: Colors.white),
                          padding: EdgeInsets.zero,
                        ),
                        SizedBox(width: 8),
                        Chip(
                          label: Text("19°C"),
                          backgroundColor: Colors.pink.shade100,
                          labelStyle: TextStyle(color: Colors.white),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // 이미지
                    Container(
                      height: 600,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.pink.shade50,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image.asset(
                        widget.imagePath,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: 12),

                    // 좋아요/공유
                    Row(
                      children: [
                        Icon(Icons.favorite_border),
                        Spacer(),
                        Icon(Icons.share),
                      ],
                    ),
                    SizedBox(height: 8),

                    // 피드 설명
                    Text("빈티지 스타일 청바지에 셔츠~", style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("#빈티지 #청바지 #셔츠 #블라우스", style: TextStyle(color: Colors.grey.shade600)),
                    SizedBox(height: 4),
                    Text("모던 부림1동", style: TextStyle(color: Colors.grey.shade500)),
                    SizedBox(height: 4),
                    Text("2025.05.16", style: TextStyle(color: Colors.grey.shade500)),

                    Divider(height: 32),

                    // 댓글 리스트
                    ...comments.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Comment comment = entry.value;
                      return _buildComment(idx, comment);
                    }).toList(),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 댓글 입력창
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: AssetImage("assets/w1.jpg"),
                    radius: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: "댓글을 입력하세요...",
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      final text = commentController.text.trim();
                      if (text.isNotEmpty) {
                        setState(() {
                          comments.add(
                            Comment(
                              userImage: "assets/w1.jpg",
                              userName: "나", // 본인 이름으로 변경 가능
                              comment: text,
                              replies: [],
                            ),
                          );
                          commentController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(int idx, Comment comment) {
    // 대댓글 입력 컨트롤러 초기화
    replyControllers[idx] ??= TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundImage: AssetImage(comment.userImage),
                radius: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${comment.userName} ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: comment.comment,
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    showReplyInput[idx] = !(showReplyInput[idx] ?? false);
                  });
                },
                child: Text("답글", style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          // 대댓글 입력창 토글
          if (showReplyInput[idx] ?? false)
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyControllers[idx],
                      decoration: InputDecoration(
                        hintText: "답글을 입력하세요...",
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.send, size: 20),
                    onPressed: () {
                      final replyText = replyControllers[idx]!.text.trim();
                      if (replyText.isNotEmpty) {
                        setState(() {
                          comment.replies.add(CommentReply(
                            userName: "나", // 본인 이름
                            comment: replyText,
                          ));
                          replyControllers[idx]!.clear();
                          showReplyInput[idx] = false; // 입력창 닫기
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

          // 대댓글 목록
          ...comment.replies.map((reply) => Padding(
            padding: const EdgeInsets.only(left: 48, top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
                SizedBox(width: 6),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "${reply.userName} ",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        TextSpan(
                          text: reply.comment,
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// 댓글 구조 정의
class Comment {
  final String userImage;
  final String userName;
  final String comment;
  final List<CommentReply> replies;

  Comment({
    required this.userImage,
    required this.userName,
    required this.comment,
    required this.replies,
  });
}

// 대댓글 구조 정의
class CommentReply {
  final String userName;
  final String comment;

  CommentReply({required this.userName, required this.comment});
}
