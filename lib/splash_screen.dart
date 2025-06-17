import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'login_page.dart'; // 반드시 LoginPage가 구현되어 있어야 합니다.

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String logoimg = 'assets/plogo.png';

  late AnimationController _controller;
  late Animation<double> _animation;

  final double boxWidth = 300;
  final double boxHeight = 150;

  @override
  void initState() {
    super.initState();
    _loadTheme();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    )..repeat();

    _animation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final colorThemeString = prefs.getString("colorTheme");

    setState(() {
      if (colorThemeString != 'ColorTheme.defaultTheme') {
        logoimg = 'assets/logo.png';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _fixedGradientBackground() {
    return Container(
      width: boxWidth,
      height: boxHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Color(0xFF60A5FA), // 파랑
            Color(0xFFF472B6), // 핑크
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _shiningLight() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final pos = _animation.value * boxWidth;

        return Positioned(
          left: pos - boxWidth * 0.3,
          top: 0,
          child: Container(
            width: boxWidth * 0.3,
            height: boxHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
                stops: [0.0, 0.5, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              children: [
                _fixedGradientBackground(), // 고정된 그라데이션 배경
                _shiningLight(), // 흐르는 하얀 빛
                Center( // 로고 이미지 표시
                  child: Image.asset(
                    logoimg,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
