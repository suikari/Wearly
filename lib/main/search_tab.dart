import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../provider/custom_colors.dart';
import 'search_result_page.dart';


class SearchTab extends StatefulWidget {
  final void Function(String userId) onUserTap;
  final void Function(String tags) onFeedTap;

  const SearchTab({Key? key,
    required this.onUserTap,
    required this.onFeedTap,
  }) : super(key: key);

  @override
  _SearchTabState createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  double minTemp = 10;
  double maxTemp = 30;
  final TextEditingController _searchController = TextEditingController();

  List<String> popularTags = [
  ];
  Set<String> selectedTags = {};

  @override
  void initState() {
    super.initState();
    fetchPopularTags();
  }

  Future<void> fetchPopularTags() async {
    final fs = FirebaseFirestore.instance;
    try {
      final feedSnapshot = await fs.collection('feeds').get();

      Map<String, int> tagCountMap = {};

      for (var doc in feedSnapshot.docs) {
        final tags = doc.get('tags') as List<dynamic>? ?? [];
        for (var tag in tags) {
          tagCountMap[tag.toString()] = (tagCountMap[tag.toString()] ?? 0) + 1;
        }
      }

      final sortedTags = tagCountMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topTags = sortedTags.take(5).map((e) => e.key).toList();

      setState(() {
        //print('popularTags>>$popularTags');
        popularTags = topTags;
      });
    } catch (e) {
      print('Error fetching popular tags: $e');
      // 실패 시 기존 popularTags 유지 또는 다른 처리 가능
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white;
    Color white = customColors?.textWhite ?? Colors.white;

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 기존 코드 그대로...
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '검색어를 입력하세요',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  ),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  // if (_searchController.text.trim().isEmpty) {
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(
                  //       content: Text('최소 1개의 검색어를 입력하세요.'),
                  //       backgroundColor: Colors.redAccent,
                  //     ),
                  //   );
                  //   return;
                  // }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SearchResultPage(
                          keyword: _searchController.text.trim(),
                          minTemp: minTemp,
                          maxTemp: maxTemp,
                          selectedTags: selectedTags.toList(),
                          onUserTap  : widget.onUserTap
                      ),
                    ),
                  );
                },
                child: Text('검색'),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('온도 범위 설정 (°C)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Text('최저: ${minTemp.toInt()}°'),
              Expanded(
                child: Slider(
                  min: -20,
                  max: 40,
                  divisions: 60,
                  value: minTemp,
                  label: minTemp.toInt().toString(),
                  activeColor: Colors.blue,
                  onChanged: (value) {
                    setState(() {
                      if (value <= maxTemp) minTemp = value;
                    });
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text('최고: ${maxTemp.toInt()}°'),
              Expanded(
                child: Slider(
                  min: -20,
                  max: 40,
                  divisions: 60,
                  value: maxTemp,
                  label: maxTemp.toInt().toString(),
                  activeColor: Colors.red,
                  onChanged: (value) {
                    setState(() {
                      if (value >= minTemp) maxTemp = value;
                    });
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text('인기 태그', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: popularTags.map((tag) {
              final isSelected = selectedTags.contains(tag);
              return ChoiceChip(
                label: Text(
                  tag,
                  style: TextStyle(color: white),
                ),
                selected: isSelected,
                backgroundColor: mainColor,
                selectedColor: pointColor,
                onSelected: (selected) {
                  setState(() {
                    if (selected)
                      selectedTags.add(tag);
                    else
                      selectedTags.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
