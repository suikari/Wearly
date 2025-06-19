import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../common/custom_bottom_navbar.dart';

// 카드 배경색
const kFeedBgColor = Color(0xFFfff5f8);

class ClosetPage extends StatefulWidget {
  final List<Map<String, dynamic>> hourlyWeather;
  // currentUserId는 실제로 Auth 등에서 받아와야 함!
  final String currentUserId;
  const ClosetPage({
    super.key,
    required this.hourlyWeather,
    required this.currentUserId,
  });

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  int _selectedNavIndex = 0;
  Timer? _timer;
  int? currentHour;

  // "내 코디"/"다른 사람 코디" 탭
  int _tabIndex = 0; // 0=내 코디, 1=다른 사람 코디
  final List<String> _mainTabs = ['내 코디', '다른 사람 코디'];

  // "추웠어요/적당해요/더웠어요"
  final List<String> _feelingTabs = ['적당했어요', '추웠어요', '더웠어요'];
  String _selectedFeeling = '적당했어요';

  // for pull-to-refresh(온도 갱신)
  late List<Map<String, dynamic>> _hourlyWeather;

  @override
  void initState() {
    super.initState();
    _hourlyWeather = widget.hourlyWeather;
    _updateHour();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateHour());
  }

  void _updateHour() {
    final now = DateTime.now();
    setState(() {
      currentHour = now.hour;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<int> getHourList() {
    final hour = currentHour ?? DateTime.now().hour;
    return List.generate(8, (i) => (hour + i) % 24);
  }

  double? getClosestTempForHour(int targetHour) {
    int minDiff = 25;
    double? temp;
    for (final item in _hourlyWeather) {
      final fcstHour = int.parse(item['fcstTime'].substring(0, 2));
      final diff = (fcstHour - targetHour).abs();
      if (diff < minDiff) {
        minDiff = diff;
        temp = double.tryParse(item['temp'].toString());
      }
    }
    return temp;
  }

  // [추가] 새로고침시 HomeContent로 pop했다가 다시 push하는 패턴(최신화, 권장)
  Future<void> _onRefresh(BuildContext context) async {
    Navigator.of(context).pop();
    // 새로고침하면 HomeContent에서 최신 hourlyWeather로 다시 ClosetPage 진입하면 됨!
  }

  @override
  Widget build(BuildContext context) {
    final hourList = getHourList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ==== 시간별 날씨 ====
              Container(
                color: const Color(0xfff7f8fd),
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SizedBox(
                  height: 88,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: hourList.length,
                    itemBuilder: (context, idx) {
                      final hour = hourList[idx];
                      final temp = getClosestTempForHour(hour);
                      return Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${hour.toString().padLeft(2, '0')}시',
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            const Icon(Icons.cloud, color: Color(0xff868eb6), size: 22),
                            const SizedBox(height: 2),
                            Text(
                              temp != null ? '${temp.toStringAsFixed(1)}°' : '-',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // ======= "내 코디/다른 사람 코디" 탭 =======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  children: List.generate(_mainTabs.length, (i) {
                    final isSelected = _tabIndex == i;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tabIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: i != _mainTabs.length - 1 ? 8 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xfffff0f6),
                            border: isSelected
                                ? Border.all(color: Colors.pinkAccent, width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _mainTabs[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.pink : Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // ======= 필터 탭 =======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: List.generate(_feelingTabs.length, (i) {
                    final label = _feelingTabs[i];
                    final isSelected = _selectedFeeling == label;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedFeeling = label),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: EdgeInsets.only(right: i != _feelingTabs.length - 1 ? 6 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xfff9e8ee),
                            border: isSelected
                                ? Border.all(color: Colors.pinkAccent, width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.pink : Colors.black54,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 10),
              FeedGrid(
                feeling: _selectedFeeling,
                isMine: _tabIndex == 0,
                currentUserId: widget.currentUserId,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: (i) {
          setState(() => _selectedNavIndex = i);
        },
      ),
    );
  }
}

class FeedGrid extends StatelessWidget {
  final String feeling;
  final bool isMine; // true: 내 코디, false: 다른 사람 코디
  final String currentUserId;
  const FeedGrid({
    super.key,
    required this.feeling,
    required this.isMine,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
        .collection('feeds')
        .where('feeling', isEqualTo: feeling);

    // Firestore에 피드 작성자 식별자 필드가 'userId'라고 가정!
    baseQuery = isMine
        ? baseQuery.where('userId', isEqualTo: currentUserId)
        : baseQuery.where('userId', isNotEqualTo: currentUserId);

    baseQuery = baseQuery.orderBy('cdatetime', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: baseQuery.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: Text("피드가 없습니다.", style: TextStyle(color: Colors.black38))),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2열 그리드
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.84,
            ),
            itemBuilder: (context, idx) {
              final data = docs[idx].data() as Map<String, dynamic>;
              final List<dynamic>? images = data['imageUrls'];
              final tags = data['tags']?.cast<String>() ?? [];
              final content = data['content'] ?? '';
              return FeedCard(
                imageUrl: (images != null && images.isNotEmpty) ? images[0] : null,
                tags: tags,
                content: content,
              );
            },
          ),
        );
      },
    );
  }
}

class FeedCard extends StatelessWidget {
  final String? imageUrl;
  final List<String> tags;
  final String content;

  const FeedCard({super.key, this.imageUrl, required this.tags, required this.content});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kFeedBgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.withOpacity(0.05),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 (없으면 빈 박스)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: imageUrl != null
                ? Image.network(
              imageUrl!,
              height: 92,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: 92,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // 태그
          Wrap(
            spacing: 4,
            children: tags
                .map((tag) => Text(
              "#$tag",
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xffb460a2),
                  fontWeight: FontWeight.bold),
            ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // 내용 (한줄)
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
