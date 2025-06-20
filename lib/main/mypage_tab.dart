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
  bool isUserLoading = true;
  bool _isFollowing = false;


  String currentUserId = '';
  String viewedUserId = '';

  final FirebaseFirestore fs = FirebaseFirestore.instance;

  List<Map<String, dynamic>> userProfiles = [];
  Map<String, dynamic> mainCoordiFeed = {};

  final PageController _pageController = PageController(viewportFraction: 0.85);

  // 월별로 그룹화된 피드 아이템
  Map<String, List<Map<String, dynamic>>> feedItemsByMonth = {};

  Future<void> fetchFeeds() async {
    //print('fetchstart==>>>$viewedUserId');
    try {
      feedItemsByMonth.clear();

      //currentUserId
      final snapshot = await fs
          .collection('feeds')
          .where('writeid', isEqualTo: viewedUserId) // 조건 추가
          .orderBy('cdatetime', descending: true)       // 정렬 기준
          .get();
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
    _loadUserId();

  }

  Future<void> _loadUserId() async {
    String? userId = await getSavedUserId();
    setState(() {
      currentUserId = userId!;
      if ( widget.userId == null || widget.userId == '' ){
        viewedUserId = userId!;
      } else {
        viewedUserId = widget.userId!;
      }
      //print("currentUserId====>$currentUserId");
      fetchCurrentUserProfile();
    });
  }

  Future<void> fetchCurrentUserProfile() async {
    if (viewedUserId == null) return; // null 체크

    viewedUserId = widget.userId ?? currentUserId;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(viewedUserId)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        final userId = docSnapshot.id;
        data['id'] = userId;

        setState(() {
          userProfiles = [data];
          isUserLoading = false;
        });

        // 🔽 mainCoordiId 가져와서 feeds에서 문서 가져오기
        final mainCoordiId = data['mainCoordiId'];
        if (mainCoordiId != null && mainCoordiId.toString().trim().isNotEmpty) {
          try {
            final feedSnapshot = await FirebaseFirestore.instance
                .collection('feeds')
                .doc(mainCoordiId)
                .get();

            if (feedSnapshot.exists) {
              final feedData = feedSnapshot.data()!;
              feedData['id'] = feedSnapshot.id;

              // 🔽 리스트에 추가
              setState(() {
                mainCoordiFeed = feedData;
              });
            }
          } catch (e) {
            print('feeds 문서 가져오기 실패: $e');
          }
        }

        // 🔽 팔로우 상태 확인
        if (viewedUserId != currentUserId) {
          try {
            final targetUserSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(viewedUserId)
                .get();

            if (targetUserSnapshot.exists) {
              final targetData = targetUserSnapshot.data()!;
              List<dynamic> followers = targetData['follower'] ?? [];

              setState(() {
                _isFollowing = followers.contains(currentUserId);
              });
            }
          } catch (e) {
            print('팔로우 상태 확인 실패: $e');
          }
        }

        fetchFeeds();
      } else {
        setState(() {
          userProfiles = [];
          isUserLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isUserLoading = false;
      });
      print('유저 프로필 불러오기 실패: $e');
    }
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
          (profile) => profile['id'] == userId,
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



  Future<void> _toggleFollow() async {

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final targetUserRef = FirebaseFirestore.instance.collection('users').doc(viewedUserId);

    if (_isFollowing) {
      await currentUserRef.update({
        'following': FieldValue.arrayRemove([viewedUserId])
      });
      await targetUserRef.update({
        'follower': FieldValue.arrayRemove([currentUserId])
      });
    } else {
      await currentUserRef.update({
        'following': FieldValue.arrayUnion([viewedUserId])
      });
      await targetUserRef.update({
        'follower': FieldValue.arrayUnion([currentUserId])
      });
    }

    setState(() {
      _isFollowing = !_isFollowing;
    });

    await fetchCurrentUserProfile();
  }


  @override
  Widget build(BuildContext context) {

    if (isUserLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userProfiles.isEmpty) {
      return const Center(child: Text("프로필 데이터를 불러올 수 없습니다."));
    }


    //print("widget.userId ==>${widget.userId }");
    //print("currentUserId ==>${currentUserId }");
    //print("viewedUserId==>$viewedUserId");

    final bool isOwnPage = viewedUserId == currentUserId;

    final Map<String, dynamic> profile = getUserProfile(viewedUserId);

    //print("profile ==> $profile");
    final theme = Theme.of(context);
    final bottomNavTheme = theme.bottomNavigationBarTheme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final navBackgroundColor = bottomNavTheme.backgroundColor ?? theme.primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;
    final screenWidth = MediaQuery.of(context).size.width;
    final followerCount = (profile['follower'] )?.length ?? 0;
    final followingCount = (profile['following'] )?.length ?? 0;



    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 프로필 UI
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
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 팔로워 수
                            Text(
                              '팔로워 ${followerCount ?? 0}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 8),

                            // 팔로잉 수
                            Text(
                              '팔로잉 ${followingCount ?? 0}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                            const SizedBox(width: 12),

                            // 프로필 이미지
                            if (profile["profileImage"] != null &&
                                profile["profileImage"].toString().isNotEmpty)
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: NetworkImage(profile["profileImage"]),
                              )
                            else
                              const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                            const SizedBox(width: 12),

                            // 닉네임
                            Text(
                              profile["nickname"].length > 6
                                  ? '${profile["nickname"].substring(0, 6)}...'
                                  : profile["nickname"],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: selectedItemColor,
                              ),
                            ),
                          ],
                        )
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 좌측 상단 팔로워/팔로잉 표시
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Text(
                                    '팔로워',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    '팔로잉',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    '${followerCount ?? 0}',
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                  const SizedBox(width: 32),
                                  Text(
                                    '${followingCount ?? 0}',
                                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // 프로필 이미지 (중앙 정렬 유지)
                        Center(
                          child: Column(
                            children: [
                              if (profile["profileImage"] != null &&
                                  profile["profileImage"].toString().isNotEmpty)
                                CircleAvatar(
                                  radius: 32,
                                  backgroundImage: NetworkImage(profile["profileImage"]),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                profile["nickname"] ?? '',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: selectedItemColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 피드 섹션
                        buildExpandedFeedSection(
                          imageUrls: mainCoordiFeed["imageUrls"] ?? [],
                          profile: profile,
                          isExpanded: isExpanded,
                          selectedItemColor: selectedItemColor,
                          pageController: _pageController,
                        ),

                        // 펼치기 버튼
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() => isExpanded = !isExpanded),
                            child: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 32,
                              color: selectedItemColor,
                            ),
                          ),
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
                        _buildIconBtn('assets/common/person_edit.png', () {
                          openUserEditPage(context);
                        }),
                        _buildIconBtn(Icons.settings, () {
                          openSettingsPage(context);
                        }),
                      ],
                    )
                        : ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? selectedItemColor : unselectedItemColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // 내부 여백
                        minimumSize: Size(0, 0), // 기본 크기 제한 없음
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap, // 터치 영역 최소화
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isFollowing ? '팔로우 중' : '팔로우',
                        style: const TextStyle(fontSize: 12), // 글자 크기 축소
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 피드 목록 영역
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
                                final imageUrl = item["imageUrls"] != null && item["imageUrls"].isNotEmpty
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
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: imageUrl != ''
                                              ? Image.network(imageUrl, fit: BoxFit.cover)
                                              : Image.asset('assets/noimg.jpg', fit: BoxFit.cover),
                                        ),
                                        if ((item["feeling"]?.toString().isNotEmpty ?? false) ||
                                            (item["temperature"]?.toString().isNotEmpty ?? false))
                                          Positioned.fill(
                                            child: Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Stack(
                                                children: [
                                                  if (item["temperature"]?.toString().isNotEmpty ?? false)
                                                    Positioned(
                                                      top: 0,
                                                      right: 0,
                                                      child: _buildOverlayText('${item["temperature"]}℃'),
                                                    ),
                                                  if (item["feeling"]?.toString().isNotEmpty ?? false)
                                                    Positioned(
                                                      bottom: 0,
                                                      left: 0,
                                                      child: _buildOverlayText(item["feeling"]),
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
                      currentUserId: currentUserId,
                      onBack: closeDetail,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    ;
  }


  Widget _buildOverlayText(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 12),
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

Widget buildExpandedFeedSection({
  required List<dynamic> imageUrls,
  required Map<String, dynamic> profile,
  required bool isExpanded,
  required Color selectedItemColor,
  required PageController pageController,
}) {
  return AnimatedCrossFade(
    duration: Duration(milliseconds: 300),
    crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    firstChild: Column(
      children: [
        SizedBox(height: 8),
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: pageController,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrls[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Text(profile["bio"] ?? '', style: TextStyle(color: selectedItemColor)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: (profile["interest"] as List<dynamic>? ?? [])
              .take(3)
              .map((item) => Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.toString(),
              style: TextStyle(color: Colors.blue),
            ),
          ))
              .toList(),
        )
      ],
    ),
    secondChild: SizedBox.shrink(),
  );
}

