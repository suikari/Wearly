import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main/widget/comment_list.dart';
import 'package:w2wproject/main/widget/image_carousel_card.dart';

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
                          if (feed['writeid'] != null && feed['writeid'] == currentUserId)
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
                                ? ImageCarouselCard(
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

