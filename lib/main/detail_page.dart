import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../provider/custom_colors.dart';
import '../provider/theme_provider.dart';
import 'edit_post_page.dart';
import 'widget/comment_list.dart';
import 'widget/image_carousel_card.dart';

class DetailPage extends StatefulWidget {
  final String feedId;
  final VoidCallback onBack;
  final String currentUserId;
  final bool showAppBar;
  final void Function(String)? onUserTap; // ← 콜백 타입 정의

  const DetailPage({
    Key? key,
    required this.feedId,
    required this.onBack,
    required this.currentUserId,
    this.showAppBar = false,
    this.onUserTap,
  }) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Map<String, dynamic>? feedData;
  bool isLoading = true;
  bool isLiked = false;
  int likeCount = 0;

  final FirebaseFirestore fs = FirebaseFirestore.instance;
  final GlobalKey qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchFeedData();
  }

  Future<void> fetchFeedData() async {
    try {
      final doc = await fs.collection('feeds').doc(widget.feedId).get();
      if (!doc.exists) throw Exception("Feed not found");

      final data = doc.data()!;
      data['id'] = doc.id;

      final writeId = data['writeid'];
      if (writeId != null && writeId.toString().isNotEmpty) {
        final writerDoc = await fs.collection('users').doc(writeId).get();
        if (writerDoc.exists) {
          data['writerInfo'] = {...writerDoc.data()!, 'docId': writerDoc.id};
        }
      }

      final result = await getLikeStatusAndCount(widget.feedId);

      setState(() {
        feedData = data;
        isLiked = result['isLiked'];
        likeCount = result['likeCount'];
        isLoading = false;
      });
    } catch (e) {
      print("피드 로딩 오류: $e");
      setState(() => isLoading = false);
    }
  }

  Future<Map<String, dynamic>> getLikeStatusAndCount(String feedId) async {
    try {
      final likeDoc = await fs.collection('feeds').doc(feedId).collection('likes').doc(widget.currentUserId).get();
      final likeSnapshot = await fs.collection('feeds').doc(feedId).collection('likes').get();
      return {'isLiked': likeDoc.exists, 'likeCount': likeSnapshot.size};
    } catch (e) {
      print('좋아요 상태 오류: $e');
      return {'isLiked': false, 'likeCount': 0};
    }
  }



  Future<void> toggleLike(Map<String, dynamic> feed) async {
    final feedId = feed['id'];
    final writeUesrid = feed['writerInfo']?['docId'];
    final feedTitle = feed['title'];

    try {
      final currentLiked = isLiked;

      setState(() {
        isLiked = !currentLiked;
        likeCount += currentLiked ? -1 : 1;
      });

      final likeRef = fs.collection('feeds').doc(feedId).collection('likes').doc(widget.currentUserId);
      final userRef = fs.collection('users').doc(widget.currentUserId).collection('likedFeeds').doc(feedId);

      if (currentLiked) {
        await Future.wait([likeRef.delete(), userRef.delete()]);
      } else {
        await FirebaseFirestore.instance.collection('notifications').add({
          'uid' : writeUesrid, // 알림 받을 사람(피드 주인)
          'type' : 'comment',
          'fromUid': widget.currentUserId,
          'content': '($feedTitle)게시글을 좋아합니다. ',
          'postId': feedId,
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
        });

        await Future.wait([
          likeRef.set({'userId': widget.currentUserId, 'createdAt': FieldValue.serverTimestamp()}),
          userRef.set({'feedId': feedId, 'createdAt': FieldValue.serverTimestamp()}),
        ]);
      }
    } catch (e) {
      print("좋아요 오류: $e");
    }
  }

  Future<void> deleteFeed(String feedId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('피드 삭제'),
        content: Text('정말 이 피드를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return; // 사용자가 '삭제'를 누르지 않았다면 종료

    try {
      await fs.collection('feeds').doc(feedId).delete();

      widget.onBack();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드가 삭제되었습니다')),
      );
    } catch (e) {
      print('피드 삭제 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('피드 삭제 중 오류가 발생했습니다')),
      );
    }
  }


  Future<void> updateMainCoordiId(String feedId) async {
    try {
      await fs.collection('users').doc(widget.currentUserId).update({'mainCoordiId': feedId});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('대표 코디가 설정되었습니다'), backgroundColor: Colors.green),
      );
    } catch (e) {
      print("대표 설정 오류: $e");
    }
  }

  void showShareBottomSheet(BuildContext context, String feedId) {
    final url = 'wearly://deeplink/feedid?id=$feedId';
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('피드 공유하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              RepaintBoundary(
                key: qrKey,
                child: QrImageView(
                  data: url,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              SelectableText(url, maxLines: 3),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await Future.delayed(Duration(milliseconds: 300));
                        RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
                        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
                        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                        Uint8List pngBytes = byteData!.buffer.asUint8List();
                        final tempDir = await getTemporaryDirectory();
                        final file = await File('${tempDir.path}/qr.png').create();
                        await file.writeAsBytes(pngBytes);
                        await Share.shareXFiles([XFile(file.path)], text: 'QR 코드로 공유된 피드입니다');
                      } catch (e) {
                        print('QR 공유 실패: $e');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR 공유 중 오류 발생')));
                      }
                    },
                    child: Text('QR 공유'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('링크가 복사되었습니다')));
                    },
                    child: Text('링크 복사'),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    final subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;

    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : feedData == null
          ? Center(child: Text("피드를 불러올 수 없습니다."))
          : SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchFeedData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: widget.onBack,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedData!['title'] ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (feedData!['writeid'] == widget.currentUserId)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditPostPage(feedId: feedData!['id']),
                            ),
                          );
                        } else if (value == 'del') {
                          deleteFeed(feedData!['id']);
                        } else if (value == 'main') {
                          updateMainCoordiId(feedData!['id']);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: 'edit', child: Text('수정')),
                        PopupMenuItem(value: 'del', child: Text('삭제')),
                        PopupMenuItem(value: 'main', child: Text('대표설정')),
                      ],
                    ),
                ],
              ),
              SizedBox(height: 12),
              ImageCarouselCard(
                imageUrls: List<String>.from(feedData!['imageUrls'] ?? []),
                cardcolor: subColor,
                pointColor : pointColor,
                profileImageUrl: feedData!['writerInfo']?['profileImage'] ?? '',
                userName: feedData!['writerInfo']?['nickname'] ?? '',
                onUserTap: () {
                  final docId = feedData!['writerInfo']?['docId'] ?? '';
                  // 이동 처리
                },
                onShareTap: () => showShareBottomSheet(context, feedData!['id']),
                isLiked: isLiked,
                likeCount: likeCount,
                onLikeToggle: () => toggleLike(feedData!),
              ),
              SizedBox(height: 16),
              Text(feedData!['content'] ?? '', style: TextStyle(fontSize: 16)),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(feedData!['location'] ?? '', style: TextStyle(color: Colors.grey)),
                  Text(DateFormat('yyyy-MM-dd HH:mm').format((feedData!['cdatetime'] as Timestamp).toDate()), style: TextStyle(color: Colors.grey)),
                ],
              ),
              Divider(height: 32),
              CommentSection(
                key: ValueKey("comment_${feedData!['id']}"),
                feedId: feedData!['id'],
                currentUserId: widget.currentUserId,
                onUserTap: widget.onUserTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
