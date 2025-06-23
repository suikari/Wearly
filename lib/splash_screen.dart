import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'login_page.dart'; // 반드시 LoginPage가 구현되어 있어야 합니다.

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String logoimg = 'assets/logo/plogo.png';

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _loadTheme();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..forward();

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
      if (colorThemeString == 'ColorTheme.blackTheme') {
        logoimg = 'assets/logo/wlogo.png';
      } else if (colorThemeString == 'ColorTheme.blueTheme') {
        logoimg = 'assets/logo/logo.png';
      } else {
        logoimg = 'assets/logo/plogo.png';
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 로고
            Image.asset(
              logoimg,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),

            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(150, 150),
                  painter: RevealWavePainter(
                    animationValue: _controller.value,
                    backgroundColor: bgColor,
                  ),
                );
              },
            ),
          ],
        )
      ),
    );
  }
}

class RevealWavePainter extends CustomPainter {
  final double animationValue;
  final Color backgroundColor;

  RevealWavePainter({
    required this.animationValue,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = backgroundColor;

    final path = Path();

    final waveHeight = 15.0;
    final progress = animationValue * pi * 2;

    final yOffset = size.height * (1 - animationValue);

    path.moveTo(0, 0);
    path.lineTo(0, yOffset);

    for (double x = 0.0; x <= size.width; x++) {
      double y = waveHeight * sin((x / size.width * 2 * pi) + progress);
      path.lineTo(x, yOffset + y);
    }

    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant RevealWavePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
