import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../common/custom_app_bar.dart';
import '../firebase_options.dart';


class SearchResultPage extends StatefulWidget {
  final String keyword;

  const SearchResultPage({super.key, required this.keyword});

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;



  late TabController _tabController;
  String selectedSort = '최신순';

  final List<String> tabs = ['태그', '지역', '내용', '유저'];
  final List<String> sortOptions = ['최신순', '좋아요순', '조회수순', '온도순'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    final FirebaseFirestore fs = FirebaseFirestore.instance;

    return Scaffold(
      appBar:  CustomAppBar(title: '검색 결과'),
      // AppBar(
      //   title: Text('검색 결과'),
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색어 안내
          Padding(
            padding: const EdgeInsets.all(12.0),
            child:
            Text(
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
              tabs: tabs.map((tab) => Tab(text: tab)).toList(),
            ),
          ),

          // 정렬 버튼
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

          // 탭 콘텐츠
          Expanded(
              child: StreamBuilder(
                stream: fs.collection("adItems").snapshots(),
                builder: (context, snapshot) {

                  if (snapshot.hasError) {
                    return Center(child: Text('Error==: ${snapshot.error}'));
                  }
                  if(!snapshot.hasData) {

                    return Center(child: CircularProgressIndicator(),);
                  }
                  final docs = snapshot.data!.docs;
                  // print("테스트================> + ${docs}");
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];

                      return ListTile(
                        title : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("작성자: ${doc["imageUrl"]} "),
                            Text(" 내용 ${doc["itemName"]}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize : MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: ()=>{},
                              icon: Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: ()=> {},
                              icon: Icon(Icons.delete),
                            )
                          ],
                        ),
                      );

                    },
                  );
                },
              )
          )
          // Expanded(
          //   child: TabBarView(
          //     controller: _tabController,
          //     children: tabs.map((tab) => _buildTabContent(tab)).toList(),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildTabContent(String category) {
    return Center(
      child: Text(
        '$category 결과 (${selectedSort} 기준)',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
