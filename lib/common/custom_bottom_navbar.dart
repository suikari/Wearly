import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? nickname;
  final String? profileImageUrl;

  CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.nickname,
    required this.profileImageUrl,
  }) : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;
    final backgroundColor = bottomNavTheme.backgroundColor ?? Theme.of(context).primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor ?? Colors.white70;



    //print("widget.profileImageUrl>>>>${widget.profileImageUrl}");
    // Column(
    //   mainAxisSize: MainAxisSize.min,
    //   children: [
    //   Container(
    //   height: 7,               // 배경색 줄 두께 (원하는 만큼 조절)
    //   width: double.infinity,
    //   color: backgroundColor, // 예: 연한 회색 배경색
    // ),
    // Container(
    // height: 3,              // 흰색 선 높이
    // width: double.infinity,
    // color: scaffoldBackgroundColor,    // 흰색 선
    // ),
    //        ),],
    return
        BottomNavigationBar(
          currentIndex: widget.currentIndex,
          onTap: widget.onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: backgroundColor,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          items: [

            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: '검색',
            ),
            BottomNavigationBarItem(
              icon: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.all(4),
                child: Icon(Icons.add,),
              ),
              label: '추가',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.article),
              label: '코디',
            ),
            BottomNavigationBarItem(
              icon: (widget.profileImageUrl != null && widget.profileImageUrl!.isNotEmpty)
                  ? CircleAvatar(
                radius: 12,
                backgroundImage: NetworkImage(widget.profileImageUrl!),
              )
                  : Icon(Icons.person),
              label: (widget.nickname != null && widget.nickname!.isNotEmpty)
                  ? widget.nickname!
                  : '마이페이지',
            ),
          ],
    );
  }
}
