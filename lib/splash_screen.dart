import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

import 'login_page.dart';
import 'home_page.dart';
import 'main/detail_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String logoimg = 'assets/plogo.png';

  late AnimationController _controller;
  late Animation<double> _animation;

  final double boxWidth = 300;
  final double boxHeight = 150;

  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _loadTheme();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _animation = Tween<double>(begin: -0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startInitProcess();
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

  Future<void> _startInitProcess() async {
    await Future.delayed(const Duration(seconds: 2)); // 기존 대기 유지

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    Uri? initialUri;
    try {
      initialUri = await _appLinks.getInitialLink();
    } catch (e) {
      initialUri = null;
    }

    if (userId == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  bool _isFeedLink(Uri? uri) {
    return uri != null &&
        uri.scheme == 'wearly' &&
        uri.host == 'deeplink' &&
        uri.path == '/feedid' &&
        uri.queryParameters.containsKey('id');
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
        gradient: const LinearGradient(
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
                stops: const [0.0, 0.5, 1.0],
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
          child: SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              children: [
                _fixedGradientBackground(),
                _shiningLight(),
                Center(
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
