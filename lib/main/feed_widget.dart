import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'AdItemAddPage.dart';
import 'mypage_tab.dart';

// 관리자 UID 상수로 정의
const String adminUid = '2ea5nKtz9tX2LYgzaVmFfarAZGV2';

// (1) 피드 추천 영역
class TodayFeedSection extends StatefulWidget {
  final List<String> tagList;
  final void Function(String userId) onUserTap;
  final void Function(String feedId) onFeedTap; // 상세 페이지 이동 콜백 추가

  const TodayFeedSection({
    Key? key,
    required this.tagList,
    required this.onUserTap,
    required this.onFeedTap,
  }) : super(key: key);

  @override
  State<TodayFeedSection> createState() => _TodayFeedSectionState();
}

class _TodayFeedSectionState extends State<TodayFeedSection> {
  List<Map<String, dynamic>> feedList = [];
  bool isLoading = false;

  // 펼쳐진 태그 인덱스 저장용
  Set<int> expandedTagIdx = {};

  @override
  void didUpdateWidget(covariant TodayFeedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tagList.join() != oldWidget.tagList.join()) {
      loadFeeds();
    }
  }

  @override
  void initState() {
    super.initState();
    loadFeeds();
  }

  Future<void> loadFeeds() async {
    setState(() {
      isLoading = true;
      feedList = [];
      expandedTagIdx.clear();
    });

    if (widget.tagList.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final feedSnapshot = await FirebaseFirestore.instance.collection('feeds').get();
    List<Map<String, dynamic>> allFeeds = [];

    for (var doc in feedSnapshot.docs) {
      var feedData = doc.data();
      feedData['feedId'] = doc.id;

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(feedData['writeid'])
          .get();
      var userData = userDoc.data();

      feedData['profileImgUrl'] = userData?['profileImageUrl'];
      feedData['nickname'] = userData?['nickname'];
      feedData['writeid'] = feedData['writeid'];

      allFeeds.add(feedData);
    }

    // 태그 매칭
    List<Map<String, dynamic>> matchedFeeds = allFeeds.where((feed) {
      if (feed['tags'] == null) return false;
      List<dynamic> tags = feed['tags'];
      if (tags.isEmpty) return false;
      return tags.any((t) =>
      widget.tagList.contains(t) ||
          widget.tagList.contains('#$t') ||
          widget.tagList.any((tag) => tag.replaceAll('#', '') == t.toString().replaceAll('#', ''))
      );
    }).toList();

    matchedFeeds.shuffle();

    setState(() {
      feedList = matchedFeeds;
      isLoading = false;
      expandedTagIdx.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              text: TextSpan(
                text: '오늘 날씨에 어울리는 코디',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 3, bottom: 7),
            child: Text(
              widget.tagList.join(' '),
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isLoading)
            Container(
              height: 220,
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            )
          else if (feedList.isEmpty)
            Container(
              height: 220,
              alignment: Alignment.center,
              child: Text('추천 태그에 맞는 피드가 없습니다.'),
            )
          else
            SizedBox(
              height: 430,
              child: PageView.builder(
                itemCount: feedList.length,
                controller: PageController(viewportFraction: 0.81),
                itemBuilder: (context, idx) {
                  final feed = feedList[idx];
                  final profileImg = feed['profileImgUrl'];
                  final feedImg = (feed['imageUrls'] as List?)?.isNotEmpty == true ? feed['imageUrls'][0] : null;
                  final nickname = feed['nickname'] ?? '알 수 없음';
                  final tags = (feed['tags'] as List?) ?? [];

                  // 태그 3개 초과시 펼침 여부
                  final isExpanded = expandedTagIdx.contains(idx);
                  final tagsToShow = isExpanded ? tags : tags.take(3).toList();

                  return Padding(
                    padding: const EdgeInsets.only(left: 7, right: 7, bottom: 4, top: 4),
                    child: Card(
                      elevation: 7,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey[200]!, width: 1.4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 프로필 부분(마이페이지 이동)
                            Padding(
                              padding: const EdgeInsets.only(top: 16, left: 14, bottom: 7),
                              child: GestureDetector(
                                onTap: () => widget.onUserTap(feed['writeid']),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.grey[300]!, width: 1.5),
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 15,
                                        backgroundImage: profileImg == null
                                            ? AssetImage('assets/profile1.jpg')
                                            : (profileImg.toString().startsWith('http')
                                            ? NetworkImage(profileImg)
                                            : AssetImage(profileImg)) as ImageProvider,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '$nickname 님',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 피드 이미지 부분(상세페이지 이동)
                            Center(
                              child: GestureDetector(
                                onTap: () => widget.onFeedTap(feed['feedId']), // 상세페이지로
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 2),
                                  width: 210,
                                  height: 280,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(19),
                                    color: Colors.black26,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(19),
                                    child: feedImg != null
                                        ? Image.network(feedImg, fit: BoxFit.cover)
                                        : Icon(Icons.image, size: 62, color: Colors.white30),
                                  ),
                                ),
                              ),
                            ),
                            // 태그 영역(칩 스타일) + 더보기/접기 버튼
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 9, 0, 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Wrap(
                                      spacing: 7,
                                      runSpacing: 3,
                                      children: tagsToShow.map<Widget>((tag) =>
                                          Container(
                                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 9),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFF2F4F8),
                                              borderRadius: BorderRadius.circular(11),
                                            ),
                                            child: Text(
                                              '$tag',
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12.7,
                                              ),
                                            ),
                                          )
                                      ).toList(),
                                    ),
                                  ),
                                  // 태그가 3개를 초과하면 '더보기' 버튼 표시
                                  if (tags.length > 3)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          if (isExpanded) {
                                            expandedTagIdx.remove(idx);
                                          } else {
                                            expandedTagIdx.add(idx);
                                          }
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 3),
                                        child: Text(
                                          isExpanded ? '접기' : '더보기',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
// (2) 광고 배너 영역 - 상단 1개, 하단 썸네일 N개
class ZigzagBannerSection extends StatefulWidget {
  final List<String> tagList;
  const ZigzagBannerSection({Key? key, required this.tagList}) : super(key: key);

  @override
  State<ZigzagBannerSection> createState() => _ZigzagBannerSectionState();
}

class _ZigzagBannerSectionState extends State<ZigzagBannerSection> {
  List<Map<String, dynamic>> adList = [];
  bool isLoading = true;
  int selectedIdx = 0;

  @override
  void initState() {
    super.initState();
    loadAds();
  }

  @override
  void didUpdateWidget(covariant ZigzagBannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tagList.join() != oldWidget.tagList.join()) {
      loadAds();
    }
  }

  Future<void> loadAds() async {
    setState(() {
      isLoading = true;
      adList = [];
      selectedIdx = 0;
    });

    final adSnap = await FirebaseFirestore.instance.collection('adItems').get();
    List<Map<String, dynamic>> allAds = [];

    for (var doc in adSnap.docs) {
      var adData = doc.data();
      allAds.add(adData);
    }

    // 태그 매칭: widget.tagList와 ad['tagId'] 교집합 1개라도 있으면 노출
    List<Map<String, dynamic>> matchedAds = allAds.where((ad) {
      if (ad['tagId'] == null) return false;
      List<dynamic> adTags = ad['tagId'] is List ? ad['tagId'] : [ad['tagId']];
      return adTags.any((t) =>
      widget.tagList.contains(t) ||
          widget.tagList.contains('#$t') ||
          widget.tagList.any((tag) => tag.replaceAll('#', '') == t.toString().replaceAll('#', ''))
      );
    }).toList();

    matchedAds.shuffle();

    setState(() {
      adList = matchedAds;
      isLoading = false;
      selectedIdx = 0;
    });
  }

  void _launchLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(0xffe15eef),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      "Ad",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  "광고",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.add_circle_outline, color: Color(0xffe15eef), size: 28),
                  tooltip: '광고 업로드',
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdItemAddPage()));
                  },
                ),
              ],
            ),
          ),
          if (isLoading)
            SizedBox(height: 270, child: Center(child: CircularProgressIndicator()))
          else if (adList.isEmpty)
            SizedBox(height: 270, child: Center(child: Text('추천 태그에 맞는 광고가 없습니다.')))
          else ...[
              GestureDetector(
                onTap: () {
                  if (adList[selectedIdx]['link'] != null) {
                    _launchLink(adList[selectedIdx]['link']);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: AspectRatio(
                    aspectRatio: 0.78,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          adList[selectedIdx]['photoUrl'] != null
                              ? Image.network(
                            adList[selectedIdx]['photoUrl'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.image, size: 80, color: Colors.white30),
                          )
                              : Icon(Icons.image, size: 80, color: Colors.white30),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.40),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    adList[selectedIdx]['itemName'] ?? '',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Icon(Icons.open_in_new, color: Colors.white70, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 135,
                margin: EdgeInsets.only(top: 14, left: 10, right: 10, bottom: 16), // 하단 margin 넉넉히
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: adList.length,
                  itemBuilder: (context, idx) {
                    final ad = adList[idx];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIdx = idx;
                        });
                      },
                      child: Container(
                        width: 85,
                        margin: EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: selectedIdx == idx ? Color(0xffe15eef) : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(13),
                                child: AspectRatio(
                                  aspectRatio: 1,
                                  child: ad['photoUrl'] != null
                                      ? Image.network(
                                    ad['photoUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(Icons.image, color: Colors.white30),
                                  )
                                      : Icon(Icons.image, color: Colors.white30),
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              ad['itemName'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.tag,
                                  size: 15,
                                  color: Colors.grey[600],
                                ),
                                SizedBox(width: 4),
                                Text(
                                  (ad['tagId'] is List && ad['tagId'].isNotEmpty)
                                      ? ad['tagId'][0]
                                      : (ad['tagId'] ?? ''),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
        ],
      ),
    );
  }
}
// (3) 위클리 랭킹
class WeeklyBestWidget extends StatefulWidget {
  final void Function(String userId) onUserTap;

  const WeeklyBestWidget({super.key, required this.onUserTap});

  @override
  State<WeeklyBestWidget> createState() => _WeeklyBestWidgetState();
}

class _WeeklyBestWidgetState extends State<WeeklyBestWidget> {
  List<Map<String, dynamic>> weeklyBest = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadWeeklyBest();
  }

  Future<void> loadWeeklyBest() async {
    final feedsSnap = await FirebaseFirestore.instance.collection('feeds').get();

    List<Map<String, dynamic>> feedList = [];
    for (var doc in feedsSnap.docs) {
      var feedData = doc.data();
      var feedId = doc.id;

      // 좋아요 수
      var likesSnap = await FirebaseFirestore.instance
          .collection('feeds')
          .doc(feedId)
          .collection('likes')
          .get();
      int likeCount = likesSnap.docs.length;

      // 유저 정보
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(feedData['writeid'])
          .get();
      var userData = userDoc.data();

      feedList.add({
        ...feedData,
        'feedId': feedId,
        'likeCount': likeCount,
        'profileImgUrl': userData?['profileImageUrl'],
        'nickname': userData?['nickname'],
        'writeid': feedData['writeid'],
      });
    }

    feedList.sort((a, b) => b['likeCount'].compareTo(a['likeCount']));
    setState(() {
      weeklyBest = feedList.take(3).toList();
      loading = false;
    });
  }

  String getCurrentWeekRange() {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    DateTime sunday = monday.add(const Duration(days: 6));
    final formatter = DateFormat('yyyy.MM.dd');
    return '${formatter.format(monday)} ~ ${formatter.format(sunday)}';
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Center(child: CircularProgressIndicator());
    }
    if (weeklyBest.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(18.0),
        child: Text('이번주 인기 피드가 없습니다.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'WEEKLY WEARLY BEST',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            getCurrentWeekRange(),
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (weeklyBest.length > 0)
              _buildRankingBox(weeklyBest[0], 1, 160, 30),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (weeklyBest.length > 1)
              _buildRankingBox(weeklyBest[1], 2, 100, 22, margin: EdgeInsets.only(top: 10, right: 14)),
            if (weeklyBest.length > 2)
              _buildRankingBox(weeklyBest[2], 3, 100, 22, margin: EdgeInsets.only(top: 10, left: 14)),
          ],
        ),
        SizedBox(height: 28),
      ],
    );
  }

  Widget _buildRankingBox(
      Map<String, dynamic> feed,
      int rank,
      double imgSize,
      double borderRadius, {
        EdgeInsets? margin,
      }) {
    final profileImg = feed['profileImgUrl'];
    final nickname = feed['nickname'] ?? '익명';
    final likeCount = feed['likeCount'] ?? 0;
    final imageUrls = (feed['imageUrls'] as List?) ?? [];
    final feedImg = imageUrls.isNotEmpty ? imageUrls[0] : null;
    final writeid = feed['writeid'];

    return GestureDetector(
      onTap: () => widget.onUserTap(writeid),
      child: Column(
        children: [
          Container(
            width: imgSize,
            height: imgSize,
            margin: margin,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: Colors.grey[200],
            ),
            child: feedImg != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.network(feedImg, fit: BoxFit.cover),
            )
                : Icon(Icons.image, size: imgSize / 2, color: Colors.white30),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => widget.onUserTap(writeid),
                child: Container(
                  width: 38,
                  height: 38,
                  margin: EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!, width: 1.4),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: profileImg != null && profileImg.toString().startsWith('http')
                        ? NetworkImage(profileImg)
                        : AssetImage('assets/profile1.jpg') as ImageProvider,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => widget.onUserTap(writeid),
                child: Text(
                  nickname,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              SizedBox(width: 7),
              Icon(Icons.favorite, color: Colors.pink, size: 16),
              SizedBox(width: 3),
              Text('$likeCount', style: TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
