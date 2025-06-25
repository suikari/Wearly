import 'package:flutter/material.dart';
import 'widget/comment_list.dart'; // 댓글 컴포넌트 import
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailPage extends StatefulWidget {
  final String feedId;
  final VoidCallback onBack;
  final String currentUserId;
  final bool showAppBar;

  const DetailPage({
    Key? key,
    required this.feedId,
    required this.onBack,
    required this.currentUserId,
    this.showAppBar = false,
  }) : super(key: key);

  @override
  _DetailPageState createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  DocumentSnapshot? feedData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFeedData();
  }

  Future<void> fetchFeedData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('feeds')
          .doc(widget.feedId)
          .get();
      setState(() {
        feedData = snapshot;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching feed data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateMainCoordiId(String newMainCoordiId) async {
    print("1123currentUserId>>>>>?${widget.currentUserId}");
    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUserId);

      await docRef.update({'mainCoordiId': newMainCoordiId});

      // 업데이트 성공 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('대표 코디가 성공적으로 설정되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // 오류 발생 시 스낵바 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('대표 코디 설정 중 오류 발생: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = isLoading
        ? const Center(child: CircularProgressIndicator())
        : feedData == null
        ? const Center(child: Text("피드를 불러올 수 없습니다."))
        : SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.showAppBar)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                ),
                const SizedBox(width: 8),
                Text(
                  feedData!['title'].length > 8 ? '${feedData!['title'].substring(0, 8)}...'
                      : feedData!['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    //color: selectedItemColor,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    // 메뉴 선택 시 동작
                    if (value == 'edit') {
                      print("Edit 선택됨");
                    } else if (value == 'del') {
                      print("Delete 선택됨");
                    } else if (value == 'main') {
                      updateMainCoordiId(feedData!.id);
                    }
                  },
                  itemBuilder:
                      (BuildContext context) =>
                  <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('수정'),
                    ),
                    PopupMenuItem<String>(
                      value: 'del',
                      child: Text('삭제'),
                    ),
                    PopupMenuItem<String>(
                      value: 'main',
                      child: Text('대표설정'),
                    ),
                  ],
                )
              ],
            ),
          if (!widget.showAppBar) const SizedBox(height: 8),
          Text("온도: ${feedData!['temperature'] ?? 'N/A'}°C"),
          Text("작성일시: ${formatTimestamp(feedData!['cdatetime'])}"),
          const SizedBox(height: 16),
          feedData!['imageUrls'] != null
              ? _buildImageCarousel(
            (feedData!['imageUrls'] as List<dynamic>)
                .map((e) => e.toString())
                .toList(),
          )
              : Container(height: 200, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("내용",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(feedData!['content'] ?? ''),
          const Divider(height: 40),
          CommentSection(
            key: ValueKey("comment_${widget.feedId}"),
            feedId: widget.feedId,
            currentUserId: widget.currentUserId,
          ),
        ],
      ),
    );

    if (widget.showAppBar) {
      return WillPopScope(
        onWillPop: () async {
          // 뒤로가기 막기
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(feedData?['title'] ?? ''),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.home),
                tooltip: '홈으로 이동',
                onPressed: widget.onBack,
              )
            ],
          ),
          body: bodyContent,
        ),
      );
    } else {
      return WillPopScope(
        onWillPop: () async {
          widget.onBack();
          return false;
        },
        child: Scaffold(
          body: bodyContent,
        ),
      );
    }
  }
}

// 이미지 캐러셀 함수는 이전과 동일하게 사용
Widget _buildImageCarousel(List<String> imageUrls) {
  if (imageUrls.isEmpty) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          topRight: Radius.circular(50),
        ),
      ),
      alignment: Alignment.center,
      child: const Text('이미지가 없습니다'),
    );
  } else if (imageUrls.length == 1) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(50),
        topRight: Radius.circular(50),
      ),
      child: Image.network(
        imageUrls[0],
        height: 480,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  } else {
    return SizedBox(
      height: 480,
      child: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(50),
              topRight: Radius.circular(50),
            ),
            child: Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          );
        },
      ),
    );
  }
}
