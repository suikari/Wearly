import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String logoimg = 'assets/plogo.png' ;


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
  void initState() {
    super.initState();
    _loadTheme();

    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          logoimg,
          width: 150,
          height: 150,
        ),
      ),
    );
  }
}
