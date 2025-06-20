import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../login_page.dart';
import '../../page/notification_page.dart';
import '../../provider/theme_provider.dart'; // ThemeProvider 경로 맞게 수정

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool isAlarmOn = true;
  bool dmAllowed = true;

  int selectedThemeIndex = 0;
  List<Color> themeColors = [Colors.pink, Colors.indigo, Colors.black];

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
      isAlarmOn = prefs.getBool(keyIsAlarmOn) ?? true;
      dmAllowed = prefs.getBool(keyDmAllowed) ?? true;
    });
  }

  Future<void> _saveIsAlarmOn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyIsAlarmOn, value);
  }

  Future<void> _saveDmAllowed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyDmAllowed, value);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('설정', style: TextStyle(color: Colors.white)),
        actions: const [
          Icon(Icons.message, color: Colors.white),
          SizedBox(width: 10),
          Icon(Icons.notifications, color: Colors.white),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(Icons.notifications, '알림 설정'),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _selectTime,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[100],
                  ),
                  child: Text(
                      '${selectedTime.hourOfPeriod.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isAlarmOn = true;
                    });
                    _saveIsAlarmOn(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlarmOn ? Colors.pink : Colors.grey[300],
                  ),
                  child: const Text('설정', style: TextStyle(color: Colors.white)),
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
                    backgroundColor: !isAlarmOn ? Colors.pink : Colors.grey[300],
                  ),
                  child: const Text('해제', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '선택한 시간에 오늘의 날씨와 옷차림 알림을 보내드립니다.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationPage()),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('알림 상세 설정 열기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const Divider(height: 32),
            _buildSectionTitle(Icons.color_lens, '테마 설정'),
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
                        color: selectedThemeIndex == index ? Colors.pink : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const Divider(height: 32),
            _buildSectionTitle(Icons.mark_chat_unread, 'DM 설정'),
            Row(
              children: [
                _toggleButton('숫자알림', dmAllowed, () {
                  setState(() => dmAllowed = true);
                  _saveDmAllowed(true);
                }),
                const SizedBox(width: 8),
                _toggleButton('알림안봄', !dmAllowed, () {
                  setState(() => dmAllowed = false);
                  _saveDmAllowed(false);
                }),
              ],
            ),
            const Divider(height: 32),

            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('userId');// 저장된 정보 초기화

                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (route) => false, // 모든 이전 화면 제거
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('로그아웃'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.pink),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _toggleButton(String label, bool selected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.pink : Colors.grey[300],
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
