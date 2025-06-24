import 'package:flutter/material.dart';
import '../provider/custom_colors.dart';
import 'search_result_page.dart';


class SearchTab extends StatefulWidget {
  final void Function(String userId) onUserTap;

  const SearchTab({Key? key, required this.onUserTap}) : super(key: key);

  @override
  _SearchTabState createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  bool showDetails = false;
  double minTemp = 10;
  double maxTemp = 30;
  final TextEditingController _searchController = TextEditingController();

  List<String> popularTags = [
    '반바지',
    '민소매/반팔',
    '자켓',
    '미니멀',
    '클래식',
  ];
  Set<String> selectedTags = {};





  @override
  Widget build(BuildContext context) {

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
          // 검색 상단 Row
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.filter_list),
                onPressed: () {
                  setState(() {
                    showDetails = !showDetails;
                  });
                },
              ),
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
                  if (_searchController.text.trim().isEmpty) return;

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SearchResultPage(
                        keyword: _searchController.text.trim(),
                        minTemp : minTemp,
                        maxTemp : maxTemp,
                        selectedTags: selectedTags.toList()
                      ),
                    ),
                  );
                },
                child: Text('검색'),
              ),
            ],
          ),

          // 디테일 옵션 보이기
          if (showDetails) ...[
            SizedBox(height: 16),
            Text('온도 범위 설정 (°C)', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  label: Text(tag, style: TextStyle(color: white),),
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
        ],
      ),
    );
  }
}
