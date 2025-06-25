import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

const kFeedBgColor = Color(0xFFfff5f8);

class ClosetPage extends StatefulWidget {
  final List<Map<String, dynamic>> hourlyWeather;
  final String currentUserId;
  final int? currentTemperature; // null 허용

  const ClosetPage({
    super.key,
    required this.hourlyWeather,
    required this.currentUserId,
    this.currentTemperature,
  });

  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  Timer? _timer;
  int? currentHour;

  int _tabIndex = 0;
  final List<String> _mainTabs = ['내 코디', '다른 사람 코디'];
  final List<String> _feelingTabs = ['적당해요', '추웠어요', '더웠어요'];
  String _selectedFeeling = '적당해요';

  late List<Map<String, dynamic>> _hourlyWeather;

  @override
  void initState() {
    super.initState();
    _hourlyWeather = widget.hourlyWeather ?? [];
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
      if (item['fcstTime'] == null || item['temp'] == null) continue;
      final fcstHour = int.tryParse(item['fcstTime'].substring(0, 2));
      if (fcstHour == null) continue;
      final diff = (fcstHour - targetHour).abs();
      if (diff < minDiff) {
        minDiff = diff;
        temp = double.tryParse(item['temp'].toString());
      }
    }
    return temp;
  }

  int get displayTemperature {
    // 0, null이 오면 시간별 데이터에서 보정
    if (widget.currentTemperature != null && widget.currentTemperature != 0) {
      return widget.currentTemperature!;
    } else {
      final nowHour = DateTime.now().hour;
      final nowTemp = getClosestTempForHour(nowHour);
      return nowTemp?.round() ?? 22; // 못 찾으면 22도
    }
  }

  Future<void> _onRefresh(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('메인에서 새로고침 후 다시 옷장에 진입해주세요!')),
    );
    await Future.delayed(const Duration(milliseconds: 600));
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final hourList = getHourList();

    if (_hourlyWeather.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Text(
            "날씨 데이터가 없습니다.\n메인에서 새로고침 후 다시 시도해주세요.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
        ),
      );
    }

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

              // ================= 피드 그리드 =================
              FeedGrid(
                feeling: _selectedFeeling,
                isMine: _tabIndex == 0,
                currentUserId: widget.currentUserId,
                temperature: displayTemperature, // ★★★
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= FeedGrid =================

class FeedGrid extends StatefulWidget {
  final String feeling;
  final bool isMine;
  final String currentUserId;
  final int temperature;
  const FeedGrid({
    super.key,
    required this.feeling,
    required this.isMine,
    required this.currentUserId,
    required this.temperature,
  });

  @override
  State<FeedGrid> createState() => _FeedGridState();
}

class _FeedGridState extends State<FeedGrid> {
  List<Map<String, dynamic>> feedItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFeeds();
  }

  Future<void> fetchFeeds() async {
    setState(() { isLoading = true; });
    try {
      // print('---[FeedGrid] fetchFeeds start---');
      // print('필터: feeling=${widget.feeling}, isMine=${widget.isMine}, currentUserId=${widget.currentUserId}, temperature=${widget.temperature}');
      final snapshot = await FirebaseFirestore.instance
          .collection('feeds')
          .where('feeling', isEqualTo: widget.feeling)
          .orderBy('cdatetime', descending: true)
          .get();

      // print('[Firestore] 받은 문서 개수: ${snapshot.docs.length}');
      int filteredCount = 0;

      final items = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((data) {
        final tempRaw = data['temperature'];
        final temp = tempRaw is int
            ? tempRaw
            : int.tryParse(tempRaw.toString().split('.').first ?? '');

        final writeid = data['writeid'];
        final bool tempMatch = temp != null && (temp - widget.temperature).abs() <= 2;
        final bool idMatch = widget.isMine
            ? writeid == widget.currentUserId
            : writeid != widget.currentUserId;

        // print('[doc ${data['id']}] temp=$temp, writeid=$writeid, tempMatch=$tempMatch, idMatch=$idMatch, 전체조건=${tempMatch && idMatch}');
        // print('  Firestore feeling=${data['feeling']}, tags=${data['tags']}, content=${data['content']}');
        if (tempMatch && idMatch) filteredCount++;
        return tempMatch && idMatch;
      }).toList();

      // print('[FeedGrid] 필터링 후 피드 개수: $filteredCount');

      setState(() {
        feedItems = items;
        isLoading = false;
      });
      // print('---[FeedGrid] fetchFeeds end---');
    } catch (e) {
      setState(() {
        feedItems = [];
        isLoading = false;
      });
      // print('[FeedGrid] 에러 발생: $e');
    }
  }

  @override
  void didUpdateWidget(covariant FeedGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.feeling != widget.feeling ||
        oldWidget.isMine != widget.isMine ||
        oldWidget.temperature != widget.temperature) {
      fetchFeeds();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (feedItems.isEmpty) {
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
        itemCount: feedItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.70,
        ),
        itemBuilder: (context, idx) {
          final data = feedItems[idx];
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
  }
}

// ================= FeedCard =================

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
          // 이미지: 고정 height X, 비율만 맞춤!
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1, // 정사각형 사진(1:1), 세로로 길게 하고 싶으면 0.9~1.2
              child: imageUrl != null
                  ? Image.network(
                imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
              )
                  : Container(color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
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
