import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main/chat_list_page.dart';
import '../provider/theme_provider.dart';
import '../main/NotificationPage.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final VoidCallback? onMessageTap;
  final VoidCallback? onNotificationTap;

  static const String keyIsAlarmOn = 'isAlarmOn';
  static const String keyDmAllowed = 'dmAllowed';

  const CustomAppBar({
    this.title,
    this.onMessageTap,
    this.onNotificationTap,
    Key? key,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<Map<String, bool>> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('userId');

    return {
      'isAlarmOn': prefs.getBool('${keyIsAlarmOn}_${uid}') ?? true,
      'dmAllowed': prefs.getBool('${keyDmAllowed}_${uid}') ?? true,
    };
  }

  Stream<int> getUnreadMessageCountStream(String uid) {
    return FirebaseFirestore.instance
        .collection('chatRooms')
        .where('uids', arrayContains: uid)
        .snapshots()
        .map((roomsSnap) {
      int totalUnread = 0;
      for (var doc in roomsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final unreadCount = data['unreadCount_$uid'] ?? 0;
        totalUnread += unreadCount is int ? unreadCount : 0;
      }
      return totalUnread;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appBarTheme = Theme.of(context).appBarTheme;
    final backgroundColor = appBarTheme.backgroundColor ?? Theme.of(context).primaryColor;
    final iconColor = appBarTheme.iconTheme?.color ?? Colors.white;
    final titleTextStyle = appBarTheme.titleTextStyle ??
        const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600);

    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return FutureBuilder<Map<String, bool>>(
      future: _loadSettings(),
      builder: (context, snapshot) {
        final isAlarmOn = snapshot.data?['isAlarmOn'] ?? true;
        final dmAllowed = snapshot.data?['dmAllowed'] ?? true;

        return AppBar(
          title: Text(title ?? '', style: titleTextStyle),
          backgroundColor: backgroundColor,
          iconTheme: IconThemeData(color: iconColor),
          actions: [
            // 메시지
              StreamBuilder<int>(
                stream: getUnreadMessageCountStream(uid),
                builder: (context, snapshot) {
                  int unreadMsgCount = snapshot.data ?? 0;
                  return InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: onMessageTap ??
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatListPage()),
                          );
                        },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.message, size: 27),
                        ),
                        if (unreadMsgCount > 0 && dmAllowed)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                              child: Text(
                                unreadMsgCount > 99 ? '99+' : unreadMsgCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

            // 알림
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('notifications')
                    .where('uid', isEqualTo: uid)
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  final unreadNotiCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: onNotificationTap ??
                              () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotificationPage(uid: uid),
                              ),
                            );
                          },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.notifications, size: 27),
                          ),
                          if (unreadNotiCount > 0 && isAlarmOn)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                                child: Text(
                                  unreadNotiCount > 99 ? '99+' : unreadNotiCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}