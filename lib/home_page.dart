// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main/gemini_chat.dart'; // ⬅ 추가
import 'common/custom_app_bar.dart';
import 'common/custom_bottom_navbar.dart';
import 'main/home_content.dart';
import 'main/mypage_tab.dart';
import 'main/search_tab.dart';
import 'main/weather_tab.dart';
import 'main/write_post_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  Key _myPageKey = ValueKey('initial');

  void _onItemTapped(int index) {
    setState(() {
      if (index == 4) {
        _myPageKey = ValueKey(DateTime.now().millisecondsSinceEpoch);
      }
      _selectedIndex = index;
    });
  }

  final FirebaseFirestore fs = FirebaseFirestore.instance;


  void _goToGeminiPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const GeminiTextGeneratePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
  final List<Widget> _pages = [
    HomeContent(),
    SearchTab(),
    WritePostPage(),
    WeatherTab(),
    MyPageTab(key: _myPageKey), // ✅ key가 동적으로 반영됨
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToGeminiPage,
        child: const Icon(Icons.headset_mic),
        tooltip: 'Gemini 테스트',
      ),
    );
  }
}
