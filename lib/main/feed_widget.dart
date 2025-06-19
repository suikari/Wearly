import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // 이거 추가!

// (1) 오늘 날씨에 어울리는 코디 피드 (태그 매칭)
class TodayFeedSection extends StatefulWidget {
  final List<String> tagList;
  const TodayFeedSection({super.key, required this.tagList});

  @override
  State<TodayFeedSection> createState() => _TodayFeedSectionState();
}

class _TodayFeedSectionState extends State<TodayFeedSection> {
  List<Map<String, dynamic>> feedList = [];

  @override
  void didUpdateWidget(covariant TodayFeedSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tagList != oldWidget.tagList) {
      loadFeeds();
    }
  }

  @override
  void initState() {
    super.initState();
    loadFeeds();
  }

  Future<void> loadFeeds() async {
    if (widget.tagList.isEmpty) {
      setState(() => feedList = []);
      return;
    }
    final feedSnapshot = await FirebaseFirestore.instance.collection('feeds').get();
    List<Map<String, dynamic>> allFeeds = feedSnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();

    List<Map<String, dynamic>> matchedFeeds = allFeeds.where((feed) {
      if (feed['tags'] == null) return false;
      List<dynamic> tags = feed['tags'];
      return tags.any((t) => widget.tagList.contains('#$t') || widget.tagList.contains(t));
    }).toList();

    matchedFeeds.shuffle();
    setState(() {
      feedList = matchedFeeds;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RichText(
              text: TextSpan(
                text: '오늘 날씨에 어울리는 코디',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black,
                  letterSpacing: 0.2,
                  height: 1.1,
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
                letterSpacing: 0.1,
              ),
            ),
          ),
          if (feedList.isEmpty)
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
                            // 프로필/닉네임
                            Padding(
                              padding: const EdgeInsets.only(top: 16, left: 14, bottom: 7),
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
                                          : (profileImg.startsWith('http')
                                          ? NetworkImage(profileImg)
                                          : AssetImage(profileImg)) as ImageProvider,
                                      onBackgroundImageError: (_, __) {},
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
                            // 피드 이미지
                            Center(
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
                                      ? Image.network(
                                    feedImg,
                                    fit: BoxFit.cover,
                                  )
                                      : Icon(Icons.image, size: 62, color: Colors.white30),
                                ),
                              ),
                            ),
                            // 태그
                            Padding(
                              padding: const EdgeInsets.fromLTRB(15, 9, 0, 6),
                              child: Wrap(
                                spacing: 7,
                                children: tags.take(3).map<Widget>((tag) => Text(
                                  '$tag',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12.7,
                                  ),
                                )).toList(),
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

// (2) 광고2 (zigzag 배너)
class ZigzagBannerSection extends StatefulWidget {
  const ZigzagBannerSection({super.key});
  @override
  State<ZigzagBannerSection> createState() => _ZigzagBannerSectionState();
}

class _ZigzagBannerSectionState extends State<ZigzagBannerSection> {
  final List<Map<String, String>> zigzagThumbs = [
    {
      "img": "assets/ad_banner2.jpg",
      "brand": "바이보니",
    },
    {
      "img": "assets/ad_banner3.jpg",
      "brand": "moment.",
    },
    {
      "img": "assets/ad_banner4.jpg",
      "brand": "써스데이아일랜드",
    },
  ];
  int currentPage = 0;
  final PageController _pageController = PageController();

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
                      "Z",
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
                  "광고2",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                Icon(Icons.two_k, size: 22, color: Colors.grey[700]),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: AspectRatio(
              aspectRatio: 0.78,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: zigzagThumbs.length,
                  onPageChanged: (idx) {
                    setState(() {
                      currentPage = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    return Image.asset(
                      zigzagThumbs[idx]["img"]!,
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 14, left: 10, right: 10),
            child: Row(
              children: List.generate(zigzagThumbs.length, (idx) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        idx,
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: currentPage == idx
                                    ? Color(0xffe15eef)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  zigzagThumbs[idx]["img"]!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            zigzagThumbs[idx]["brand"]!,
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
                                Icons.favorite_border,
                                size: 15,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                "99+",
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
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// (3) 위클리 랭킹 - 날짜 자동 표시
class WeeklyBestWidget extends StatelessWidget {
  const WeeklyBestWidget({super.key});

  // 이번 주 월요일~일요일 날짜 반환
  String getCurrentWeekRange() {
    DateTime now = DateTime.now();
    DateTime monday = now.subtract(Duration(days: now.weekday - 1));
    DateTime sunday = monday.add(const Duration(days: 6));
    final formatter = DateFormat('yyyy.MM.dd');
    return '${formatter.format(monday)} ~ ${formatter.format(sunday)}';
  }

  @override
  Widget build(BuildContext context) {
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
            // 1등
            Column(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    image: DecorationImage(
                      image: AssetImage('assets/profile1.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.orange, size: 18),
                    SizedBox(width: 4),
                    Text('옆집악마', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.favorite, color: Colors.pink, size: 15),
                    SizedBox(width: 2),
                    Text('1,253'),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2등
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(top: 10, right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: DecorationImage(
                      image: AssetImage('assets/profile2.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.account_circle, size: 16, color: Colors.grey),
                    SizedBox(width: 2),
                    Text(
                      'Ranez',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.favorite, color: Colors.pink, size: 13),
                    SizedBox(width: 2),
                    Text('1,111', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            // 3등
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(top: 10, left: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: DecorationImage(
                      image: AssetImage('assets/profile3.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.account_circle, size: 16, color: Colors.grey),
                    SizedBox(width: 2),
                    Text('이두나', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.favorite, color: Colors.pink, size: 13),
                    SizedBox(width: 2),
                    Text('987', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 28),
      ],
    );
  }
}
