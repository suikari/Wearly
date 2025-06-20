import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'common/notification_service.dart';
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
  // // (선택) App Check 초기화
  // await FirebaseAppCheck.instance.activate(
  //   androidProvider: AndroidProvider.debug,
  //   appleProvider: AppleProvider.debug,
  // );

  // 익명 로그인
  // await FirebaseAuth.instance.signInAnonymously();
  KakaoSdk.init(
    nativeAppKey: '102bf4d0a6bfeeab56fd2d28f7573cc1',
  );

  tz.initializeTimeZones();
  await NotificationService.init(); // 알림 초기화

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
      locale: const Locale('ko'),  // 한국어로 설정
      supportedLocales: const [
        Locale('ko'), // 한국어
        Locale('en'), // 영어 등 필요에 따라 추가
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Splash & Login Demo',
      theme: themeProvider.currentTheme,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
