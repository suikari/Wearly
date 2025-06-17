import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../common/custom_app_bar.dart';

class SearchResultPage extends StatefulWidget {
  final String keyword;

  const SearchResultPage({super.key, required this.keyword});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> with SingleTickerProviderStateMixin {

  int _selectedIndex = 0;


  late TabController _tabController;

  final List<String> tabs = ['태그', '지역', '내용', '유저'];
  final List<String> sortOptions = ['최신순', '좋아요순', '조회수순', '온도순'];
  String selectedSort = '최신순';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  Widget build(BuildContext context) {

    final FirebaseFirestore fs = FirebaseFirestore.instance;

    return Scaffold(
      appBar: CustomAppBar(title: '검색 결과'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '"${widget.keyword}"에 대한 검색 결과입니다.',
              style: const TextStyle(fontSize: 16),
            ),
          ),
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
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              tabs: tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 6),
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() {
                    selectedSort = value;
                  });
                },
                itemBuilder: (context) {
                  return sortOptions
                      .map((option) => PopupMenuItem(
                    value: option,
                    child: Text(option),
                  ))
                      .toList();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedSort,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
           
            child: StreamBuilder<QuerySnapshot>(
              stream: fs.collection("feeds").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('에러 발생: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 제목에 키워드 포함 필터링
                final docs = snapshot.data!.docs.where((doc) {
                  final title = doc['title']?.toString().toLowerCase() ?? '';
                  return title.contains(widget.keyword.toLowerCase());
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('검색 결과가 없습니다.'));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];

                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("작성자: ${doc["content"] ?? "알 수 없음"}"),
                          Text("제목: ${doc["title"] ?? "없음"}"),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () {
                              // 수정 기능 추가 예정
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              // 삭제 기능 추가 예정
                            },
                            icon: const Icon(Icons.delete),
                          )
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

            child: TabBarView(
              controller: _tabController,
              children: tabs.map((tab) => _buildTabContent(tab)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String category) {
    final FirebaseFirestore fs = FirebaseFirestore.instance;

    // 정렬 필드 설정
    String orderByField;
    switch (selectedSort) {
      case '좋아요순':
        orderByField = 'likes';
        break;
      case '조회수순':
        orderByField = 'views';
        break;
      case '온도순':
        orderByField = 'temperature';
        break;
      case '최신순':
      default:
        orderByField = 'createdAt';
    }

    // 탭별 필터링
    Query<Map<String, dynamic>> query = fs.collection("feeds");

    if (category == '태그') {
      query = query.where("imageUrls", arrayContains: widget.keyword);
    } else if (category == '지역') {
      query = query.where("temperature", isEqualTo: widget.keyword);
    } else if (category == '내용') {
      query = query.where("content", isGreaterThanOrEqualTo: widget.keyword);
    } else if (category == '유저') {
      query = query.where("feeling", isEqualTo: widget.keyword);
    }

    query = query.orderBy(orderByField, descending: true);

    return StreamBuilder(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text('검색 결과가 없습니다.'));
        }

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return ListTile(
              title: Text(doc['title'] ?? '제목 없음'),
              subtitle: Text('작성자: ${doc['cdatetime'] ?? '알 수 없음'}'),
            );
          },
        );
      },
    );
  }

}
