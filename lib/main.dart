import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'splash_screen.dart';
import 'provider/theme_provider.dart';



Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized(); // Flutter 엔진 초기화 보장

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase 초기화가 완료된 후 Firestore 인스턴스에 접근 가능
  FirebaseFirestore.instance;

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Splash & Login Demo',
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
