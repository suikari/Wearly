import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // const 제거 (hot reload 문제 방지)
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splash & Login Demo',
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
