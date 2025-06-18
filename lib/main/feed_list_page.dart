import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main/widget/comment_list.dart';

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
  List<Map<String, dynamic>> feeds = [];
  String currentUserId = '';

  final FirebaseFirestore fs = FirebaseFirestore.instance;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    fetchFeedsWithWriter();
  }

  Future<void> _loadUserId() async {
    String? userId = await getSavedUserId();
    setState(() {
      currentUserId = userId!;
      print("currentUserId====>$currentUserId");
    });
  }

  Future<String?> getSavedUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId');
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = timestamp.toDate(); // Firestore Timestamp → DateTime
      final year = dateTime.year % 100;
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$year-$month-$day $hour:$minute';
    } catch (e) {
      return '';
    }
  }

  Future<void> fetchFeedsWithWriter() async {
    try {
      final snapshot = await fs
          .collection('feeds')
          .orderBy('cdatetime', descending: true)
          .get();

      final Map<String, Map<String, dynamic>> userCache = {};

      final futures = snapshot.docs.map((doc) async {
        final data = doc.data();
        data['id'] = doc.id;

        final writeId = data['writeid'];

        if (writeId != null && writeId.isNotEmpty) {
          if (userCache.containsKey(writeId)) {
            // 캐시에 있으면 바로 넣기
            data['writerInfo'] = userCache[writeId];
          } else {
            // 캐시에 없으면 users 조회
            final userDoc = await fs.collection('users').doc(writeId).get();
            if (userDoc.exists) {
              final userData = userDoc.data()!;
              // 문서 ID를 포함한 새 Map 생성
              final userDataWithId = {
                ...userData,
                'docId': userDoc.id,
              };
              userCache[writeId] = userDataWithId;
              data['writerInfo'] = userDataWithId;
            } else {
              data['writerInfo'] = null;
            }
          }
        } else {
          data['writerInfo'] = null;
        }
        print("writerInfo ===> ${data['writerInfo']}");
        return data;
      });

      final items = await Future.wait(futures);

      setState(() {
        feeds = items;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching feeds with writer info: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

    Future<void> updateMainCoordiId( String newMainCoordiId ) async {
    print("currentUserId>>>>>?$currentUserId");
      try {
        final docRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);

        await docRef.update({
          'mainCoordiId': newMainCoordiId,
        });

        print('mainCoordiId가 성공적으로 업데이트되었습니다.');
      } catch (e) {
        print('mainCoordiId 업데이트 중 오류 발생: $e');
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: feeds.length, // feeds -> feedItems
          itemBuilder: (context, index) {
            final feed = feeds[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 타이틀 + 메뉴 점 세 개
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              feed['title'] ?? '',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.grey),
                            onSelected: (value) {
                              // 메뉴 선택 시 동작
                              if (value == 'edit') {
                                print("Edit 선택됨");
                              } else if (value == 'del') {
                                print("Delete 선택됨");
                              } else if (value == 'main') {
                                updateMainCoordiId(feed['id']);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text('수정'),
                              ),
                              PopupMenuItem<String>(
                                value: 'del',
                                child: Text('삭제'),
                              ),
                              PopupMenuItem<String>(
                                value: 'main',
                                child: Text('대표설정'),
                              ),
                            ],
                          ),
                        ],
                      ),

                      SizedBox(height: 4),

                      Row(
                        children: [
                          Icon(
                              Icons.mood, size: 18, color: Colors.orangeAccent),
                          SizedBox(width: 4),
                          Text(feed['feeling'] ?? '', style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.w600)),
                          SizedBox(width: 16),
                          Icon(Icons.thermostat, size: 18,
                              color: Colors.redAccent),
                          SizedBox(width: 4),
                          Text(feed['temperature'].toString() ?? '', style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600)),
                        ],
                      ),

                      SizedBox(height: 12),
                      // 이미지 (중앙, 카드 너비 90%, 좌하단+우상단 라운드)
                      Stack(
                        children: [
                          Center(
                            child:
                            feed!['imageUrls'] != null
                                ? _buildImageCarousel(
                                imageUrls: (feed!['imageUrls'] as List<dynamic>).map((e) => e.toString()).toList(),
                                profileImageUrl : feed['writerInfo']?['profileImage'] ?? '',
                                userName : feed['writerInfo']?['nickname'] ?? '닉네임',
                                onUserTap: () {
                                  final docId = feed['writerInfo']?['docId'] ?? '';
                                  widget.onUserTap(docId);
                                },
                            )
                                : Container(height: 200, color: Colors.grey[300]),
                          ),
                          Positioned(
                            left: MediaQuery
                                .of(context)
                                .size
                                .width * 0.05,
                            bottom: 8,
                            child: Icon(
                              Icons.favorite_border,
                              color: Colors.white70,
                              size: 28,
                            ),
                          ),
                          Positioned(
                            right: MediaQuery
                                .of(context)
                                .size
                                .width * 0.05,
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
                      Text(feed['content'] ?? '',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 12),
                      feed['tags'] != null && feed['tags'] is List
                          ? Wrap(
                        spacing: 6.0,
                        runSpacing: 2.0,
                        children: (feed['tags'] as List)
                            .map((tag) => Chip(
                          label: Text(
                            tag.toString(),
                            style: TextStyle(
                              // color: Colors.grey.shade700,
                              fontSize: 12, // ⬅️ 폰트 크기 축소
                            ),
                          ),
                          // backgroundColor: Colors.grey.shade200,
                          shape: StadiumBorder(),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0), // ⬅️ 내부 여백 축소
                          visualDensity: VisualDensity.compact, // ⬅️ 전체 크기 컴팩트하게
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // ⬅️ 터치 영역 축소
                        ))
                            .toList(),
                      )
                          : SizedBox.shrink()
                      ,
                      SizedBox(height: 6),
                      // 위치, 날짜
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(feed['location'] ?? '',
                              style: TextStyle(color: Colors.grey.shade500)),
                          Text(
                            _formatDate(feed['cdatetime']),
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      Divider(color: Colors.grey.shade300),

                      // 댓글 및 대댓글 -> CommentSection 위젯으로 교체
                      CommentSection(
                        key: ValueKey("comment_${feed['id']}"),
                        feedId: feed['id'],
                        currentUserId: currentUserId,
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



// --- 이미지 슬라이더 UI 함수 --- //
Widget _buildImageCarousel({
  required List<String> imageUrls,
  required String profileImageUrl,
  required String userName,
  required void Function() onUserTap,
}) {
  if (imageUrls.isEmpty) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      alignment: Alignment.center,
      child: Text('이미지가 없습니다'),
    );
  }

  Widget buildImage(String imageUrl) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: Image.network(
            imageUrl,
            height: 480,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // 프로필 사진 + 닉네임 위치
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onTap: () {
                onUserTap(); // userId 전달해서 페이지 열기
              },
              child: Row(
                children: [
                  ClipOval(
                    child: Container(
                      width: 32,
                      height: 32,
                      color: Colors.grey[400], // 기본 배경색 (사진 없을 때)
                      child: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 이미지 로드 실패 시 기본 배경만 보여줌
                          return Container(color: Colors.grey[400]);
                        },
                      )
                          : null, // 사진 없으면 비워둠
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  if (imageUrls.length == 1) {
    return buildImage(imageUrls[0]);
  } else {
    return SizedBox(
      height: 480,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return buildImage(imageUrls[index]);
        },
      ),
    );
  }
}