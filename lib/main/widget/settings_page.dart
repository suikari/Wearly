import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);
  bool isAlarmOn = true;
  bool isPrivate = false;
  int selectedThemeIndex = 0;
  bool dmAllowed = true;

  List<Color> themeColors = [Colors.black, Colors.indigo, Colors.pink];

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.pink[100],
        elevation: 0,
        automaticallyImplyLeading: false,
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
                  child: Text('${selectedTime.hourOfPeriod.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')} ${selectedTime.period == DayPeriod.am ? 'AM' : 'PM'}'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => setState(() => isAlarmOn = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAlarmOn ? Colors.pink : Colors.grey[300],
                  ),
                  child: const Text('설정', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => setState(() => isAlarmOn = false),
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
            const Divider(height: 32),
            _buildSectionTitle(Icons.person, '계정 비공개'),
            Row(
              children: [
                _toggleButton('공개', !isPrivate, () => setState(() => isPrivate = false)),
                const SizedBox(width: 8),
                _toggleButton('비공개', isPrivate, () => setState(() => isPrivate = true)),
              ],
            ),
            const Divider(height: 32),
            _buildSectionTitle(Icons.color_lens, '테마 설정'),
            Row(
              children: List.generate(themeColors.length, (index) {
                return GestureDetector(
                  onTap: () => setState(() => selectedThemeIndex = index),
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
                _toggleButton('수신 설정', dmAllowed, () => setState(() => dmAllowed = true)),
                const SizedBox(width: 8),
                _toggleButton('수신 거부', !dmAllowed, () => setState(() => dmAllowed = false)),
              ],
            ),
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
