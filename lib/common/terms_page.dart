import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../page/signup_page.dart';
import '../provider/custom_colors.dart';
import '../provider/custom_fonts.dart';
import '../provider/theme_provider.dart';

class TermsModel {
  final String id;
  final String title;
  final String content;

  TermsModel({
    required this.id,
    required this.title,
    required this.content,
  });

  factory TermsModel.fromMap(Map<String, dynamic> map, String id) {
    return TermsModel(
      id: id,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

class TermsPage extends StatefulWidget {
  const TermsPage({Key? key}) : super(key: key);

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<List<TermsModel>> _termsFuture;

  Map<String, bool> _agreeMap = {};
  bool _agreeAll = false;

  Future<List<TermsModel>> fetchTerms() async {
    final snapshot = await _firestore.collection('terms').orderBy('order').get();
    final terms = snapshot.docs
        .map((doc) => TermsModel.fromMap(doc.data(), doc.id))
        .toList();

    for (var term in terms) {
      _agreeMap[term.id] = false;
    }
    return terms;
  }

  void _toggleAgreeAll(bool? value) {
    final checked = value ?? false;
    setState(() {
      _agreeAll = checked;
      _agreeMap.updateAll((key, _) => checked);
    });
  }


  @override
  void initState() {
    super.initState();
    _termsFuture = fetchTerms();
  }

  void _showTermsContent(
      TermsModel term,
      Color Grey,
      Color White,
      Color Black,
      final isBlackTheme,
      String font,
    ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isBlackTheme ? Color(0xFF333333) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          maxChildSize: 0.9,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isBlackTheme ? Grey : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    term.title,
                    style: TextStyle(
                        fontFamily: font, fontSize: 20, fontWeight: FontWeight.bold, color: isBlackTheme ? White : Black),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        term.content,
                        style: TextStyle(fontFamily: font, fontSize: 16, color: Grey),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

    bool get _allAgreed =>
    _agreeMap.values.isNotEmpty && _agreeMap.values.every((v) => v);

    void _onContinue() {
      if (_allAgreed) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SignupPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('모든 약관에 동의하셔야 합니다.')),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;
    Color Grey = customColors?.textGrey ?? Colors.grey;
    Color White = customColors?.textWhite ?? Colors.white;
    Color Black = customColors?.textBlack ?? Colors.black;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isBlackTheme = themeProvider.colorTheme == ColorTheme.blackTheme;
    final bgColor = isBlackTheme ? Color(0xFF333333) : Colors.white;
    final fonts = Theme.of(context).extension<CustomFonts>()!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('약관 동의'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<TermsModel>>(
          future: _termsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('약관 불러오기 실패: ${snapshot.error}'));
            }
            final terms = snapshot.data ?? [];
            if (terms.isEmpty) {
              return const Center(child: Text('등록된 약관이 없습니다.'));
            }

            return Column(
              children: [
                // 상단 여백 + 감사 이미지 영역
                Container(
                  height: 200,
                  width: double.infinity,
                  color: bgColor,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite, color: pointColor, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Wearly에 오신 것을 환영합니다!',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  thickness: 1,
                  height: 1,
                  color: highlightColor,
                ),
                // 약관 리스트
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: terms.length,
                    separatorBuilder: (_, __) => Divider(color: subColor),
                    itemBuilder: (context, index) {
                      final term = terms[index];
                      final isChecked = _agreeMap[term.id] ?? false;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _agreeMap[term.id] = !isChecked;
                            _agreeAll = _agreeMap.values.every((v) => v);
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (value) {
                                setState(() {
                                  _agreeMap[term.id] = value ?? false;
                                  _agreeAll = _agreeMap.values.every((v) => v);
                                });
                              },
                              activeColor: mainColor,
                              checkColor: Colors.white,
                              side: const BorderSide(color: Colors.grey),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      term.title,
                                      style: TextStyle(fontFamily: fonts.labelFont, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showTermsContent(term,Grey,White,Black,isBlackTheme, fonts.labelFont,),
                                    icon: Icon(Icons.expand_more,color: Colors.grey,),
                                    label: Text('전문보기', style: TextStyle(fontFamily: fonts.labelFont, ),),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Grey,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(10, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Divider(
                  thickness: 1,
                  height: 1,
                  color: highlightColor,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CheckboxListTile(
                    title: Text('전체 약관에 동의합니다', style: TextStyle(fontFamily: fonts.labelFont, fontWeight: FontWeight.bold)),
                    value: _agreeAll,
                    onChanged: _toggleAgreeAll,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: mainColor,
                    checkColor: Colors.white,
                    side: const BorderSide(color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 35.0, top: 8.0), // 👈 하단 공간 줄이기
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.9,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _allAgreed ? _onContinue : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        foregroundColor: White,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('동의하고 회원가입으로 이동',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}