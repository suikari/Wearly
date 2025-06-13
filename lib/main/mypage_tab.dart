import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'detail_page.dart';

class MyPageTab extends StatefulWidget {
  final String? userId;

  const MyPageTab({Key? key, this.userId}) : super(key: key);

  @override
  State<MyPageTab> createState() => _MyPageWidgetState();
}

class _MyPageWidgetState extends State<MyPageTab> {
  bool isExpanded = true;
  bool showDetail = false;
  String? selectedImagePath;

  String currentUserId = 'user123';

  final FirebaseFirestore fs = FirebaseFirestore.instance;


  final List<Map<String, dynamic>> userProfiles = [
    {
      "userId": "user123",
      "name": "윤사나",
      "profileImages": [
        'assets/w1.jpg',
        'assets/w3.jpg',
        'assets/w5.jfif',
      ],
      "bio": "안녕하세요. 윤사나 입니다.",
      "hashtags": "#캐주얼 #반팔",
      "mainProfileImage": "assets/w2.jpg"
    },
    {
      "userId": "user456",
      "name": "김지은",
      "profileImages": [
        'assets/w7.jfif',
        'assets/w8.jfif',
      ],
      "bio": "반가워요. 지은이에요!",
      "hashtags": "#댄디 #봄코디",
      "mainProfileImage": "assets/w9.jfif"
    },
  ];

  final List<Map<String, dynamic>> feedItems = [
    {"imagePath": "assets/w11.webp", "label": "#추웠어\n20℃"},
    {"imagePath": "assets/w3.jpg", "label": "#더웠어\n25℃"},
    {"imagePath": "assets/w12.jpg", "label": "#적당했어\n23℃"},
    {"imagePath": "assets/w13.webp", "label": "#더웠어\n23℃"},
    {"imagePath": "assets/noimg.jpg", "label": ""},
    {"imagePath": "assets/noimg.jpg", "label": ""},
    {"imagePath": "assets/noimg.jpg", "label": ""},
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

  Map<String, dynamic> getUserProfile(String userId) {
    return userProfiles.firstWhere(
          (profile) => profile['userId'] == userId,
      orElse: () => userProfiles[0],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String viewedUserId = widget.userId ?? currentUserId;
    final bool isOwnPage = viewedUserId == currentUserId;
    final Map<String, dynamic> profile = getUserProfile(viewedUserId);

    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor ?? Theme.of(context).primaryColor;
    final navBackgroundColor = bottomNavTheme.backgroundColor ?? Theme.of(context).primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
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
                        Text(
                          profile["name"],
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: selectedItemColor),
                        ),
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
                        Text(
                          profile["name"],
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selectedItemColor),
                        ),
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
                                        child: Image.asset(
                                          profile["profileImages"][index],
                                          fit: BoxFit.cover,
                                        ),
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
                          child: Icon(
                            isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 32,
                            color: selectedItemColor,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconBtn('assets/common/person_edit.png', () {
                          // 프로필 편집
                        }),
                        _buildIconBtn(Icons.settings, () {
                          // 설정
                        }),
                      ],
                    )
                        : ElevatedButton(
                      onPressed: () {
                        // 팔로우 기능
                      },
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
            Expanded(
              child: IndexedStack(
                index: showDetail ? 1 : 0,
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("5월", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: selectedItemColor)),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.all(16),
                          itemCount: feedItems.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.8,
                          ),
                          itemBuilder: (context, index) {
                            final item = feedItems[index];
                            return GestureDetector(
                              onTap: () => openDetail(item["imagePath"]),
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: AssetImage(item["imagePath"]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (item["label"].toString().isNotEmpty)
                                      Container(
                                        width: double.infinity,
                                        color: Colors.white70,
                                        padding: EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          item["label"],
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        SingleChildScrollView(
                          child: StreamBuilder(
                            stream: fs.collection("feeds").snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

                              final docs = snapshot.data!.docs;
                              return Column(
                                children: List.generate(docs.length, (index) {
                                  final doc = docs[index];
                                  return ListTile(
                                    title: Text("작성자: ${doc["content"]}"),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(onPressed: () {}, icon: Icon(Icons.edit)),
                                        IconButton(onPressed: () {}, icon: Icon(Icons.delete)),
                                      ],
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
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
            ? Padding(
          padding: EdgeInsets.all(4),
          child: Image.asset(icon, color: Colors.black),
        )
            : Icon(icon, size: 20, color: Colors.black),
      ),
    );
  }
}
