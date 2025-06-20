import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/deep_link_handler.dart';
import 'main/detail_page.dart';
import 'main/feed_list_page.dart';
import 'main/gemini_chat.dart'; // ⬅ 추가
import 'common/custom_app_bar.dart';
import 'common/custom_bottom_navbar.dart';
import 'main/home_content.dart';
import 'main/mypage_tab.dart';
import 'main/search_tab.dart';
import 'main/write_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String? _selectedUserId;
  String? _nickname;
  String? _profileImageUrl;

  Key _myPageKey = ValueKey('initial');

  final DeepLinkHandler _deepLinkHandler = DeepLinkHandler();

  bool _hasProcessedDeepLink = false; // 딥링크 중복 처리 방지 플래그

  @override
  void initState() {
    super.initState();
    _loadUserInfo();

    _handleInitialDeepLink();

    // 딥링크 실시간 처리 콜백 등록 및 초기화
    _deepLinkHandler.onFeedIdReceived = (feedId) {
      if (!_hasProcessedDeepLink) {
        _hasProcessedDeepLink = true;
        _openDetailPage(feedId);
      }
    };
    _deepLinkHandler.init();
  }

  Future<void> _handleInitialDeepLink() async {
    final uri = await _deepLinkHandler.getInitialUri();
    if (!_hasProcessedDeepLink &&
        uri != null &&
        uri.scheme == 'wearly' &&
        uri.host == 'deeplink' &&
        uri.path == '/feedid' &&
        uri.queryParameters.containsKey('id')) {
      _hasProcessedDeepLink = true;
      final feedId = uri.queryParameters['id']!;
      _openDetailPage(feedId);
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId');

    if (uid != null) {
      setState(() {
        _selectedUserId = uid;
      });

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        setState(() {
          _nickname = userDoc['nickname'] ?? '';
          _profileImageUrl = userDoc['profileImage'] ?? null;
          prefs.setString('nickname', userDoc['nickname'] ?? '');
          prefs.setString('profileImage', userDoc['profileImage'] ?? '');
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 4) {
        _selectedUserId = null;
        _myPageKey = ValueKey(DateTime.now().millisecondsSinceEpoch.toString());
      }
      _selectedIndex = index;
    });
  }

  void openUserPage(String userId) {
    setState(() {
      _selectedUserId = userId;
      _myPageKey = ValueKey(userId + DateTime.now().millisecondsSinceEpoch.toString());
      _selectedIndex = 4; // MyPageTab 탭으로 전환
    });
  }

  void openFeecPage() {
    setState(() {
      _selectedIndex = 3; // MyPageTab 탭으로 전환
    });
  }

  void _openDetailPage(String feedId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DetailPage(
          feedId: feedId,
          currentUserId: _selectedUserId ?? '',
          showAppBar: true,
          onBack: () {
            Navigator.of(context).pop();
            // 상세페이지에서 뒤로가면 딥링크 처리 플래그 리셋
            _deepLinkHandler.resetProcessedFlag();
            _hasProcessedDeepLink = false;
          },
        ),
      ),
    );
  }

  void _goToGeminiPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GeminiTextGeneratePage()),
    );
  }

  Widget buildMyPageTab({String? userId, required Function onUserTap}) {
    return MyPageTab(
      key: ValueKey(userId ?? _myPageKey),
      userId: userId,
      onUserTap: onUserTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomeContent(key: ValueKey(DateTime.now().millisecondsSinceEpoch)),
      SearchTab(onUserTap: openUserPage),
      WritePostPage(),
      //onUserTap: openFeecPage),
      FeedListPage(
          key: ValueKey(DateTime.now().millisecondsSinceEpoch),
          onUserTap: openUserPage),
      buildMyPageTab(userId: _selectedUserId, onUserTap: openUserPage),
    ];

    return Scaffold(
      appBar: CustomAppBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        nickname: _nickname,
        profileImageUrl: _profileImageUrl,
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _goToGeminiPage,
      //   child: const Icon(Icons.headset_mic),
      //   tooltip: 'Gemini 테스트',
      // ),
    );
  }
}
