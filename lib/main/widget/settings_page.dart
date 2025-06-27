import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/common/custom_app_bar.dart';
import 'package:w2wproject/main.dart';
import '../../home_page.dart';
import '../../login_page.dart';
import '../../page/notification_page.dart';
import '../../provider/custom_colors.dart';
import '../../provider/theme_provider.dart'; // ThemeProvider 경로 맞게 수정

class SettingsPage extends StatefulWidget {
  final String userId;

  const SettingsPage({super.key, required this.userId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool isAlarmOn = true;
  bool dmAllowed = true;

  int selectedThemeIndex = 0;
  List<Color> themeColors = [Color(0xFFFFC1CC), Color(0xFF4058A6), Color(0xCC000000)];

  static const String keyIsAlarmOn = 'isAlarmOn';
  static const String keyDmAllowed = 'dmAllowed';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isAlarmOn = prefs.getBool('${keyIsAlarmOn}_${widget.userId}') ?? true;
      dmAllowed = prefs.getBool('${keyDmAllowed}_${widget.userId}') ?? true;
    });
  }

  Future<void> _saveIsAlarmOn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${keyIsAlarmOn}_${widget.userId}', value);
  }

  Future<void> _saveDmAllowed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${keyDmAllowed}_${widget.userId}', value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context);
    // ThemeProvider.colorTheme에 맞춰 selectedThemeIndex 초기화
    switch (themeProvider.colorTheme) {
      case ColorTheme.defaultTheme:
        selectedThemeIndex = 0;
        break;
      case ColorTheme.blueTheme:
        selectedThemeIndex = 1;
        break;
      case ColorTheme.blackTheme:
        selectedThemeIndex = 2;
        break;
    }
  }

  void _onThemeSelected(int index) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    ColorTheme newTheme;

    setState(() {
      selectedThemeIndex = index;

      switch (index) {
        case 0:
          newTheme = ColorTheme.defaultTheme;
          themeProvider.setColorTheme(newTheme);
          break;
        case 1:
          newTheme = ColorTheme.blueTheme;
          themeProvider.setColorTheme(newTheme);
          break;
        case 2:
          newTheme = ColorTheme.blackTheme;
          themeProvider.setColorTheme(newTheme);
          break;
      }
    });
  }

  void _selectTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('로그아웃'),
        content: Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // 취소
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 다이얼로그 먼저 닫기
              await _logout(context); // 로그아웃 처리
            },
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // 저장된 정보 초기화

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false, // 모든 이전 화면 제거
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;
    Color Grey = customColors?.textGrey ?? Colors.grey;
    Color White = customColors?.textWhite ?? Colors.white;
    Color Black = customColors?.textBlack ?? Colors.black;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return WillPopScope(
        onWillPop: () async {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(initialIndex: 4),
            ),
                (route) => false,
          );
          return false; // 기본 pop 동작 방지
        },
        child: Scaffold(
        appBar: CustomAppBar(title : '설정'),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(Icons.notifications, pointColor , '알림 설정'),
              Row(
                children: [
                  // ElevatedButton(
                  //   onPressed: _selectTime,
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Colors.purple[100],
                  //   ),
                  //   child: Text(
                  //       '${selectedTime.hourOfPeriod.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}'),
                  // ),
                  // const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isAlarmOn = true;
                      });
                      _saveIsAlarmOn(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAlarmOn ? pointColor : subColor,
                    ),
                    child: Text('숫자알림', style: TextStyle(
                      color: themeProvider.colorTheme != ColorTheme.blackTheme
                        ? Black
                        : Grey,)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isAlarmOn = false;
                      });
                      _saveIsAlarmOn(false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isAlarmOn ? pointColor : subColor,
                    ),
                    child: Text('알림안봄', style: TextStyle(
                      color: themeProvider.colorTheme != ColorTheme.blackTheme
                        ? Black
                        : Grey,)),
                  ),
                ],
              ),
              const Divider(height: 32),
              _buildSectionTitle(Icons.mark_chat_unread, pointColor, 'DM 설정'),
              Row(
                children: [
                  _toggleButton('숫자알림', dmAllowed, pointColor , subColor , themeProvider , () {
                    setState(() => dmAllowed = true);
                    _saveDmAllowed(true);
                  }),
                  const SizedBox(width: 8),
                  _toggleButton('알림안봄', !dmAllowed, pointColor , subColor ,themeProvider , () {
                    setState(() => dmAllowed = false);
                    _saveDmAllowed(false);
                  }),
                ],
              ),
              // const Padding(
              //   padding: EdgeInsets.symmetric(vertical: 8),
              //   child: Text(
              //     '선택한 시간에 오늘의 날씨와 옷차림 알림을 보내드립니다.',
              //     style: TextStyle(color: Colors.grey),
              //   ),
              // ),
              // const SizedBox(height: 12),
              // ElevatedButton.icon(
              //   onPressed: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (context) => const NotificationPage()),
              //     );
              //   },
              //   icon: const Icon(Icons.settings),
              //   label: const Text('알림 상세 설정 열기'),
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.deepPurple,
              //     foregroundColor: Colors.white,
              //   ),
              // ),
              const Divider(height: 32),
              _buildSectionTitle(Icons.color_lens, pointColor, '테마 설정'),
              Row(
                children: List.generate(themeColors.length, (index) {
                  return GestureDetector(
                    onTap: () => _onThemeSelected(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: themeColors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedThemeIndex == index ? pointColor : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const Divider(height: 32),

              Center(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('로그아웃'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: highlightColor,
                    foregroundColor: themeProvider.colorTheme != ColorTheme.blackTheme
                    ? Black
                      : Grey,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, Color point, String title) {
    return Row(
      children: [
        Icon(icon, color: point),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, Color point , Color sub , ThemeProvider themeProvider , VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? point : sub,
        foregroundColor: themeProvider.colorTheme != ColorTheme.blackTheme
          ? Colors.black87
            : Colors.grey ,
      ),
      child: Text(label),
    );
  }
}
