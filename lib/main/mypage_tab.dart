import 'package:flutter/material.dart';
import 'detail_page.dart';

class MyPageTab extends StatefulWidget {
  const MyPageTab({Key? key}) : super(key: key);

  @override
  State<MyPageTab> createState() => _MyPageWidgetState();
}

class _MyPageWidgetState extends State<MyPageTab> {
  bool isExpanded = true;
  bool showDetail = false;
  String? selectedImagePath;

  final List<String> profileImages = [
    'assets/w1.jpg',
    'assets/w3.jpg',
    'assets/w5.jfif',
  ];

  final PageController _pageController = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void openDetail(String imagePath) {
    setState(() {
      selectedImagePath = imagePath;
      showDetail = true;
    });
  }

  void closeDetail() {
    setState(() {
      showDetail = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor ?? Theme.of(context).primaryColor;
    final navBackgroundColor = bottomNavTheme.backgroundColor ?? Theme.of(context).primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;

    final screenWidth = MediaQuery.of(context).size.width;

    String currentUserId = 'user123'; // 본인 아이디 (실제 로그인 아이디로 교체)
    String viewedUserId = 'user123'; // 현재 보고 있는 유저 아이디 (변경해보면서 테스트 가능)

    bool isFollowing = false; // 팔로우 상태

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            /// 상단 프로필 영역
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
                  // 기존 프로필 중앙 내용
                  Align(
                    alignment: Alignment.center,
                    child: showDetail
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage('assets/w2.jpg'),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "윤사나",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: selectedItemColor,
                          ),
                        ),
                      ],
                    )
                        : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundImage: AssetImage('assets/w2.jpg'),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "윤사나",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: selectedItemColor,
                          ),
                        ),
                        AnimatedCrossFade(
                          duration: Duration(milliseconds: 300),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Column(
                            children: [
                              SizedBox(height: 8),
                              SizedBox(
                                height: 360,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: profileImages.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.asset(
                                          profileImages[index],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "안녕하세요. 윤사나 입니다.",
                                style: TextStyle(color: selectedItemColor),
                              ),
                              Text(
                                "#캐주얼 #반팔",
                                style: TextStyle(color: Colors.blue),
                              ),
                            ],
                          ),
                          secondChild: SizedBox.shrink(),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isExpanded = !isExpanded;
                            });
                          },
                          child: Icon(
                            isExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 32,
                            color: selectedItemColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 우측 최상단 고정된 버튼/아이콘
                  Positioned(
                    top: 8,
                    right: 8,
                    child: viewedUserId == currentUserId
                        ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // 프로필 편집 버튼 클릭 시 행동
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Image.asset(
                                'assets/common/person_edit.png',
                                color: Colors.black,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            // 설정 버튼 클릭 시 행동
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings,
                              size: 24,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    )
                        : ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isFollowing = !isFollowing;
                        });
                      },
                      child: Text(isFollowing ? "언팔로우" : "팔로우"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        isFollowing ? Colors.grey : Colors.pink[200],
                        foregroundColor: Colors.white,
                        shape: StadiumBorder(),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// 하단 영역: 피드 or 상세 페이지
            Expanded(
              child: IndexedStack(
                index: showDetail ? 1 : 0,
                children: [
                  /// 피드 뷰
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "5월",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: selectedItemColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16),
                          itemCount: 7,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, index) {
                            String imagePath;
                            String label;
                            if (index == 0) {
                              imagePath = 'assets/w11.webp';
                              label = "#추웠어\n20℃";
                            } else if (index == 1) {
                              imagePath = 'assets/w3.jpg';
                              label = "#더웠어\n25℃";
                            } else if (index == 2) {
                              imagePath = 'assets/w12.jpg';
                              label = "#적당했어\n23℃";
                            } else if (index == 3) {
                              imagePath = 'assets/w13.webp';
                              label = "#더웠어\n23℃";
                            } else {
                              imagePath = 'assets/noimg.jpg';
                              label = "";
                            }
                            return GestureDetector(
                              onTap: () => openDetail(imagePath),
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(imagePath),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: Colors.white70,
                                      padding: EdgeInsets.symmetric(vertical: 2),
                                      child: Text(
                                        label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  /// 상세 페이지
                  DetailPage(
                    key: ValueKey(selectedImagePath),
                    imagePath: selectedImagePath ?? 'assets/noimg.jpg',
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
}
