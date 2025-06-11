import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
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
  final FirebaseFirestore fs = FirebaseFirestore.instance;

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
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
