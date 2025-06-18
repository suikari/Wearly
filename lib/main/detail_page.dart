import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'widget/comment_list.dart'; // 댓글 컴포넌트 import

class DetailPage extends StatefulWidget {
  final String feedId;
  final VoidCallback onBack;
  final String currentUserId;

  const DetailPage({
    Key? key,
    required this.feedId,
    required this.onBack,
    required this.currentUserId,
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

  String formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : feedData == null
          ? const Center(child: Text("피드를 불러올 수 없습니다."))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                ),
                SizedBox(width: 8), // 아이콘과 텍스트 사이 간격
                Text(
                  "${feedData!['title'] ?? ''}",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("온도: ${feedData!['temperature'] ?? 'N/A'}°C"),
            // Text("위치: ${feedData!['location'] ?? 'N/A'}"),
            Text("작성일시: ${formatTimestamp(feedData!['cdatetime'])}"),
            const SizedBox(height: 16),
            feedData!['imageUrls'] != null
                ? _buildImageCarousel(
              (feedData!['imageUrls'] as List<dynamic>).map((e) => e.toString()).toList(),
            )
                : Container(height: 200, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("내용",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(feedData!['content'] ?? ''),
            const Divider(height: 40),

            /// ✅ 기존 기능 유지하면서 댓글 위젯 삽입
            CommentSection(
              key: ValueKey("comment_${widget.feedId}"),
                feedId: widget.feedId,
                currentUserId : widget.currentUserId,
            ),
          ],
        ),
      ),
    );
  }
}


// --- 이미지 슬라이더 UI 함수 --- //
Widget _buildImageCarousel(List<String> imageUrls) {
  if (imageUrls.isEmpty) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      alignment: Alignment.center,
      child: Text('이미지가 없습니다'),
    );
  } else if (imageUrls.length == 1) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        topRight: Radius.circular(20),
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
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              topRight: Radius.circular(20),
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
