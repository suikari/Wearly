import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 🔔 팔로우 알림 전송 함수
Future<void> sendFollowNotification({
  required String fromUid,
  required String fromNickname,
  required String fromProfileImg,
  required String toUid,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'uid': toUid,
    'type': 'follow',
    'fromUid': fromUid,
    'fromNickname': fromNickname,
    'fromProfileImg': fromProfileImg,
    'content': '회원님을 팔로우 합니다.',
    'createdAt': FieldValue.serverTimestamp(),
    'isRead': false,
  });
}

/// ➕ 팔로우 수행 함수
Future<void> followUser({
  required String targetUid,
  required void Function() onComplete,
}) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null || targetUid == myUid) return;

  final userRef = FirebaseFirestore.instance.collection('users').doc(myUid);
  final targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);

  await FirebaseFirestore.instance.runTransaction((txn) async {
    final mySnap = await txn.get(userRef);
    final targetSnap = await txn.get(targetRef);

    List<dynamic> following = (mySnap.data()?['following'] ?? []) as List<dynamic>;
    List<dynamic> followers = (targetSnap.data()?['follower'] ?? []) as List<dynamic>;

    if (!following.contains(targetUid)) following.add(targetUid);
    if (!followers.contains(myUid)) followers.add(myUid);

    txn.update(userRef, {'following': following});
    txn.update(targetRef, {'follower': followers});
  });

  final mySnap = await FirebaseFirestore.instance.collection('users').doc(myUid).get();
  final myData = mySnap.data() ?? {};
  final fromNickname = myData['nickname'] ?? '';
  final fromProfileImg = myData['profileImage'] ?? '';

  await sendFollowNotification(
    fromUid: myUid,
    fromNickname: fromNickname,
    fromProfileImg: fromProfileImg,
    toUid: targetUid,
  );

  onComplete(); // UI 업데이트 등
}

/// ➖ 언팔로우 수행 함수
Future<void> unfollowUser({
  required String targetUid,
  required void Function() onComplete,
}) async {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null || targetUid == myUid) return;

  final userRef = FirebaseFirestore.instance.collection('users').doc(myUid);
  final targetRef = FirebaseFirestore.instance.collection('users').doc(targetUid);

  await FirebaseFirestore.instance.runTransaction((txn) async {
    final mySnap = await txn.get(userRef);
    final targetSnap = await txn.get(targetRef);

    List<dynamic> following = (mySnap.data()?['following'] ?? []) as List<dynamic>;
    List<dynamic> followers = (targetSnap.data()?['follower'] ?? []) as List<dynamic>;

    following.remove(targetUid);
    followers.remove(myUid);

    txn.update(userRef, {'following': following});
    txn.update(targetRef, {'follower': followers});
  });

  onComplete(); // UI 업데이트 등
}