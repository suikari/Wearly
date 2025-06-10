import 'package:flutter/material.dart';

class MyPageTab extends StatefulWidget {
  @override
  _MyPageTabState createState() => _MyPageTabState();
}

class _MyPageTabState extends State<MyPageTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String profileImage =
      'https://i.pravatar.cc/150?img=12'; // 예제용 프로필 사진
  final String nickname = 'FlutterFan';
  final List<String> tags = ['#스타일', '#패션', '#일상'];
  final String intro = '패션과 일상을 사랑하는 개발자입니다.';

  final int followingsCount = 123;
  final int followersCount = 456;

  // 예제용 코디 피드 리스트
  final List<Map<String, String>> feedList = List.generate(
    5,
        (index) => {
      'image':
      'https://picsum.photos/seed/codi$index/400/400', // 랜덤 이미지
      'content': '코디 스타일 #$index',
    },
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildFeedCard(Map<String, String> feed) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(feed['image']!, fit: BoxFit.cover, width: double.infinity, height: 250),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(feed['content']!, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 프로필 헤더
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(profileImage),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(nickname, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(intro),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        ...tags.map((tag) => Container(
                          margin: EdgeInsets.only(right: 6),
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(tag, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
                        )),
                      ],
                    )

                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    tooltip: '프로필 수정',
                    onPressed: () {
                      // 프로필 수정 버튼 클릭
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings),
                    tooltip: '설정',
                    onPressed: () {
                      // 설정 버튼 클릭
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        Divider(height: 1),

        // 탭바
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.black54,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(text: '코디'),
            Tab(text: '팔로우 $followingsCount명'),
            Tab(text: '팔로워 $followersCount명'),
          ],
        ),

        // 탭바 뷰 (높이 고정 or Expanded로 감싸야함)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 코디 탭: 피드 리스트
              ListView.builder(
                itemCount: feedList.length,
                itemBuilder: (context, index) {
                  return _buildFeedCard(feedList[index]);
                },
              ),

              // 팔로우 탭: 예제 텍스트
              Center(
                child: Text('팔로우 리스트 화면 (예제)'),
              ),

              // 팔로워 탭: 예제 텍스트
              Center(
                child: Text('팔로워 리스트 화면 (예제)'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
