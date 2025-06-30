import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// 날씨 상태별 아이콘 반환 함수 (기본값은 sunny)
IconData getWeatherIcon(String? weather) {
  if (weather == null) return Icons.wb_sunny;
  switch (weather.toLowerCase()) {
    case '맑음':
    case 'sunny':
      return Icons.wb_sunny;
    case '구름많음':
    case '흐림':
    case 'cloudy':
      return Icons.cloud;
    case '구름조금':
    case 'few clouds':
      return Icons.wb_cloudy;
    case '비':
    case 'rain':
      return Icons.umbrella;
    case '눈':
    case 'snow':
      return Icons.ac_unit;
    case '소나기':
    case 'shower':
      return Icons.grain;
    default:
      return Icons.wb_sunny; // 기본값
  }
}

class ClosetPage extends StatefulWidget {
  final List<Map<String, dynamic>> hourlyWeather;
  final String currentUserId;
  final int? currentTemperature;

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

  // 추가: 현재 선택된 시간 인덱스 및 선택된 시간
  int _selectedHourIndex = 0;

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
      // 최초 진입 시 현재 시간 기준 첫 인덱스로 초기화
      if (_selectedHourIndex == 0) _selectedHourIndex = 0;
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

  // 시간별 item 찾기
  Map<String, dynamic>? getClosestWeatherItemForHour(int targetHour) {
    int minDiff = 25;
    Map<String, dynamic>? found;
    for (final item in _hourlyWeather) {
      if (item['fcstTime'] == null) continue;
      final fcstHour = int.tryParse(item['fcstTime'].toString().substring(0, 2));
      if (fcstHour == null) continue;
      final diff = (fcstHour - targetHour).abs();
      if (diff < minDiff) {
        minDiff = diff;
        found = item;
      }
    }
    return found;
  }

  double? getClosestTempForHour(int targetHour) {
    return getClosestWeatherItemForHour(targetHour)?['temp'] as double?;
  }

  int get displayTemperature {
    // 선택된 시간 인덱스의 온도를 사용!
    final hourList = getHourList();
    final selectedHour = hourList[_selectedHourIndex];
    final temp = getClosestTempForHour(selectedHour);
    return temp?.round() ??
        widget.currentTemperature ??
        22; // 데이터 없으면 22 기본값
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
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Center(
          child: Text(
            "날씨 데이터가 없습니다.\n메인에서 새로고침 후 다시 시도해주세요.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(''),
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
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: SizedBox(
                  height: 88,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: hourList.length,
                    itemBuilder: (context, idx) {
                      final hour = hourList[idx];
                      final item = getClosestWeatherItemForHour(hour);
                      final temp = item?['temp'];
                      final weather = item?['weather'];
                      final isSelected = _selectedHourIndex == idx;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedHourIndex = idx;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 14),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.13)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? Border.all(
                                  color: Theme.of(context).colorScheme.primary, width: 2)
                                  : null,
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 7),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${hour.toString().padLeft(2, '0')}시',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    )),
                                const SizedBox(height: 2),
                                Icon(getWeatherIcon(weather), size: 22,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null),
                                const SizedBox(height: 2),
                                Text(
                                  temp != null ? '${temp.toString()}°' : '-',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                            border: isSelected
                                ? Border.all(width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _mainTabs[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
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
                            border: isSelected
                                ? Border.all(width: 2)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
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
                temperature: displayTemperature,
                onFeedTap: (feedId) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FeedDetailPage(feedId: feedId),
                    ),
                  );
                },
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
  final void Function(String feedId)? onFeedTap; // ★ 추가

  const FeedGrid({
    super.key,
    required this.feeling,
    required this.isMine,
    required this.currentUserId,
    required this.temperature,
    this.onFeedTap,
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
    setState(() {
      isLoading = true;
    });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('feeds')
          .where('feeling', isEqualTo: widget.feeling)
          .orderBy('cdatetime', descending: true)
          .get();

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
        final bool tempMatch =
            temp != null && (temp - widget.temperature).abs() <= 2;
        final bool idMatch = widget.isMine
            ? writeid == widget.currentUserId
            : writeid != widget.currentUserId;

        return tempMatch && idMatch;
      }).toList();

      setState(() {
        feedItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        feedItems = [];
        isLoading = false;
      });
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
        child: Center(child: Text("피드가 없습니다.")),
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
            onTap: () => widget.onFeedTap?.call(data['id']), // ★ 상세 진입 콜백
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
  final VoidCallback? onTap;

  const FeedCard({
    super.key,
    this.imageUrl,
    required this.tags,
    required this.content,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // ★ 피드 상세 진입 콜백
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.08),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 1,
                child: imageUrl != null
                    ? Image.network(
                  imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Container(),
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
                  fontWeight: FontWeight.bold,
                ),
              ))
                  .toList(),
            ),
            const SizedBox(height: 4),
            Text(
              content,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// =========== 피드 상세페이지 예시 ===========
class FeedDetailPage extends StatelessWidget {
  final String feedId;
  const FeedDetailPage({super.key, required this.feedId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('피드 상세')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('feeds').doc(feedId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return Center(child: Text('피드를 찾을 수 없습니다.'));
          }
          final images = (data['imageUrls'] as List?) ?? [];
          final tags = (data['tags'] as List?)?.cast<String>() ?? [];
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                images.isNotEmpty
                    ? Image.network(images[0], width: double.infinity, height: 230, fit: BoxFit.cover)
                    : Container(height: 230, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  children: tags.map((t) => Chip(label: Text('#$t'))).toList(),
                ),
                const SizedBox(height: 10),
                Text(data['content'] ?? '', style: TextStyle(fontSize: 16)),
                // 필요한 정보 더 추가
              ],
            ),
          );
        },
      ),
    );
  }
}
