import 'package:flutter/material.dart';

class WritePostPage extends StatefulWidget {
  const WritePostPage({super.key});

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  String selectedWeather = '맑음';
  String selectedTemperature = '20℃';
  bool isPublic = true;

  final List<String> tags = [
    '#간편복', '#긴팔', '#셔츠/블라우스', '#조끼', // 상의
    '#청바지', '#트레이닝', '#숏팬츠', '#레깅스', // 하의
    '#자켓', '#가디건', '#패딩', '#코트', // 아우터
    '#원피스/치마', '#기모', '#모자/악세서리', // 기타
  ];

  final Set<String> selectedTags = {};

  void toggleTag(String tag) {
    setState(() {
      if (selectedTags.contains(tag)) {
        selectedTags.remove(tag);
      } else {
        selectedTags.add(tag);
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('글 쓰기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 업로드 영역
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink.shade200, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 48, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),

            // 제목
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력해주세요...',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink.shade200),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 내용
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '내용을 입력해주세요...',
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.pink.shade200),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('태그', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 태그 선택
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final isSelected = selectedTags.contains(tag);
                return ChoiceChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => toggleTag(tag),
                  selectedColor: Colors.pink.shade100,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // 날씨 및 공개 설정
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedWeather,
                      items: ['맑음', '흐림', '비', '눈'].map((w) {
                        return DropdownMenuItem(value: w, child: Text(w));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedWeather = value!;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: selectedTemperature,
                      items: ['10℃', '15℃', '20℃', '25℃', '30℃'].map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedTemperature = value!;
                        });
                      },
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        const Text('공개 여부: '),
                        Switch(
                          value: isPublic,
                          onChanged: (val) => setState(() => isPublic = val),
                          activeColor: Colors.pink,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.pink,
                    side: const BorderSide(color: Colors.pink),
                  ),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 등록 로직
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('등록'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
