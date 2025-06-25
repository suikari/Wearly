import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../common/custom_app_bar.dart';
import '../provider/custom_colors.dart';
import 'widget/followService.dart';

class SearchResultPage extends StatefulWidget {
  final String keyword;
  final double minTemp;
  final double maxTemp;
  final List<String> selectedTags;

  const SearchResultPage({super.key, required this.keyword, required this.minTemp, required this.maxTemp, required this.selectedTags});
  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;
  String selectedSort = '최신순';

  final List<String> tabs = ['태그', '지역', '내용', '유저'];
  final List<String> sortOptions = ['최신순', '온도순'];

  final String? myUid = FirebaseAuth.instance.currentUser?.uid;
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
      case '온도순':
        return 'temperature';
      case '최신순':
      default:
        return 'cdatetime';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;
    final kw = widget.keyword.toLowerCase().trim();
    final minTemp = widget.minTemp;
    final maxTemp = widget.maxTemp;
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white;

    return Scaffold(
      appBar: CustomAppBar(title: '검색 결과'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 검색어 안내
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              '"${widget.keyword}"에 대한 검색 결과입니다. 온도 범위 : $minTemp℃~$maxTemp℃',
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
              labelColor: mainColor,
              unselectedLabelColor: Colors.black87,
              indicatorColor: subColor,
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

          // 탭별 콘텐츠 (슬라이드 가능)
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(tabs.length, (index) {
                return buildTabContent(index, kw, fs);
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 각 탭별 콘텐츠 위젯 빌더
  Widget buildTabContent(int tabIndex, String kw, FirebaseFirestore fs) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white;
    late Stream<QuerySnapshot> stream;
    switch (tabIndex) {
      case 0:
        stream = fs.collection("feeds").orderBy(getSortField(selectedSort), descending: true).snapshots();
        break;
      case 1:
      case 2:
        stream = fs.collection("feeds").orderBy(getSortField(selectedSort), descending: true).snapshots();
        break;
      case 3:
        stream = fs.collection("users").snapshots();
        break;
      default:
        stream = const Stream.empty();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;

          final temp = data['temperature'];

          if (temp is num) {
            if (temp < widget.minTemp || temp > widget.maxTemp) {
              return false;
            }
          }

          switch (tabIndex) {
            case 0:
              final tags = data['tags'];
              if (tags is! List) return false;

              final tagStrings = tags.map((e) => e.toString().toLowerCase()).toList();
              final keywordMatched = tagStrings.any((tag) => tag.contains(kw));
              if (!keywordMatched) return false;

              if (widget.selectedTags.isNotEmpty) {
                final hasSelectedTag = widget.selectedTags.any(
                        (selected) => tagStrings.contains(selected.toLowerCase()));
                if (!hasSelectedTag) return false;
              }

              return true;
            case 1:
              final tags = data['tags'];
              if (tags is! List) return false;

              final tagStrings = tags.map((e) => e.toString().toLowerCase()).toList();

              // 선택된 태그 필터
              if (widget.selectedTags.isNotEmpty) {
                final hasSelectedTag = widget.selectedTags.any(
                        (selected) => tagStrings.contains(selected.toLowerCase()));
                if (!hasSelectedTag) return false;
              }

              // 키워드가 지역에 포함되어야 함
              final location = (data['location'] ?? '').toString().toLowerCase();
              return location.contains(kw);

            case 2:
              final tags = data['tags'];
              if (tags is! List) return false;

              final tagStrings = tags.map((e) => e.toString().toLowerCase()).toList();

              // 선택된 태그 필터
              if (widget.selectedTags.isNotEmpty) {
                final hasSelectedTag = widget.selectedTags.any(
                        (selected) => tagStrings.contains(selected.toLowerCase()));
                if (!hasSelectedTag) return false;
              }

              // 키워드가 title 또는 content에 포함되어야 함
              final title = (data['title'] ?? '').toString().toLowerCase();
              final content = (data['content'] ?? '').toString().toLowerCase();

              return title.contains(kw) || content.contains(kw);

            case 3:
              final nickname = (data['nickname'] ?? '').toString().toLowerCase();
              return nickname.contains(kw);

            default:
              return false;
          }
        }).toList();

        if (docs.isEmpty) {
          return const Center(child: Text('검색 결과가 없습니다. 필터를 확인해 주세요'));
        }

        return ListView.builder (
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final customColors = Theme.of(context).extension<CustomColors>();
            Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
            Color subColor = customColors?.subColor ?? Colors.white;
            return ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tabIndex == 0) ...[
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: mainColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            Text(
                              data['title'] ?? '제목 없음',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            // 추천/기온 뱃지
                            Row(
                              children: [
                                if (data['feeling'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: mainColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      data['feeling'],
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                if (data['temperature'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: subColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${data['temperature']}℃",
                                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 이미지
                            if (data['imageUrls'] != null &&
                                data['imageUrls'] is List &&
                                data['imageUrls'].isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['imageUrls'][0],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                            const SizedBox(height: 10),

                            // 내용 요약
                            Text(
                              data['content'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),

                            // 해시태그
                            if (data['tags'] != null && data['tags'] is List)
                              Wrap(
                                spacing: 6,
                                runSpacing: -8,
                                children: (data['tags'] as List)
                                    .map((tag) => Text(
                                  tag,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ))
                                    .toList(),
                              ),

                            const SizedBox(height: 6),

                            // 지역 + 날짜
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['location'] ?? '지역 정보 없음',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                Text(
                                  data['cdatetime'] != null
                                      ? DateFormat('yyyy.MM.dd')
                                      .format((data['cdatetime'] as Timestamp).toDate())
                                      : '',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),

                            const Divider(height: 20),

                            // 댓글 예시 (고정된 더미 데이터)
                            Row(
                              children: [
                                const SizedBox(width: 8),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const SizedBox(width: 8),
                              ],
                            )
                          ],
                        ),
                      ),
                    )
                  ] else if (tabIndex == 1) ...[
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: mainColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            Text(
                              data['title'] ?? '제목 없음',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            // 추천/기온 뱃지
                            Row(
                              children: [
                                if (data['feeling'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: pointColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      data['feeling'],
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                if (data['temperature'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: pointColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${data['temperature']}℃",
                                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 이미지
                            if (data['imageUrls'] != null &&
                                data['imageUrls'] is List &&
                                data['imageUrls'].isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['imageUrls'][0],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                            const SizedBox(height: 10),

                            // 내용 요약
                            Text(
                              data['content'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),

                            // 해시태그
                            if (data['tags'] != null && data['tags'] is List)
                              Wrap(
                                spacing: 6,
                                runSpacing: -8,
                                children: (data['tags'] as List)
                                    .map((tag) => Text(
                                  tag,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ))
                                    .toList(),
                              ),

                            const SizedBox(height: 6),

                            // 지역 + 날짜
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['location'] ?? '지역 정보 없음',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                Text(
                                  data['cdatetime'] != null
                                      ? DateFormat('yyyy.MM.dd')
                                      .format((data['cdatetime'] as Timestamp).toDate())
                                      : '',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),

                            const Divider(height: 20),
                            FutureBuilder<QuerySnapshot>(
                              future: fs
                                  .collection('feeds')
                                  .doc(docs[index].id)
                                  .collection('comment')
                                  .orderBy('cdatetime', descending: true)
                                  .limit(3)
                                  .get(),
                              builder: (context, commentSnapshot) {
                                if (!commentSnapshot.hasData) return const CircularProgressIndicator();

                                final commentDocs = commentSnapshot.data!.docs;

                                if (commentDocs.isEmpty) {
                                  return const Text("댓글이 없습니다", style: TextStyle(fontSize: 13, color: Colors.grey));
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: commentDocs.map((commentDoc) {
                                    final comment = commentDoc.data() as Map<String, dynamic>;
                                    final userId = comment['userId'];

                                    return FutureBuilder<DocumentSnapshot>(
                                      future: fs.collection('users').doc(userId).get(),
                                      builder: (context, userSnapshot) {
                                        String nickname = comment['userName'] ?? '익명';
                                        String profileUrl = '';

                                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                          nickname = userData['nickname'] ?? nickname;
                                          profileUrl = userData['profileImageUrl'] ?? '';
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundImage: profileUrl.isNotEmpty
                                                    ? NetworkImage(profileUrl)
                                                    : const AssetImage('assets/default_profile.png') as ImageProvider,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      nickname,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      comment['comment'] ?? '',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (comment['cdatetime'] != null)
                                                Text(
                                                  DateFormat('MM/dd HH:mm').format(
                                                      (comment['cdatetime'] as Timestamp).toDate()),
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  ] else if (tabIndex == 2) ...[
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: mainColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            Text(
                              data['title'] ?? '제목 없음',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),

                            // 추천/기온 뱃지
                            Row(
                              children: [
                                if (data['feeling'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    margin: const EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: mainColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      data['feeling'],
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                if (data['temperature'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: pointColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      "${data['temperature']}℃",
                                      style: const TextStyle(color: Colors.black87, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 이미지
                            if (data['imageUrls'] != null &&
                                data['imageUrls'] is List &&
                                data['imageUrls'].isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  data['imageUrls'][0],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),

                            const SizedBox(height: 10),

                            // 내용 요약
                            Text(
                              data['content'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),

                            // 해시태그
                            if (data['tags'] != null && data['tags'] is List)
                              Wrap(
                                spacing: 6,
                                runSpacing: -8,
                                children: (data['tags'] as List)
                                    .map((tag) => Text(
                                  tag,
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 13),
                                ))
                                    .toList(),
                              ),

                            const SizedBox(height: 6),

                            // 지역 + 날짜
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  data['location'] ?? '지역 정보 없음',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                                Text(
                                  data['cdatetime'] != null
                                      ? DateFormat('yyyy.MM.dd')
                                      .format((data['cdatetime'] as Timestamp).toDate())
                                      : '',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                                ),
                              ],
                            ),

                            const Divider(height: 20),
                            FutureBuilder<QuerySnapshot>(
                              future: fs
                                  .collection('feeds')
                                  .doc(docs[index].id)
                                  .collection('comment')
                                  .orderBy('cdatetime', descending: true)
                                  .limit(3)
                                  .get(),
                              builder: (context, commentSnapshot) {
                                if (!commentSnapshot.hasData) return const CircularProgressIndicator();

                                final commentDocs = commentSnapshot.data!.docs;

                                if (commentDocs.isEmpty) {
                                  return const Text("댓글이 없습니다", style: TextStyle(fontSize: 13, color: Colors.grey));
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: commentDocs.map((commentDoc) {
                                    final comment = commentDoc.data() as Map<String, dynamic>;
                                    final userId = comment['userId'];

                                    return FutureBuilder<DocumentSnapshot>(
                                      future: fs.collection('users').doc(userId).get(),
                                      builder: (context, userSnapshot) {
                                        String nickname = comment['userName'] ?? '익명';
                                        String profileUrl = '';

                                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                                          nickname = userData['nickname'] ?? nickname;
                                          profileUrl = userData['profileImage'] ?? '';
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundImage: profileUrl.isNotEmpty
                                                    ? NetworkImage(profileUrl)
                                                    : const AssetImage('assets/default_profile.png') as ImageProvider,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      nickname,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                                    ),
                                                    Text(
                                                      comment['comment'] ?? '',
                                                      style: const TextStyle(fontSize: 13),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (comment['cdatetime'] != null)
                                                Text(
                                                  DateFormat('MM/dd HH:mm').format(
                                                      (comment['cdatetime'] as Timestamp).toDate()),
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }).toList(),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  ] else if (tabIndex == 3) ...[
                    ListTile(
                      leading: CircleAvatar(
                        radius: 28,
                        backgroundImage: (data['profileImageUrl'] != null && data['profileImageUrl'].toString().isNotEmpty)
                            ? NetworkImage(data['profileImageUrl'])
                            : const AssetImage('assets/profile2.jpg') as ImageProvider,
                        backgroundColor: Colors.transparent,
                      ),
                      title: Row(
                        children: [
                          Text(
                            data['nickname'] ?? '닉네임 없음',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          if (data['interest'] != null && data['interest'] is List && data['interest'].isNotEmpty)
                            Flexible(
                              child: Text(
                                "#${(data['interest'] as List).join(', ')}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        data['bio'] ?? '자기소개 없음',
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Builder(
                        builder: (context) {
                          final followers = (data['follower'] ?? []) as List<dynamic>;
                          final isFollowing = followers.contains(myUid);

                          return ElevatedButton(
                            onPressed: isFollowing ? null
                               : () async {
                              followUser(
                                targetUid: docs[index].id,
                                onComplete: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('팔로우 완료')),
                                  );
                                  setState(() {}); // UI 갱신
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              foregroundColor: subColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                            child: Text(isFollowing ? '팔로우 중' : '팔로우'),
                          );
                        }
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}