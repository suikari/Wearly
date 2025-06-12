import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

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
    '#간편복', '#긴팔', '#셔츠/블라우스', '#조끼', '#청바지', '#트레이닝', '#숏팬츠',
    '#레깅스', '#자켓', '#가디건', '#패딩', '#코트', '#원피스/치마', '#기모', '#모자/악세서리'
  ];
  final Set<String> selectedTags = {};
  final List<File> selectedImages = [];
  final int maxImageCount = 10;
  int currentPageIndex = 0;

  void toggleTag(String tag) {
    setState(() {
      selectedTags.contains(tag) ? selectedTags.remove(tag) : selectedTags.add(tag);
    });
  }

  Future<void> pickAndEditImages() async {
    if (selectedImages.length >= maxImageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지는 최대 $maxImageCount장까지만 업로드할 수 있어요.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final pickedPaths = result.paths.whereType<String>().toList();

      for (var path in pickedPaths) {
        if (selectedImages.length >= maxImageCount) break;

        final bytes = await File(path).readAsBytes();

        final editedBytes = await Navigator.of(context).push<Uint8List?>(
          MaterialPageRoute(builder: (_) => ImageEditor(image: bytes)),
        );

        if (editedBytes != null) {
          try {
            final dir = await getTemporaryDirectory();
            final fileName = const Uuid().v4();
            final tempFile = File('${dir.path}/$fileName.jpg');
            await tempFile.writeAsBytes(editedBytes);

            setState(() {
              selectedImages.add(tempFile);
            });
          } catch (e) {
            debugPrint("이미지 저장 중 에러 발생: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지 저장 중 오류가 발생했어요.')),
            );
          }
        }
      }
    }
  }

  void resetForm() {
    titleController.clear();
    contentController.clear();
    selectedTags.clear();
    selectedImages.clear();
    selectedWeather = '맑음';
    selectedTemperature = '20℃';
    isPublic = true;
    currentPageIndex = 0;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
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
            // 이미지 슬라이더 영역
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: selectedImages.isEmpty
                  ? Center(
                child: Text(
                  '이미지를 선택해주세요.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
                  : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: selectedImages.length,
                      onPageChanged: (index) {
                        setState(() => currentPageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            SizedBox.expand(
                              child: Image.file(
                                selectedImages[index],
                                fit: BoxFit.fill,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedImages.removeAt(index);
                                    if (currentPageIndex >= selectedImages.length &&
                                        currentPageIndex > 0) {
                                      currentPageIndex--;
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child:
                                  const Icon(Icons.close, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedImages.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(selectedImages.length, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPageIndex == index ? Colors.pink : Colors.grey,
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: pickAndEditImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('이미지 추가 및 편집'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink.shade100,
                foregroundColor: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // 제목 입력
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

            // 내용 입력
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

            // 태그 선택
            const Text('태그', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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

            // 날씨, 온도, 공개여부 선택
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.wb_sunny_outlined),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedWeather,
                    items: ['맑음', '흐림', '비', '눈']
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedWeather = val!),
                  ),
                ]),
                Row(children: [
                  DropdownButton<String>(
                    value: selectedTemperature,
                    items: ['10℃', '15℃', '20℃', '25℃', '30℃']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedTemperature = val!),
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
                ]),
              ],
            ),
            const SizedBox(height: 24),

            // 취소/등록 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () {
                    resetForm();
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.pink,
                    side: const BorderSide(color: Colors.pink),
                  ),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // 업로드 로직 자리
                    debugPrint("제목: ${titleController.text}");
                    debugPrint("내용: ${contentController.text}");
                    debugPrint("태그: ${selectedTags.toList()}");
                    debugPrint("날씨: $selectedWeather");
                    debugPrint("온도: $selectedTemperature");
                    debugPrint("공개: $isPublic");
                    debugPrint("이미지 수: ${selectedImages.length}");
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
