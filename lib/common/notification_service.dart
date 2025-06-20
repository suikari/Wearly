import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    tz.initializeTimeZones();

    await _plugin.initialize(initSettings);

    final granted = await requestPermission();
    if (!granted) {
      print('알림 권한 거부됨');
    }

    if (await needsExactAlarmPermission()) {
      // 권한 없으면 사용자에게 권한 설정 열도록 안내
      print('정확한 알람 권한 필요');
    }
  }

  /// 알림 권한 요청 및 승인 여부 반환
  static Future<bool> requestPermission() async {
    var status = await Permission.notification.status;
    if (status.isDenied || status.isRestricted || status.isPermanentlyDenied) {
      status = await Permission.notification.request();
    }
    return status.isGranted;
  }

  /// Android 12 이상에서 정확한 알람 권한 체크
  static Future<bool> needsExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;

    // Android 버전 체크 (API 31 = S)
    final sdkInt = await _getAndroidSdkInt();
    if (sdkInt >= 31) {
      // AlarmManager.canScheduleExactAlarms() 호출을 플랫폼 채널로 해야 하므로 Flutter 패키지 없으면 항상 true로 처리 가능
      // flutter_local_notifications에서 직접 지원 안하면 native 코드 필요
      return true; // 권한이 필요한 상태라고 가정
    }
    return false;
  }

  /// Android SDK 버전 조회 (플랫폼 채널 또는 MethodChannel 구현 필요, 없으면 기본 0 리턴)
  static Future<int> _getAndroidSdkInt() async {
    // 실제로는 플랫폼 채널 통해 Android 코드에서 Build.VERSION.SDK_INT 값을 받아와야 함
    // 예시: MethodChannel('app.channel.shared.data').invokeMethod<int>('getSdkInt')
    return 31; // 테스트용 하드코딩 (Android 12 이상)
  }

  /// 정확한 알람 권한 설정 화면 열기
  static void openExactAlarmSettings() {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: 'android.settings.REQUEST_SCHEDULE_EXACT_ALARM',
        package: 'com.example.w2wproject', // 실제 패키지명으로 변경하세요
      );
      intent.launch();
    }
  }

  // 아래 scheduleDailyNotification, showInstantNotification 등 기존 함수 동일
  static Future<void> scheduleDailyNotification(
      int id, String title, String body, int hour, int minute) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
    tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    print('예약된 알림 시간: $scheduled');

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_id',
          'Daily Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      // matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'instant_id',
      'Instant Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, details);
  }
}
