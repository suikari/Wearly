import 'package:flutter/material.dart';
import '../common/notification_service.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  TimeOfDay selectedTime = TimeOfDay.now();

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  void _scheduleNotification() {
    NotificationService.scheduleDailyNotification(
      0,
      '일일 알림',
      '밥먹을 시간입니다!',
      selectedTime.hour,
      selectedTime.minute,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('알림이 예약되었습니다')),
    );
  }

  void _testNotificationNow() {
    NotificationService.showInstantNotification(
      id: 99,
      title: '테스트 알림',
      body: '이건 지금 바로 뜨는 테스트 알림입니다.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('선택한 시간: ${selectedTime.format(context)}'),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _pickTime, child: const Text('시간 선택')),
            ElevatedButton(onPressed: _scheduleNotification, child: const Text('알림 예약')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testNotificationNow,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('테스트 알림 즉시 보내기'),
            ),
          ],
        ),
      ),
    );
  }
}
