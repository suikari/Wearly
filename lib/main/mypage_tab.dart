import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main/widget/settings_page.dart';
import 'package:w2wproject/main/widget/user_edit_page.dart';
import '../provider/custom_colors.dart';
import '../provider/theme_provider.dart';
import 'detail_page.dart';
import 'package:intl/intl.dart';

class MyPageTab extends StatefulWidget {
  final String? userId;
  final Function(String userId) onUserTap; // 여기에 추가

  const MyPageTab({Key? key, this.userId, required this.onUserTap}) : super(key: key);

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

  void _handleDragUpdate(DragUpdateDetails details) {
    if (details.delta.dy < -5 && isExpanded) {
      // 위로 스와이프 → 접기
      setState(() {
        isExpanded = false;
      });
    } else if (details.delta.dy > 5 && !isExpanded) {
      // 아래로 스와이프 → 펼치기
      setState(() {
        isExpanded = true;
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
        } else {
          setState(() {
            isExpanded = false; // 대표 피드 없으면 닫음
          });
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
    fetchFeeds();
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
    FocusManager.instance.primaryFocus?.unfocus();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsPage( userId: currentUserId )),
    );
  }

  Future<void> openUserEditPage(BuildContext context) async {
    FocusManager.instance.primaryFocus?.unfocus();

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
      await FirebaseFirestore.instance.collection('notifications').add({
        'uid': viewedUserId,
        'type': 'follow',
        'fromUid': currentUserId,
        'content': '회원님을 팔로우 합니다.',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

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
    final bool isOwnPage = viewedUserId == currentUserId;

    final Map<String, dynamic> profile = getUserProfile(viewedUserId);

    //print("profile ==> $profile");

    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;
    Color Grey = customColors?.textGrey ?? Colors.grey;
    Color White = customColors?.textWhite ?? Colors.white;
    Color Black = customColors?.textBlack ?? Colors.black;
    final themeProvider = Provider.of<ThemeProvider>(context);

    print("themeProvider>>${themeProvider.colorTheme}");
    final screenWidth = MediaQuery.of(context).size.width;
    final followerCount = (profile['follower'] )?.length ?? 0;
    final followingCount = (profile['following'] )?.length ?? 0;

    return Scaffold(
      // backgroundColor: White,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 프로필 UI
            GestureDetector(
              onVerticalDragUpdate: _handleDragUpdate,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                width: screenWidth,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: themeProvider.colorTheme != ColorTheme.blackTheme
                      ? Colors.white
                      : null,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(bottom: BorderSide(color: mainColor, width: 7)),
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
                              GestureDetector(
                                onTap: () {
                                  showFollowerFollowingDialog(
                                    context: context,
                                    userIds: List<String>.from(profile['follower'] ?? []),
                                    title: '팔로워',
                                    onUserTap: widget.onUserTap, // 이미 상위에서 받은 콜백 넘김
                                  );
                                },
                                child: Text(
                                  '팔로워 ${followerCount ?? 0}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  showFollowerFollowingDialog(
                                    context: context,
                                    userIds: List<String>.from(profile['following'] ?? []),
                                    title: '팔로잉',
                                    onUserTap: widget.onUserTap, // 이미 상위에서 받은 콜백 넘김
                                  );
                                },
                                child: Text(
                                  '팔로잉 ${followingCount ?? 0}',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                              // 팔로잉 수

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
                                  color: themeProvider.colorTheme != ColorTheme.blackTheme
                                      ? pointColor
                                      : Colors.white,
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
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        showFollowerFollowingDialog(
                                          context: context,
                                          userIds: List<String>.from(profile['follower'] ?? []),
                                          title: '팔로워',
                                          onUserTap: widget.onUserTap, // 이미 상위에서 받은 콜백 넘김
                                        );
                                      },
                                      child: Text(
                                        '팔로워',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () {
                                        showFollowerFollowingDialog(
                                          context: context,
                                          userIds: List<String>.from(profile['following'] ?? []),
                                          title: '팔로잉',
                                          onUserTap: widget.onUserTap, // 이미 상위에서 받은 콜백 넘김
                                        );
                                      },
                                      child: Text(
                                        '팔로잉',
                                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${followerCount ?? 0}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(width: 32),
                                    Text(
                                      '${followingCount ?? 0}',
                                      style: const TextStyle(fontSize: 14),
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
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.colorTheme != ColorTheme.blackTheme
                                        ? pointColor
                                        : Colors.white,

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
                            selectedItemColor: mainColor,
                            pointColor : pointColor,
                            colorTheme : themeProvider.colorTheme,
                            pageController: _pageController,
                          ),
              
                          // 펼치기 버튼
                          Center(
                            child: TextButton(
                              onPressed: () => setState(() => isExpanded = !isExpanded),
                              child: Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                size: 32,
                                color: highlightColor,
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
                          backgroundColor: _isFollowing ? pointColor : subColor,
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
            ),

            // 피드 목록 영역
            Expanded(
              child: IndexedStack(
                index: showDetail ? 1 : 0,
                children: [
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : feedItemsByMonth.isEmpty
                      ? const Center(child: Text('등록한 피드가 없습니다.'))
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
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: pointColor),
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
                      onUserTap : widget.onUserTap,
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
        style: TextStyle( fontSize: 12, color: Colors.white),
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
  required ColorTheme colorTheme,
  required Color pointColor,
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
        Text(profile["bio"] ?? '', style: TextStyle(
            color: colorTheme != ColorTheme.blackTheme
            ? pointColor
            : Colors.white, fontSize: 20)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: (profile["interest"] as List<dynamic>? ?? [])
              .take(3)
              .map((item) => Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: selectedItemColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              item.toString(),
              style: TextStyle(
                color: colorTheme != ColorTheme.blackTheme
                    ? pointColor
                    : Colors.white,
              ),
            ),
          ))
              .toList(),
        )
      ],
    ),
    secondChild: SizedBox.shrink(),
  );
}

void showFollowerFollowingDialog({
  required BuildContext context,
  required List<String> userIds,
  required String title,
  required Function(String userId) onUserTap,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return _FollowerFollowingDialogContent(
        userIds: userIds,
        title: title,
        onUserTap: onUserTap,
      );
    },
  );
}

class _FollowerFollowingDialogContent extends StatefulWidget {
  final List<String> userIds;
  final String title;
  final Function(String userId) onUserTap;

  const _FollowerFollowingDialogContent({
    required this.userIds,
    required this.title,
    required this.onUserTap,
    Key? key,
  }) : super(key: key);

  @override
  State<_FollowerFollowingDialogContent> createState() => _FollowerFollowingDialogContentState();
}

class _FollowerFollowingDialogContentState extends State<_FollowerFollowingDialogContent> with TickerProviderStateMixin {
  double _listHeight = 50; // 초기 최소 높이
  List<Map<String, dynamic>> _userInfos = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfos();
  }

  Future<void> _loadUserInfos() async {
    try {
      final users = await _fetchUserInfos(widget.userIds);
      setState(() {
        _userInfos = users;
        _isLoading = false;

        // 리스트 아이템당 60 높이 * 개수 + 여백, 최대 350으로 제한
        double calculatedHeight = _userInfos.length * 60.0 + 10;
        _listHeight = calculatedHeight.clamp(50, 350);
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 280,
            maxHeight: 400,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.userIds.length}명',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (widget.userIds.isEmpty)
                const Text("아직 아무도 없습니다.", style: TextStyle(fontSize: 14))
              else if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_hasError)
                  const Text("오류가 발생했습니다.")
                else if (_userInfos.isEmpty)
                    const Text("유저 정보를 불러올 수 없습니다.")
                  else
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: SizedBox(
                        height: _listHeight,
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _userInfos.length,
                          itemBuilder: (context, index) {
                            final user = _userInfos[index];
                            return ListTile(
                              leading: user['profileImage'] != null && user['profileImage'].toString().isNotEmpty
                                  ? CircleAvatar(backgroundImage: NetworkImage(user['profileImage']))
                                  : const CircleAvatar(child: Icon(Icons.person)),
                              title: Text(user['nickname'] ?? ''),
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onUserTap(user['id']);
                              },
                            );
                          },
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}



Future<List<Map<String, dynamic>>> _fetchUserInfos(List<String> userIds) async {
  final usersCollection = FirebaseFirestore.instance.collection('users');

  final futures = userIds.map((id) => usersCollection.doc(id).get());
  final snapshots = await Future.wait(futures);

  return snapshots
      .where((snap) => snap.exists)
      .map((snap) => {
    'id': snap.id,
    ...?snap.data(),
  })
      .toList();
}
