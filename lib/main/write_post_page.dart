import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  FirebaseFirestore fs = FirebaseFirestore.instance;



  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final List<String> categories = ['#상의', '#하의', '#아우터', '#기타', '#분위기'];
  String selectedWeather = '맑음';
  String selectedTemperature = '20℃';
  String selectedFeeling = '적당해요';
  bool isPublic = true;

  final Map<String, List<String>> categoryTags = {
    '#상의': ['#민소매/반팔', '#긴팔', '#셔츠/블라우스', '#스웨터/니트', '#맨투맨/후드'],
    '#하의': ['#청바지', '#면바지', '#슬렉스', '#반바지'],
    '#아우터': ['#자켓', '#가디건', '#패딩', '#코트', '#바람막이', '#집업'],
    '#기타': ['#내의/스타킹', '#기모', '#모자/목도리'],
    '#분위기': ['#스트릿', '#캐쥬얼', '#미니멀', '#빈티지', '#시크', '#클래식', '#보헤미안', '#스포티']
  };

  List<String> selectedTags = [];

  final List<File> selectedImages = [];
  final int maxImageCount = 10;
  int currentPageIndex = 0;

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
    setState(() {
      titleController.clear();
      contentController.clear();
      selectedTags.clear();
      selectedImages.clear();
      selectedWeather = '맑음';
      selectedTemperature = '20℃';
      isPublic = true;
      currentPageIndex = 0;
    });

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
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.pink.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: selectedImages.isEmpty
                  ? Center(child: Text('이미지를 선택해주세요.', style: TextStyle(color: Colors.grey)))
                  : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: selectedImages.length,
                      onPageChanged: (index) => setState(() => currentPageIndex = index),
                      itemBuilder: (context, index) => Stack(
                        children: [
                          SizedBox.expand(
                            child: Image.file(selectedImages[index], fit: BoxFit.fill),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedImages.removeAt(index);
                                  if (currentPageIndex >= selectedImages.length && currentPageIndex > 0) {
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
                                child: const Icon(Icons.close, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedImages.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(selectedImages.length, (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentPageIndex == index ? Colors.pink : Colors.grey,
                        ),
                      )),
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
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력해주세요...',
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink.shade200)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '내용을 입력해주세요...',
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.pink.shade200)),
              ),
            ),
            const SizedBox(height: 20),
            for (var category in categories) ...[
              Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryTags[category]!.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              selectedTags.add(tag);
                            } else {
                              selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: Colors.pink.shade100,
                        backgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: Colors.pink.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                  const Icon(Icons.wb_sunny_outlined),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedFeeling,
                    items: ['적당해요', '추웠어요', '더웠어요']
                        .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedFeeling = val!),
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
                  const SizedBox(width: 8),
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
                  onPressed: () async {
                    debugPrint("제목: ${titleController.text}");
                    debugPrint("내용: ${contentController.text}");
                    debugPrint("태그: ${selectedTags.toString()}");
                    debugPrint("날씨: $selectedWeather");
                    debugPrint("온도: $selectedTemperature");
                    debugPrint("공개: $isPublic");
                    debugPrint("느낌: $selectedFeeling");
                    debugPrint("이미지 수: ${selectedImages.length}");

                    if (titleController.text.trim().isEmpty && contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('제목과 내용을 모두 입력해주세요.'),
                          backgroundColor: Colors.redAccent,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return; // 이후 코드 실행 방지
                    }
                    await fs.collection("feeds").add({
                      "title" : titleController.text,
                      "content" : contentController.text,
                      "cdatetime" : Timestamp.now(),
                      "isPublic" : isPublic,
                      "temperature" : selectedTemperature,
                      "feeling" : selectedFeeling
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('등록되었습니다.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    resetForm();

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
