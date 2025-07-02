import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'custom_colors.dart';
import 'custom_fonts.dart';

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
  static final Map<int, Color> _blueColorMap = {
    50: Color.fromRGBO(64, 88, 166, 0.1),
    100: Color.fromRGBO(64, 88, 166, 0.2),
    200: Color.fromRGBO(64, 88, 166, 0.3),
    300: Color.fromRGBO(64, 88, 166, 0.4),
    400: Color.fromRGBO(64, 88, 166, 0.5),
    500: Color.fromRGBO(64, 88, 166, 0.6),
    600: Color.fromRGBO(64, 88, 166, 0.7),
    700: Color.fromRGBO(64, 88, 166, 0.8),
    800: Color.fromRGBO(64, 88, 166, 0.9),
    900: Color.fromRGBO(64, 88, 166, 1.0),
  };
  static final MaterialColor defaultSwatch =
  MaterialColor(0xFFFF6F61, _defaultColorMap);
  static final MaterialColor bluetSwatch =
  MaterialColor(0xFFFF6F61, _blueColorMap);

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  ColorTheme get colorTheme => _colorTheme;

  ThemeData get currentTheme {
    switch (_colorTheme) {
      case ColorTheme.blueTheme:
        return ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          fontFamily: 'IM_Hyemin', // 기본 본문 폰트
          textTheme:
          TextTheme(
            bodyLarge: TextStyle(fontFamily: 'IM_Hyemin', fontSize: 16 , color: Color(0xFF333333) ),
            bodyMedium: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
            bodySmall: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
            labelLarge: TextStyle(fontFamily: 'IM_Hyemin', fontSize: 16 , color: Color(0xFF333333) ),
            labelMedium: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
            labelSmall: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
            headlineSmall: TextStyle(fontFamily: 'Maplestory', fontSize: 20 , color: Color(0xFF333333) ),
          ),
          brightness: Brightness.light,
          primarySwatch: bluetSwatch,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF4058A6),
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(fontFamily: 'Maplestory',color: Colors.white, fontSize: 20),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Color(0xFF4058A6),
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.white70,
            selectedLabelStyle: TextStyle(fontFamily: 'Maplestory'),
            unselectedLabelStyle: TextStyle(fontFamily: 'Maplestory'),
          ),
          extensions: <ThemeExtension<dynamic>>[
            const CustomColors(
              mainColor: Color(0xFF4058A6),
              pointColor: Color(0xFF33B9E3),
              subColor: Color(0xFFEAF4FF),
              highlightColor: Color(0xFFFFC87B),
              textGrey: Color(0xFF555555),
              textWhite: Colors.white,
              textBlack: Color(0xFF333333)
            ),
            const CustomFonts(
              bodyFont: 'IM_Hyemin',
              titleFont: 'Maplestory',
              labelFont: 'Hakgyoansim',
            ),
          ],
        );
      case ColorTheme.blackTheme:
        return ThemeData.dark().copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          primaryColor: Colors.grey[900],
          scaffoldBackgroundColor: Color.fromRGBO(51, 51, 51, 1.0),
          textTheme: TextTheme(
            bodyLarge: TextStyle(fontFamily: 'IM_Hyemin', fontSize: 16, color : Colors.white),
            bodyMedium: TextStyle(fontFamily: 'IM_Hyemin' , color : Colors.white),
            bodySmall: TextStyle(fontFamily: 'IM_Hyemin' , color : Colors.white),
            labelLarge: TextStyle(fontFamily: 'IM_Hyemin', fontSize: 16 , color : Colors.white),
            labelMedium: TextStyle(fontFamily: 'IM_Hyemin' , color : Colors.white),
            labelSmall: TextStyle(fontFamily: 'IM_Hyemin' , color : Colors.white),
            headlineSmall: TextStyle(fontFamily: 'Maplestory', fontSize: 20 , color : Colors.white),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor:  Color(0xCC000000), //Colors.grey[900],
            iconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(fontFamily: 'Maplestory',color: Colors.white, fontSize: 20),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Color(0xCC000000), //Colors.grey[900],
            selectedItemColor: Colors.white70,
            unselectedItemColor: Color.fromRGBO(85,85,85, 1.0),
            selectedLabelStyle: TextStyle(fontFamily: 'Maplestory'),
            unselectedLabelStyle: TextStyle(fontFamily: 'Maplestory'),
          ),
          extensions: <ThemeExtension<dynamic>>[
            const CustomColors(
                mainColor: Color(0xCC000000),
                pointColor: Color(0xFFFFFFFF),
                subColor: Color(0xFF555555),
                highlightColor: Color(0xFFEEEEEE),
                textGrey: Colors.grey,
                textWhite: Colors.white,
                textBlack: Color(0xCC000000)
            ),
            const CustomFonts(
              bodyFont: 'IM_Hyemin',
              titleFont: 'Maplestory',
              labelFont: 'Hakgyoansim',
            ),
          ],
        );

      case ColorTheme.defaultTheme:
      default:
      return ThemeData(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        primarySwatch: defaultSwatch,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'IM_Hyemin', // 기본 본문 폰트
        textTheme: TextTheme(
          bodyLarge: TextStyle(fontFamily: 'IM_Hyemin', fontSize: 16 , color: Color(0xFF333333) ),
          bodyMedium: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
          bodySmall: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
          labelLarge: TextStyle(fontFamily: 'IM_Hyemin', fontSize: 16 , color: Color(0xFF333333) ),
          labelMedium: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
          labelSmall: TextStyle(fontFamily: 'IM_Hyemin' , color: Color(0xFF333333) ),
          headlineSmall: TextStyle(fontFamily: 'Maplestory', fontSize: 20 , color: Color(0xFF333333) ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFFFC1CC),//Color.fromRGBO(255, 193, 204, 1.0),
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            fontFamily: 'Maplestory', // 헤더용 폰트
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFFFFC1CC),//Color.fromRGBO(255, 193, 204, 1.0),
          selectedItemColor: Color(0xFFFF6F61),//Color.fromRGBO(255, 111, 97, 1.0),
          unselectedItemColor: Colors.white,
          selectedLabelStyle: TextStyle(fontFamily: 'Maplestory'), // 네비게이션 선택 항목 폰트
          unselectedLabelStyle: TextStyle(fontFamily: 'Maplestory'),
        ),
          extensions: <ThemeExtension<dynamic>>[
            const CustomColors(
              mainColor: Color(0xFFFFC1CC),
              pointColor: Color(0xFFFF6F61),
              subColor: Color(0xFFFFF0F4),
              highlightColor: Color(0xFFFDE97C),
              textGrey: Color(0xFF555555),
              textWhite: Colors.white,
              textBlack: Color(0xFF333333)
            ),
            const CustomFonts(
              bodyFont: 'IM_Hyemin',
              titleFont: 'Maplestory',
              labelFont: 'Hakgyoansim',
            ),
          ],
        );
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
