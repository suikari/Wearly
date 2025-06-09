import 'package:flutter/material.dart';
import 'common/custom_app_bar.dart';
import 'common/custom_bottom_navbar.dart';
import 'main/home_content.dart';  // 새로 만든 파일 import
import 'main/search_tab.dart';  // 새로 만든 파일 import
import 'main/mypage_tab.dart';  // 마이페이지 탭 import
import 'main/weather_tab.dart';  // 마이페이지 탭 import
import 'main/write_post_page.dart';  // 마이페이지 탭 import


class HomePage extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = [
    HomeContent(),
    SearchTab(),
    WritePostPage(),
    WeatherTab(),
    MyPageTab(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
