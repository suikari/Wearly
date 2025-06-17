import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../common/custom_app_bar.dart';

class SearchResultPage extends StatefulWidget {
  final String keyword;

  const SearchResultPage({super.key, required this.keyword});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  String selectedSort = '최신순';

  final List<String> tabs = ['태그', '지역', '내용', '유저'];
  final List<String> sortOptions = ['최신순', '좋아요순', '조회수순', '온도순'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this)
      ..addListener(() {
        if (_tabController.index != _selectedIndex) {
          setState(() => _selectedIndex = _tabController.index);
        }
      });
  }

  /// 정렬 옵션에 대응하는 Firestore 필드명 반환
  String getSortField(String option) {
    switch (option) {
      case '좋아요순':
        return 'likeCount';
      case '조회수순':
        return 'viewCount';
      case '온도순':
        return 'temperature';
      case '최신순':
      default:
        return 'createdAt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final kw = widget.keyword.toLowerCase().trim();

    return Scaffold(
      appBar: CustomAppBar(title: '검색 결과'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색어 안내
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '"${widget.keyword}"에 대한 검색 결과입니다.',
              style: const TextStyle(fontSize: 16),
            ),
          ),

          // 탭바
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.blue.shade200),
                bottom: BorderSide(color: Colors.blue.shade200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.redAccent,
              unselectedLabelColor: Colors.black87,
              indicatorColor: Colors.redAccent,
              tabs: tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),

          // 정렬 선택
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (value) => setState(() => selectedSort = value),
                itemBuilder: (_) => sortOptions
                    .map((opt) => PopupMenuItem(value: opt, child: Text(opt)))
                    .toList(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(selectedSort,
                        style: TextStyle(color: Colors.grey.shade600)),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          ),

          // 탭별 콘텐츠
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _selectedIndex == 0
                  ? fs.collection("tags").snapshots()
                  : _selectedIndex == 1 || _selectedIndex == 2
                  ? fs
                  .collection("feeds").snapshots()
                  : fs.collection("users").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  switch (_selectedIndex) {
                    case 0: // 태그
                      final content =
                      (data['content'] ?? '').toString().toLowerCase();
                      return content.contains(kw);
                    case 1: // 지역
                      final location =
                      (data['location'] ?? '').toString().toLowerCase();
                      return location.contains(kw);
                    case 2: // 내용
                      final title =
                      (data['title'] ?? '').toString().toLowerCase();
                      final content =
                      (data['content'] ?? '').toString().toLowerCase();
                      return title.contains(kw) || content.contains(kw);
                    case 3: // 유저
                      final nickname =
                      (data['nickname'] ?? '').toString().toLowerCase();
                      return nickname.contains(kw);
                    default:
                      return false;
                  }
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('검색 결과가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_selectedIndex == 0) ...[
                            Text("태그 내용: ${data['content'] ?? '없음'}"),
                            Text("카테고리: ${data['category'] ?? '없음'}"),
                          ] else if (_selectedIndex == 1) ...[
                            Text("지역: ${data['location'] ?? '없음'}"),
                          ] else if (_selectedIndex == 2) ...[
                            Text("제목: ${data['title'] ?? '없음'}"),
                            Text("내용: ${data['content'] ?? '없음'}"),
                          ] else if (_selectedIndex == 3) ...[
                            Text("닉네임: ${data['nickname'] ?? '없음'}"),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Icon(Icons.delete),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
