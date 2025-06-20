import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main/widget/comment_list.dart';
import 'package:w2wproject/main/widget/image_carousel_card.dart';

// Feed 전체 리스트 페이지
class FeedListPage extends StatefulWidget {
  final void Function(String userId) onUserTap;

  const FeedListPage({Key? key, required this.onUserTap}) : super(key: key);

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
  }

  Future<void> _loadUserId() async {
    String? userId = await getSavedUserId();
    setState(() {
      currentUserId = userId!;
      print("currentUserId====>$currentUserId");
    });
    await fetchFeedsWithWriter();

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
      // 🔐 현재 사용자 정보 가져오기
      final userDoc = await fs.collection('users').doc(currentUserId).get();

      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final List<String> myInterests = List<String>.from(userData['interest'] ?? []);
      final List<String> followingUserIds = List<String>.from(userData['following'] ?? []);

      // 🔁 모든 피드 가져오기
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
            data['writerInfo'] = userCache[writeId];
          } else {
            final userDoc = await fs.collection('users').doc(writeId).get();
            if (userDoc.exists) {
              final writerData = userDoc.data()!;
              final writerDataWithId = {...writerData, 'docId': userDoc.id};
              userCache[writeId] = writerDataWithId;
              data['writerInfo'] = writerDataWithId;
            } else {
              data['writerInfo'] = null;
            }
          }
        } else {
          data['writerInfo'] = null;
        }

        return data;
      });

      final items = await Future.wait(futures);

      // 🧠 관심사 및 팔로우 기반 분류
      List<Map<String, dynamic>> interestFeeds = [];
      List<Map<String, dynamic>> followFeeds = [];
      List<Map<String, dynamic>> otherFeeds = [];

      for (var feed in items) {
        final tags = List<String>.from(feed['tags'] ?? []);
        final writeId = feed['writeid'] ?? '';
        final interestScore = tags.where((tag) => myInterests.contains(tag)).length;

        if (interestScore > 0) {
          feed['interestScore'] = interestScore;
          interestFeeds.add(feed);
        } else if (followingUserIds.contains(writeId)) {
          followFeeds.add(feed);
        } else {
          otherFeeds.add(feed);
        }
      }

      // Step 4: 정렬
      interestFeeds.sort((a, b) =>
          (b['interestScore'] as int).compareTo(a['interestScore'] as int));
      followFeeds.sort((a, b) =>
          (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0));
      otherFeeds.sort((a, b) =>
          (b['cdatetime'] as Timestamp).compareTo(a['cdatetime'] as Timestamp));

      // Step 4-1: 안전하게 랜덤 섞기
      final random = Random();
      if (interestFeeds.isNotEmpty) interestFeeds.shuffle(random);
      if (followFeeds.isNotEmpty) followFeeds.shuffle(random);
      if (otherFeeds.isNotEmpty) otherFeeds.shuffle(random);

      // Step 5: 병합
      final sortedFeeds = [...interestFeeds, ...followFeeds, ...otherFeeds];

      if (sortedFeeds.isEmpty) {
        print("⚠️ 전체 피드가 비어 있음 (필터 조건 확인 필요)");
      }

      setState(() {
        feeds = sortedFeeds;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching feeds with writer info: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> toggleLike(String feedId) async {
    try {
      final feedLikeRef = fs
          .collection('feeds')
          .doc(feedId)
          .collection('likes')
          .doc(currentUserId);
      final userLikeRef = fs
          .collection('users')
          .doc(currentUserId)
          .collection('likedFeeds')
          .doc(feedId);
      final doc = await feedLikeRef.get();

      if (doc.exists) {
        // 좋아요 취소
        await feedLikeRef.delete();
        await userLikeRef.delete();
        //print("좋아요 취소됨");
      } else {
        // 좋아요 추가
        await feedLikeRef.set({
          'userId': currentUserId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        await userLikeRef.set({
          'feedId': feedId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        //print("좋아요 추가됨");
      }

      // UI 리로드는 호출 쪽에서 처리
    } catch (e) {
      print("toggleLike 오류: $e");
    }
  }

  Future<Map<String, dynamic>> getLikeStatusAndCount(String feedId) async {
    try {
      final likeDoc =
          await fs
              .collection('feeds')
              .doc(feedId)
              .collection('likes')
              .doc(currentUserId)
              .get();

      final likeSnapshot =
          await fs.collection('feeds').doc(feedId).collection('likes').get();

      bool isLiked = likeDoc.exists;
      int likeCount = likeSnapshot.size;

      return {'isLiked': isLiked, 'likeCount': likeCount};
    } catch (e) {
      print('좋아요 상태 확인 오류: $e');
      return {'isLiked': false, 'likeCount': 0};
    }
  }

  Future<void> updateMainCoordiId(String newMainCoordiId) async {
    //print("currentUserId>>>>>?$currentUserId");
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId);

      await docRef.update({'mainCoordiId': newMainCoordiId});

      // 업데이트 성공 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대표 코디가 성공적으로 설정되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 오류 발생 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('대표 코디 설정 중 오류 발생: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        if (feed['writeid'] != null &&
                            feed['writeid'] == currentUserId)
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
                            itemBuilder:
                                (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
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
                        Icon(Icons.mood, size: 18, color: Colors.orangeAccent),
                        SizedBox(width: 4),
                        Text(
                          feed['feeling'] ?? '',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(
                          Icons.thermostat,
                          size: 18,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 4),
                        Text(
                          feed['temperature'].toString() ?? '',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),
                    // 이미지 (중앙, 카드 너비 90%, 좌하단+우상단 라운드)
                    Stack(
                      children: [
                        Center(
                          child: FutureBuilder<Map<String, dynamic>>(
                            future: getLikeStatusAndCount(feed['id']),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return CircularProgressIndicator();
                              }

                              final isLiked = snapshot.data!['isLiked'];
                              final likeCount = snapshot.data!['likeCount'];

                              return ImageCarouselCard(
                                imageUrls:
                                    (feed['imageUrls'] as List<dynamic>)
                                        .map((e) => e.toString())
                                        .toList(),
                                profileImageUrl:
                                    feed['writerInfo']?['profileImage'] ?? '',
                                userName:
                                    feed['writerInfo']?['nickname'] ?? '닉네임',
                                onUserTap: () {
                                  final docId =
                                      feed['writerInfo']?['docId'] ?? '';
                                  widget.onUserTap(docId);
                                },
                                isLiked: isLiked,
                                likeCount: likeCount,
                                onLikeToggle: () async {
                                  await toggleLike(feed['id']);
                                  setState(() {}); // 좋아요 상태 반영
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    // 설명
                    Text(feed['content'] ?? '', style: TextStyle(fontSize: 16)),
                    SizedBox(height: 12),
                    feed['tags'] != null && feed['tags'] is List
                        ? Wrap(
                          spacing: 6.0,
                          runSpacing: 2.0,
                          children:
                              (feed['tags'] as List)
                                  .map(
                                    (tag) => Chip(
                                      label: Text(
                                        tag.toString(),
                                        style: TextStyle(
                                          // color: Colors.grey.shade700,
                                          fontSize: 12, // ⬅️ 폰트 크기 축소
                                        ),
                                      ),
                                      // backgroundColor: Colors.grey.shade200,
                                      shape: StadiumBorder(),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 0,
                                      ),
                                      // ⬅️ 내부 여백 축소
                                      visualDensity: VisualDensity.compact,
                                      // ⬅️ 전체 크기 컴팩트하게
                                      materialTapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap, // ⬅️ 터치 영역 축소
                                    ),
                                  )
                                  .toList(),
                        )
                        : SizedBox.shrink(),
                    SizedBox(height: 6),
                    // 위치, 날짜
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          feed['location'] ?? '',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
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
