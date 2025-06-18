import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main/widget/settings_page.dart';
import 'package:w2wproject/main/widget/user_edit_page.dart';
import 'detail_page.dart';
import 'package:intl/intl.dart';

class MyPageTab extends StatefulWidget {
  final String? userId;

  const MyPageTab({Key? key, this.userId, required Function onUserTap}) : super(key: key);

  @override
  State<MyPageTab> createState() => _MyPageWidgetState();
}

Future<String?> getSavedUserId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString('userId');
}


class _MyPageWidgetState extends State<MyPageTab> {
  bool isExpanded = true;
  bool showDetail = false;
  String? selectedFeedId;
  bool isLoading = true;




  String currentUserId = 'XHIEfJKfSqhT7SqfZXoX';
  final FirebaseFirestore fs = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> userProfiles = [
    {
      "userId": "XHIEfJKfSqhT7SqfZXoX",
      "name": "윤사나",
      "profileImages": ['assets/w1.jpg', 'assets/w3.jpg', 'assets/w5.jfif'],
      "bio": "안녕하세요. 윤사나 입니다.",
      "hashtags": "#캐주얼 #반팔",
      "mainProfileImage": "assets/w2.jpg"
    },
    {
      "userId": "user456",
      "name": "김지은",
      "profileImages": ['assets/w7.jfif', 'assets/w8.jfif'],
      "bio": "반가워요. 지은이에요!",
      "hashtags": "#댄디 #봄코디",
      "mainProfileImage": "assets/w9.jfif"
    },
  ];

  final PageController _pageController = PageController(viewportFraction: 0.85);

  // 월별로 그룹화된 피드 아이템
  Map<String, List<Map<String, dynamic>>> feedItemsByMonth = {};

  Future<void> fetchFeeds() async {
    try {
      final snapshot = await fs.collection('feeds').orderBy('cdatetime', descending: true).get();
      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;

        if (data['cdatetime'] is Timestamp) {
          DateTime date = (data['cdatetime'] as Timestamp).toDate();
          String monthKey = DateFormat('yyyy년 M월').format(date);

          feedItemsByMonth[monthKey] ??= [];
          feedItemsByMonth[monthKey]!.add(data);
        }

        return data;
      }).toList();

      // 최신 월부터 내림차순 정렬
      feedItemsByMonth = Map.fromEntries(
        feedItemsByMonth.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key)),
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching feeds: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchFeeds();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    String? userId = await getSavedUserId();
    setState(() {
      currentUserId = userId!;
      print("currentUserId====>$currentUserId");
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void openDetail(String feedId) {
    setState(() {
      selectedFeedId = feedId;
      showDetail = true;
    });
  }


  void closeDetail() {
    setState(() {
      showDetail = false;
    });
  }

  Map<String, dynamic> getUserProfile(String userId) {
    return userProfiles.firstWhere(
          (profile) => profile['userId'] == userId,
      orElse: () => userProfiles[0],
    );
  }

  void openSettingsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
  }

  void openUserEditPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserEditPage(userId: currentUserId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String viewedUserId = widget.userId ?? currentUserId;
    final bool isOwnPage = viewedUserId == currentUserId;
    final Map<String, dynamic> profile = getUserProfile(viewedUserId);

    final theme = Theme.of(context);
    final bottomNavTheme = theme.bottomNavigationBarTheme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final navBackgroundColor = bottomNavTheme.backgroundColor ?? theme.primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 프로필 UI (생략 안함)
            AnimatedContainer(
              duration: Duration(milliseconds: 200),
              width: screenWidth,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: unselectedItemColor.withOpacity(0.95),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: navBackgroundColor, width: 7)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: showDetail
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(profile["mainProfileImage"]),
                        ),
                        SizedBox(width: 12),
                        Text(profile["name"], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: selectedItemColor)),
                      ],
                    )
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: AssetImage(profile["mainProfileImage"]),
                        ),
                        SizedBox(height: 8),
                        Text(profile["name"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selectedItemColor)),
                        AnimatedCrossFade(
                          duration: Duration(milliseconds: 300),
                          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                          firstChild: Column(
                            children: [
                              SizedBox(height: 8),
                              SizedBox(
                                height: 360,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: profile["profileImages"].length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(profile["profileImages"][index], fit: BoxFit.cover),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(profile["bio"], style: TextStyle(color: selectedItemColor)),
                              Text(profile["hashtags"], style: TextStyle(color: Colors.blue)),
                            ],
                          ),
                          secondChild: SizedBox.shrink(),
                        ),
                        TextButton(
                          onPressed: () => setState(() => isExpanded = !isExpanded),
                          child: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 32, color: selectedItemColor),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 8,
                    child: isOwnPage
                        ? Row(
                      children: [
                        _buildIconBtn('assets/common/person_edit.png', () {openUserEditPage(context);}),
                        _buildIconBtn(Icons.settings, (){ openSettingsPage(context);}),
                      ],
                    )
                        : ElevatedButton(
                      onPressed: () {},
                      child: Text("팔로우"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink[200],
                        foregroundColor: Colors.white,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 피드 목록
            Expanded(
              child: IndexedStack(
                index: showDetail ? 1 : 0,
                children: [
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                    child: Column(
                      children: feedItemsByMonth.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                entry.key,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selectedItemColor),
                              ),
                            ),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              itemCount: entry.value.length,
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.8,
                              ),
                              itemBuilder: (context, index) {
                                final item = entry.value[index];
                                final imageUrl = item["imageUrls"] != null &&
                                    item["imageUrls"].isNotEmpty
                                    ? item["imageUrls"][0]
                                    : '';

                                return GestureDetector(
                                  onTap: () => openDetail(item['id']),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[300],
                                    ),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // 배경 이미지
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              8),
                                          child: imageUrl != ''
                                              ? Image.network(
                                              imageUrl, fit: BoxFit.cover)
                                              : Image.asset('assets/noimg.jpg',
                                              fit: BoxFit.cover),
                                        ),

                                        // 우상단 온도 & 좌하단 기분 텍스트
                                        if ((item["feeling"]
                                            ?.toString()
                                            .isNotEmpty ?? false) ||
                                            (item["temperature"]
                                                ?.toString()
                                                .isNotEmpty ?? false))
                                          Positioned.fill(
                                            child: Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Stack(
                                                children: [
                                                  if (item["temperature"]
                                                      ?.toString()
                                                      .isNotEmpty ?? false)
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black45,
                                                          borderRadius: BorderRadius
                                                              .circular(4),
                                                        ),
                                                        child: Text(
                                                          '${item["temperature"]?.toString()}℃',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 12),
                                                        ),
                                                      ),
                                                    ),
                                                  if (item["feeling"]
                                                      ?.toString()
                                                      .isNotEmpty ?? false)
                                                    Positioned(
                                                      bottom: 0,
                                                      left: 0,
                                                      child: Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black45,
                                                          borderRadius: BorderRadius
                                                              .circular(4),
                                                        ),
                                                        child: Text(
                                                          item["feeling"],
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white,
                                                              fontSize: 12),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  if (selectedFeedId != null)
                    DetailPage(
                      key: ValueKey(selectedFeedId),
                      feedId: selectedFeedId!,
                      currentUserId : currentUserId,
                      onBack: closeDetail,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(dynamic icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: icon is String
            ? Padding(padding: EdgeInsets.all(4), child: Image.asset(icon, color: Colors.black))
            : Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }
}
