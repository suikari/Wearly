import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ColorTheme { defaultTheme, blueTheme, blackTheme }

class ThemeProvider extends ChangeNotifier {
  // 테마 상태 변수 (Brightness 제거)
  ColorTheme _colorTheme = ColorTheme.defaultTheme;

  // 키값 (SharedPreferences)
  static const _colorThemeKey = 'colorTheme';

  // 기본색상 커스텀 스와치
  static final Map<int, Color> _defaultColorMap = {
    50: Color.fromRGBO(255, 111, 97, 0.1),
    100: Color.fromRGBO(255, 111, 97, 0.2),
    200: Color.fromRGBO(255, 111, 97, 0.3),
    300: Color.fromRGBO(255, 111, 97, 0.4),
    400: Color.fromRGBO(255, 111, 97, 0.5),
    500: Color.fromRGBO(255, 111, 97, 0.6),
    600: Color.fromRGBO(255, 111, 97, 0.7),
    700: Color.fromRGBO(255, 111, 97, 0.8),
    800: Color.fromRGBO(255, 111, 97, 0.9),
    900: Color.fromRGBO(255, 111, 97, 1.0),
  };
  static final MaterialColor defaultSwatch =
  MaterialColor(0xFFFF6F61, _defaultColorMap);

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ColorTheme get colorTheme => _colorTheme;

  ThemeData get currentTheme {
    switch (_colorTheme) {
      case ColorTheme.blueTheme:
        return ThemeData(
          fontFamily: 'reko',
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.blue[50],
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue,
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.blue,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
          ),
        );

      case ColorTheme.blackTheme:
        return ThemeData.dark().copyWith(
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'reko'),
          primaryColor: Colors.grey[900],
          scaffoldBackgroundColor: Color.fromRGBO(51,51,51, 1.0),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.grey[900],
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.grey[900],
            selectedItemColor: Color.fromRGBO(85,85,85, 1.0),
            unselectedItemColor: Colors.white70,
          ),
        );

      case ColorTheme.defaultTheme:
      default:
      return ThemeData(
        primarySwatch: defaultSwatch,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'cho', // 기본 본문 폰트
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'cho', fontSize: 16),
          bodyMedium: TextStyle(fontFamily: 'cho'),
          bodySmall: TextStyle(fontFamily: 'cho'),
          labelLarge: TextStyle(fontFamily: 'cho', fontSize: 16),
          labelMedium: TextStyle(fontFamily: 'cho'),
          labelSmall: TextStyle(fontFamily: 'cho'),
          headlineSmall: TextStyle(fontFamily: 'reko', fontSize: 20),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color.fromRGBO(255, 193, 204, 1.0),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontFamily: 'reko', // 헤더용 폰트
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color.fromRGBO(255, 193, 204, 1.0),
          selectedItemColor: Color.fromRGBO(255, 111, 97, 1.0),
          unselectedItemColor: Colors.white,
          selectedLabelStyle: TextStyle(fontFamily: 'reko'), // 네비게이션 선택 항목 폰트
          unselectedLabelStyle: TextStyle(fontFamily: 'reko'),
        ),
      );

        // return ThemeData(
        //   fontFamily: 'reko',
        //   brightness: Brightness.light,
        //   primarySwatch: defaultSwatch,
        //   scaffoldBackgroundColor : Colors.white,
        //   appBarTheme: AppBarTheme(
        //     backgroundColor: Color.fromRGBO(255, 193, 204, 1.0),
        //     iconTheme: IconThemeData(color: Colors.white),
        //     titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        //   ),
        //   bottomNavigationBarTheme: BottomNavigationBarThemeData(
        //     backgroundColor: Color.fromRGBO(255, 193, 204, 1.0),
        //     selectedItemColor: Color.fromRGBO(255, 111, 97, 1.0),
        //     unselectedItemColor: Colors.white,
        //   ),
        // );
    }
  }

  // 색상 테마 변경 (default, blue, black)
  void setColorTheme(ColorTheme theme) async {
    _colorTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_colorThemeKey, theme.toString());
  }

  // 앱 시작 시 SharedPreferences에서 저장된 값 불러오기
  void _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorThemeString = prefs.getString(_colorThemeKey);

    if (colorThemeString != null) {
      _colorTheme = ColorTheme.values.firstWhere(
            (e) => e.toString() == colorThemeString,
        orElse: () => ColorTheme.defaultTheme,
      );
    }

    notifyListeners();
  }
}
