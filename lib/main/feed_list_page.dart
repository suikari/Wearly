import 'package:flutter/material.dart';

// 댓글 모델 (대댓글 포함)
class Comment {
  final String userName;
  final String comment;
  final List<Comment> replies; // 대댓글 리스트

  Comment({
    required this.userName,
    required this.comment,
    List<Comment>? replies,
  }) : replies = replies ?? [];
}

// Feed 모델
class Feed {
  final String imagePath;
  final String title;
  final String description;
  final String hashtags;
  final String location;
  final String date;
  final String mood;
  final String temperature;
  final List<Comment> comments;

  Feed({
    required this.imagePath,
    required this.title,
    required this.description,
    required this.hashtags,
    required this.location,
    required this.date,
    required this.mood,
    required this.temperature,
    List<Comment>? comments,
  }) : comments = comments ?? [];
}

// Feed 전체 리스트 페이지
class FeedListPage extends StatefulWidget {
  final void Function(String userId) onUserTap;

  const FeedListPage({
    Key? key,
    required this.onUserTap,
  }) : super(key: key);

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  late List<Feed> feeds;

  @override
  void initState() {
    super.initState();

    feeds = [
      Feed(
        imagePath: "assets/w1.jpg",
        title: "오늘의 코디는 미니멀하게~",
        description: "빈티지 스타일 청바지에 셔츠~",
        hashtags: "#빈티지 #청바지 #셔츠 #블라우스",
        location: "모던 부림1동",
        date: "2025.05.16",
        temperature : "20℃",
        mood : "더워요",
        comments: [
          Comment(
            userName: "이두나",
            comment: "빈티지 하면 사나 사나하면 빈티지!",
            replies: [
              Comment(userName: "서세나", comment: "정말 공감해요!"),
              Comment(userName: "박철수", comment: "멋진 코디네요~"),
            ],
          ),
          Comment(userName: "서세나", comment: "빈티지 하면 사나 사나하면 빈티지!"),
        ],
      ),
      Feed(
        imagePath: "assets/w2.jpg",
        title: "편안한 봄 패션 추천",
        description: "가벼운 바람막이와 스니커즈 조합",
        hashtags: "#봄패션 #캐주얼 #편안함",
        location: "강남구 역삼동",
        date: "2025.06.10",
        temperature : "24℃",
        mood : "적당핸요",
        comments: [
          Comment(userName: "김철수", comment: "완전 편해 보여요!"),
        ],
      ),
    ];
  }

  Widget _buildComment(Comment comment, {double leftPadding = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding, top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  widget.onUserTap('user456');  // userId 전달해서 페이지 열기
                },
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade400,
                  child: Text(
                    comment.userName.isNotEmpty ? comment.userName[0] : '',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "${comment.userName} ",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      TextSpan(
                        text: comment.comment,
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (comment.replies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                children: comment.replies
                    .map((reply) => _buildComment(reply, leftPadding: leftPadding + 20))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: feeds.length,
        itemBuilder: (context, index) {
          final feed = feeds[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타이틀 + 메뉴 점 세 개
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            feed.title,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                        ),
                        Icon(Icons.more_vert, color: Colors.grey),
                      ],
                    ),

                    SizedBox(height: 4),

                    Row(
                      children: [
                        Icon(Icons.mood, size: 18, color: Colors.orangeAccent),
                        SizedBox(width: 4),
                        Text(feed.mood, style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
                        SizedBox(width: 16),
                        Icon(Icons.thermostat, size: 18, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text(feed.temperature, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      ],
                    ),

                    SizedBox(height: 12),
                    // 이미지 (중앙, 카드 너비 90%, 좌하단+우상단 라운드)
                    Stack(
                      children: [
                        Center(
                          child: Container(
                            height: 480,
                            width: MediaQuery.of(context).size.width * 0.9,
                            decoration: BoxDecoration(
                              color: Colors.pink.shade50,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              image: DecorationImage(
                                image: AssetImage(feed.imagePath),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        // 이미지 하단 왼쪽 좋아요, 공유 아이콘 (반복 의도인지 한쪽만 하단 넣음)
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.05,
                          bottom: 8,
                          child: Icon(
                            Icons.favorite_border,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                        // 공유 아이콘 - 오른쪽 하단
                        Positioned(
                          right: MediaQuery.of(context).size.width * 0.05,
                          bottom: 8,
                          child: Icon(
                            Icons.share_outlined,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // 설명
                    Text(feed.description, style: TextStyle(fontSize: 16)),
                    SizedBox(height: 12),
                    Text(
                      feed.hashtags,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14,),
                    ),
                    SizedBox(height: 6),
                    // 위치, 날짜
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(feed.location, style: TextStyle(color: Colors.grey.shade500)),
                        Text(feed.date, style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),

                    SizedBox(height: 16),

                    Divider(color: Colors.grey.shade300),

                    // 댓글 및 대댓글
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: feed.comments.map((c) => _buildComment(c)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

