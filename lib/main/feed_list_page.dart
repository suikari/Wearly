import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main/widget/comment_list.dart';
import 'package:w2wproject/main/widget/image_carousel_card.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../common/dialog_util.dart';
import '../provider/custom_colors.dart';
import '../provider/theme_provider.dart';
import 'edit_post_page.dart';

class FeedListPage extends StatefulWidget {
  final void Function(String userId) onUserTap;

  const FeedListPage({Key? key, required this.onUserTap}) : super(key: key);

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  List<Map<String, dynamic>> feeds = [];
  Map<String, bool> likedStatus = {};
  Map<String, int> likeCounts = {};

  String currentUserId = '';

  List<String> filteredTags = []; // 다중 태그 필터 상태로 변경

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
      currentUserId = userId ?? '';
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

  // 다중 태그 필터 설정 함수 (추가/제거)
  void toggleTagFilter(String tag) {
    setState(() {
      if (filteredTags.contains(tag)) {
        filteredTags.remove(tag);
      } else {
        filteredTags.add(tag);
      }
      isLoading = true;
    });
    fetchFeedsWithWriter();
  }

  Future<void> fetchFeedsWithWriter() async {
    try {
      final userDoc = await fs.collection('users').doc(currentUserId).get();
      if (!userDoc.exists) throw Exception('User not found');

      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final List<String> myInterests = List<String>.from(
          userData['interest'] ?? []);
      final List<String> followingUserIds = List<String>.from(
          userData['following'] ?? []);

      Query query = fs.collection('feeds').orderBy(
          'cdatetime', descending: true);

      // 다중 태그 필터 조건 적용
      if (filteredTags.isNotEmpty) {
        // tags 필드가 filteredTags에 포함된 모든 태그를 포함하는 문서 필터링:
        // Firestore에선 복잡한 조건 어려워서 임시 방편으로 where('tags', arrayContainsAny, filteredTags) 후 클라이언트에서 재필터링 권장.
        // 여기서는 arrayContainsAny 사용 (OR 조건)
        query = query.where('tags', arrayContainsAny: filteredTags);
      }

      final snapshot = await query.get();

      final Map<String, Map<String, dynamic>> userCache = {};

      final futures = snapshot.docs.map((doc) async {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        final writeId = data['writeid'] ?? '';

        if (writeId.isNotEmpty) {
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

      // 클라이언트에서 다중 태그 모두 포함 여부로 필터링 (AND 조건)
      List<Map<String, dynamic>> filteredItems = items.where((feed) {
        if (filteredTags.isEmpty) return true;
        final feedTags = List<String>.from(feed['tags'] ?? []);
        return filteredTags.every((tag) => feedTags.contains(tag));
      }).toList();

      // 관심사 및 팔로우 기반 분류
      List<Map<String, dynamic>> interestFeeds = [];
      List<Map<String, dynamic>> followFeeds = [];
      List<Map<String, dynamic>> otherFeeds = [];

      for (var feed in filteredItems) {
        final tags = List<String>.from(feed['tags'] ?? []);
        final writeId = feed['writeid'] ?? '';
        final interestScore = tags
            .where((tag) => myInterests.contains(tag))
            .length;

        if (interestScore > 0) {
          feed['interestScore'] = interestScore;
          interestFeeds.add(feed);
        } else if (followingUserIds.contains(writeId)) {
          followFeeds.add(feed);
        } else {
          otherFeeds.add(feed);
        }
      }

      interestFeeds.sort((a, b) {
        int interestCompare = (b['interestScore'] as int).compareTo(a['interestScore'] as int);
        if (interestCompare != 0) return interestCompare;

        return (b['cdatetime'] as Timestamp).compareTo(a['cdatetime'] as Timestamp);
      });

      followFeeds.sort((a, b) {
        int likeCompare = (b['likeCount'] ?? 0).compareTo(a['likeCount'] ?? 0);
        if (likeCompare != 0) return likeCompare;

        return (b['cdatetime'] as Timestamp).compareTo(a['cdatetime'] as Timestamp);
      });

      otherFeeds.sort((a, b) =>
          (b['cdatetime'] as Timestamp).compareTo(a['cdatetime'] as Timestamp));

      final random = Random();
      if (interestFeeds.isNotEmpty) interestFeeds.shuffle(random);
      if (followFeeds.isNotEmpty) followFeeds.shuffle(random);
      if (otherFeeds.isNotEmpty) otherFeeds.shuffle(random);

      final sortedFeeds = [...interestFeeds, ...followFeeds, ...otherFeeds];

      if (sortedFeeds.isEmpty) {
        print(" 전체 피드가 비어 있음 (필터 조건 확인 필요)");
      }

      final likedDataFutures = sortedFeeds.map((feed) async {
        final feedId = feed['id'];
        final result = await getLikeStatusAndCount(feedId);
        likedStatus[feedId] = result['isLiked'];
        likeCounts[feedId] = result['likeCount'];
      });
      await Future.wait(likedDataFutures);

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



  Future<void> toggleLike(Map<String, dynamic> feed) async {
    final feedId = feed['id'];
    final writeUesrid = feed['writerInfo']?['docId'];
    final feedTitle = feed['title'];
    final currentLiked = likedStatus[feedId] ?? false;

    try {
      setState(() {
        likedStatus[feedId] = !currentLiked;
        likeCounts[feedId] = (likeCounts[feedId] ?? 0) + (currentLiked ? -1 : 1);
      });

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
        await Future.wait([
          feedLikeRef.delete(),
          userLikeRef.delete(),
        ]);
      } else {
        await FirebaseFirestore.instance.collection('notifications').add({
          'uid' : writeUesrid, // 알림 받을 사람(피드 주인)
          'type' : 'comment',
          'fromUid': currentUserId,
          'content': '($feedTitle)게시글을 좋아합니다. ',
          'postId': feedId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        await Future.wait([
          feedLikeRef.set({
            'userId': currentUserId,
            'createdAt': FieldValue.serverTimestamp(),
          }),
          userLikeRef.set({
            'feedId': feedId,
            'createdAt': FieldValue.serverTimestamp(),
          }),
        ]);

      }
    } catch (e) {
      // 롤백
      setState(() {
        final currentLiked = likedStatus[feedId] ?? false;
        likedStatus[feedId] = !currentLiked;
        likeCounts[feedId] = (likeCounts[feedId] ?? 0) + (currentLiked ? -1 : 1);
      });
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
    FocusManager.instance.primaryFocus?.unfocus();

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId);

      await docRef.update({'mainCoordiId': newMainCoordiId});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대표 코디가 성공적으로 설정되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('대표 코디 설정 중 오류 발생: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void showShareBottomSheet(BuildContext context, String feedId) {
    FocusManager.instance.primaryFocus?.unfocus();

    final url = 'wearly://deeplink/feedid?id=$feedId';
    final qrKey = GlobalKey();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('피드 공유하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              RepaintBoundary(
                key: qrKey,
                child: QrImageView(
                  data: url,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              SelectableText(url, maxLines: 3),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await Future.delayed(Duration(milliseconds: 300));

                        RenderRepaintBoundary boundary =
                        qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                        Uint8List pngBytes = byteData!.buffer.asUint8List();

                        final tempDir = await getTemporaryDirectory();
                        final file = await File('${tempDir.path}/qr.png').create();
                        await file.writeAsBytes(pngBytes);

                        await Share.shareXFiles([XFile(file.path)], text: 'QR 코드로 공유된 피드입니다');
                      } catch (e) {
                        print('QR 공유 실패: $e');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR 공유 중 오류 발생')));
                      }
                    },
                    child: Text('QR 공유'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('링크가 복사되었습니다')));
                    },
                    child: Text('링크 복사'),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> deleteFeed(String feedId) async {

    final confirm = await showDialogMessage(
      context,
      '삭제 하시겠습니까?',
      confirmCancel: true,
    );

    if (confirm != true) return;

    try {
      await fs.collection('feeds').doc(feedId).delete();

      setState(() {
        feeds.removeWhere((feed) => feed['id'] == feedId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드가 삭제되었습니다')),
      );
    } catch (e) {
      print('피드 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드 삭제 중 오류가 발생했습니다')),
      );
    }
  }

  Future<void> openEditPostPage(BuildContext context, String feedId) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditPostPage(feedId: feedId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;
    Color Grey = customColors?.textGrey ?? Colors.grey;
    Color White = customColors?.textWhite ?? Colors.white;
    Color Black = customColors?.textBlack ?? Colors.black;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        // 필터 해제용 플로팅 액션 버튼 (우하단)
        floatingActionButton: filteredTags.isNotEmpty
            ? FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              filteredTags.clear();
              isLoading = true;
            });
            fetchFeedsWithWriter();
          },
          label: Text('필터 해제'),
          icon: Icon(Icons.clear),
        )
            : null,
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: () async {
                await fetchFeedsWithWriter();
              },
              child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),  // 이게 핵심!
              padding: const EdgeInsets.all(12),
              itemCount: feeds.where((feed) => feed['isPublic'] != false).length,
              itemBuilder: (context, index) {
              final visibleFeeds = feeds.where((feed) => feed['isPublic'] != false).toList();
              final feed = visibleFeeds[index];

              return Padding(
                key: ValueKey(feed['id']),
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
                                onOpened: (){
                                  FocusManager.instance.primaryFocus?.unfocus();
                                },
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    openEditPostPage(context,feed['id']);
                                  } else if (value == 'del') {
                                    deleteFeed(feed['id']);
                                  } else if (value == 'main') {
                                    updateMainCoordiId(feed['id']);
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
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
                              feed['temperature']?.toString() ?? '',
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
                              child: ImageCarouselCard(
                                key: ValueKey(feed['id']),
                                cardcolor : subColor,
                                pointColor : pointColor,
                                imageUrls:
                                (feed['imageUrls'] as List<dynamic>)
                                    .map((e) => e.toString())
                                    .toList(),
                                profileImageUrl:
                                feed['writerInfo']?['profileImage'] ?? '',
                                userName:
                                feed['writerInfo']?['nickname'] ?? '닉네임',
                                onUserTap: () {
                                  final docId = feed['writerInfo']?['docId'] ?? '';
                                  widget.onUserTap(docId);
                                },
                                onShareTap: () {
                                  final feedId = feed['id']?.toString() ?? '';
                                  showShareBottomSheet(context, feedId);
                                },
                                isLiked: likedStatus[feed['id']] ?? false,
                                likeCount: likeCounts[feed['id']] ?? 0,
                                onLikeToggle: () {
                                  toggleLike(feed);
                                },
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        Text(feed['content'] ?? '', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 12),
                        feed['tags'] != null && feed['tags'] is List
                            ? Wrap(
                          spacing: 6.0,
                          runSpacing: 2.0,
                          children: (feed['tags'] as List)
                              .map(
                                (tag) => GestureDetector(
                              onTap: () {
                                toggleTagFilter(tag.toString());
                              },
                              child: Chip(
                                label: Text(
                                  tag.toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: filteredTags.contains(tag)
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                backgroundColor: filteredTags.contains(tag)
                                    ? Colors.blueAccent
                                    : Colors.grey.shade200,
                                shape: StadiumBorder(),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 0,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          )
                              .toList(),
                        )
                            : SizedBox.shrink(),
                        SizedBox(height: 6),
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

                        CommentSection(
                          key: ValueKey("comment_${feed['id']}"),
                          feedId: feed['id'],
                          currentUserId: currentUserId,
                          onUserTap: widget.onUserTap,
                        ),
                      ],
                    ),
                  ),
                ),
              );
                      },
                    ),
            ),
      ),
    );
  }
}