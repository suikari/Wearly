import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:w2wproject/main/write_post_page.dart';

import '../provider/custom_colors.dart';
import '../provider/theme_provider.dart';

class EditPostPage extends StatefulWidget {
  final String feedId;

  const EditPostPage({super.key, required this.feedId});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  FirebaseFirestore fs = FirebaseFirestore.instance;

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  bool isLoading = true;
  bool isSubmitting = false;

  // 기존 상태 변수들
  String selectedWeather = '맑음';
  String selectedFeeling = '적당해요';
  bool isPublic = true;
  Map<String, List<String>> categoryTags = {};
  List<String> selectedTags = [];
  List<String> existingImageUrls = []; // 기존 firestore 이미지 URL 리스트
  List<File> selectedImages = []; // 편집 후 새로 선택된 로컬 이미지들
  int currentPageIndex = 0;
  DateTime? selectedDateTime;
  int? selectedTemp;
  String? userId;
  String? displayLocationName;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    getUserId();
    fetchTagsFromFirestore();
    fetchFeedData();
  }

  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
  }

  Future<void> fetchTagsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tags')
          .get();
      Map<String, List<String>> temp = {};
      for (var doc in snapshot.docs) {
        final category = doc['category'];
        final content = doc['content'];
        if (!temp.containsKey(category)) temp[category] = [];
        temp[category]!.add(content);
      }
      setState(() {
        categoryTags = temp;
      });
    } catch (e) {
      debugPrint('태그 로딩 오류: $e');
    }
  }

  Future<void> fetchFeedData() async {
    try {
      final doc = await fs.collection('feeds').doc(widget.feedId).get();
      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('피드가 존재하지 않습니다.')),
        );
        Navigator.of(context).pop();
        return;
      }
      final data = doc.data()!;
      // Firestore에서 받아온 데이터로 초기화
      titleController.text = data['title'] ?? '';
      contentController.text = data['content'] ?? '';
      selectedWeather = data['weather'] ?? '맑음';
      selectedFeeling = data['feeling'] ?? '적당해요';
      isPublic = data['isPublic'] ?? true;
      selectedTags = List<String>.from(data['tags'] ?? []);
      existingImageUrls = List<String>.from(data['imageUrls'] ?? []);
      displayLocationName = data['location'];

      dynamic tempValue = data['temperature'];
      if (tempValue != null) {
        if (tempValue is double) {
          selectedTemp = tempValue.toInt();
        } else if (tempValue is int) {
          selectedTemp = tempValue;
        } else {
          selectedTemp = null;
        }
      } else {
        selectedTemp = null;
      }

      // 날짜시간은 firestore timestamp에서 DateTime으로 변환
      if (data['cdatetime'] != null) {
        Timestamp ts = data['cdatetime'];
        selectedDateTime = ts.toDate();
      }
    } catch (e) {
      debugPrint('피드 데이터 로드 오류: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터를 불러오는 데 실패했습니다.')),
      );
      Navigator.of(context).pop();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // 이미지 업로드 함수는 기존과 동일하므로 재활용
  Future<List<String>> uploadNewImages(List<File> images) async {
    List<String> downloadUrls = [];
    for (var image in images) {
      final fileName = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child(
          'feed_images/$fileName.jpg');
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }
    return downloadUrls;
  }

  // 이미지 삭제 시는 local images와 firestore 이미지 URL 리스트 따로 관리
  void removeExistingImageAt(int index) {
    setState(() {
      existingImageUrls.removeAt(index);
      if (currentPageIndex >=
          existingImageUrls.length + selectedImages.length &&
          currentPageIndex > 0) {
        currentPageIndex--;
      }
    });
  }

  void removeSelectedImageAt(int index) {
    setState(() {
      selectedImages.removeAt(index);
      if (currentPageIndex >=
          existingImageUrls.length + selectedImages.length &&
          currentPageIndex > 0) {
        currentPageIndex--;
      }
    });
  }

  // 이미지 선택 + 편집 함수 (기존 pickAndEditImages 함수와 동일)
  Future<void> pickAndEditImages() async {
    final maxImageCount = 10;
    int totalCount = existingImageUrls.length + selectedImages.length;
    if (totalCount >= maxImageCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('이미지는 최대 $maxImageCount장까지만 업로드할 수 있어요.')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
        type: FileType.image, allowMultiple: true);
    if (result != null && result.files.isNotEmpty) {
      final pickedPaths = result.paths.whereType<String>().toList();

      for (var path in pickedPaths) {
        if (existingImageUrls.length + selectedImages.length >= maxImageCount)
          break;
        final bytes = await File(path).readAsBytes();
        final editedBytes = await Navigator.of(context).push<Uint8List?>(
          MaterialPageRoute(builder: (_) => ImageEditor(image: bytes)),
        );
        if (editedBytes != null) {
          try {
            final dir = await getTemporaryDirectory();
            final fileName = const Uuid().v4();
            final tempFile = File('${dir.path}/$fileName.jpg');
            await tempFile.writeAsBytes(editedBytes as List<int>);

            setState(() {
              selectedImages.add(tempFile);
            });
          } catch (e) {
            debugPrint("이미지 저장 중 에러: $e");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('이미지 저장 중 오류가 발생했습니다.')),
            );
          }
        }
      }
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('수정 중입니다...'),
                ],
              ),
            ),
          ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  // 빌드: 기존 화면 구성 거의 동일하나, 이미지 뷰어는 기존 firestore url + 새로 선택한 이미지 합쳐서 보여줌
  // 이미지 삭제 시 각각 따로 처리해야 함.

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white;
    final themeProvider = Provider.of<ThemeProvider>(context);


    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('게시글 수정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final allImagesCount = existingImageUrls.length + selectedImages.length;

    return Scaffold(
      appBar: AppBar(title: const Text('게시글 수정')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: mainColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: allImagesCount == 0
                      ? GestureDetector(
                    onTap: pickAndEditImages,
                    behavior: HitTestBehavior.translucent, // 빈 공간도 터치 가능
                    child: SizedBox.expand(  // 가능한 부모 최대 사이즈로 확장
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image,
                              size: 80,
                              color: themeProvider.colorTheme != ColorTheme.blackTheme
                                  ? Colors.white
                                  : null,                            ),
                            SizedBox(height: 16),
                            Text(
                              '이미지를 선택해주세요.',
                              style: TextStyle(
                                color: themeProvider.colorTheme != ColorTheme.blackTheme
                                    ? Colors.white
                                    : null,                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      itemCount: allImagesCount,
                      onPageChanged: (index) =>
                          setState(() => currentPageIndex = index),
                      itemBuilder: (context, index) {
                        if (index < existingImageUrls.length) {
                          // Firestore 저장된 이미지 URL
                          final url = existingImageUrls[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox.expand(
                                  child: Image.network(url, fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => removeExistingImageAt(index),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                        Icons.close, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // 새로 선택한 로컬 이미지
                          final fileIndex = index - existingImageUrls.length;
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox.expand(
                                  child: Image.file(selectedImages[fileIndex],
                                      fit: BoxFit.cover),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => removeSelectedImageAt(fileIndex),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                        Icons.close, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (allImagesCount > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(allImagesCount, (index) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentPageIndex == index
                                ? mainColor
                                : Colors.grey,
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
                backgroundColor: mainColor,
                foregroundColor: themeProvider.colorTheme != ColorTheme.blackTheme
                    ? Colors.white
                    : null,
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력해주세요...',
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: mainColor)),
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '내용을 입력해주세요...',
                border: OutlineInputBorder(
                    borderSide: BorderSide(color: mainColor)),
              ),
            ),

            const SizedBox(height: 20),
            // 태그 선택 UI
            for (var category in categoryTags.keys) ...[
              Text('#$category',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryTags[category]!.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('#$tag',
                          style: TextStyle(
                          color: themeProvider.colorTheme != ColorTheme.blackTheme
                          ? null
                        : Colors.grey,
                          )),
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
                        selectedColor: pointColor,
                        backgroundColor: subColor,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: mainColor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 날씨, 온도, 느낌, 공개여부 UI (기존과 동일)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    Row(children: [
                      Text("날씨"),
                      SizedBox(width: 50,),
                      Text("체감온도"),
                      SizedBox(width: 150,),
                    ],),

                    Row(
                      children: [
                        const Icon(Icons.wb_sunny_outlined),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedWeather,
                          items: ['맑음', '흐림', '비', '눈']
                              .map((w) =>
                              DropdownMenuItem(value: w, child: Text(w)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedWeather = val!),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.wb_sunny_outlined),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedFeeling,
                          items: ['적당해요', '추웠어요', '더웠어요']
                              .map((w) =>
                              DropdownMenuItem(value: w, child: Text(w)))
                              .toList(),
                          onChanged: (val) =>
                              setState(() => selectedFeeling = val!),
                        ),
                        const SizedBox(width: 8),
                        const Text('공개 여부: '),
                        Switch(
                          value: isPublic,
                          onChanged: (val) => setState(() => isPublic = val),
                          activeColor: mainColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 20,),

                    Row(
                      children: [Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedDateTime != null &&
                              displayLocationName != null)
                            const Text("위치"),
                          const SizedBox(height: 8),
                          if (selectedDateTime != null &&
                              displayLocationName != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF3FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on_outlined),
                                  const SizedBox(width: 8),
                                  if (selectedDateTime != null &&
                                      displayLocationName != null)
                                    Text("${displayLocationName?.isNotEmpty ==
                                        true ? displayLocationName : ''}"),
                                ],
                              ),
                            ),
                        ],
                      ),
                        SizedBox(width: 20,),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (selectedDateTime != null &&
                                selectedTemp != null)
                              const Text("온도"),
                            const SizedBox(height: 8),
                            if (selectedDateTime != null &&
                                selectedTemp != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.thermostat_outlined, size: 20),
                                    SizedBox(width: 8),
                                    Text("${selectedTemp.toString() ?? " "}°C"),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _openDateClockPicker,
                          child: selectedDateTime != null
                              ? Text('선택된 시간: ${DateFormat('yyyy-MM-dd HH:mm')
                              .format(selectedDateTime!)}')
                              : const Text('시간 선택'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 저장 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (titleController.text
                        .trim()
                        .isEmpty && contentController.text
                        .trim()
                        .isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('제목과 내용을 모두 입력해주세요.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if (existingImageUrls.isEmpty && selectedImages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('최소 1장의 이미지를 추가해주세요.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if (selectedTemp == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('날짜를 선택해주세요.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    showLoadingDialog(context);

                    setState(() {
                      isSubmitting = true;
                    });

                    // 새로 추가된 이미지 업로드
                    List<String> newImageUrls = [];
                    if (selectedImages.isNotEmpty) {
                      newImageUrls = await uploadNewImages(selectedImages);
                    }

                    // 기존 firestore 이미지 + 새로 업로드한 이미지 합치기
                    final allImageUrls = [
                      ...existingImageUrls,
                      ...newImageUrls
                    ];

                    // firestore update
                    await fs.collection('feeds').doc(widget.feedId).update({
                      'title': titleController.text,
                      'content': contentController.text,
                      'cdatetime': Timestamp.now(),
                      'isPublic': isPublic,
                      'temperature': selectedTemp,
                      'feeling': selectedFeeling,
                      'imageUrls': allImageUrls,
                      'tags': selectedTags,
                      'weather': selectedWeather,
                      'writeid': userId,
                      'location': displayLocationName,
                    });

                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('수정이 완료되었습니다.'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    //widget.onUserTap();

                    setState(() {
                      isSubmitting = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('수정 완료'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<String> getSidoFromLatLng(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      String? sido = placemarks.first.administrativeArea;
      if (sido == null || sido.isEmpty) return "서울";
      sido = sido.replaceAll(RegExp(r'(특별시|광역시|자치시|도|시)$'), '');
      return sido.trim();
    }
    return "서울";
  }

  static Future<String> getFullAddressFromLatLng(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      String area = p.administrativeArea ?? '';
      String street = p.street ?? '';
      String dong = '';

      final match = RegExp(
        r'([가-힣]+시|[가-힣]+도)[^\d가-힣]*([가-힣0-9]+동)',
      ).firstMatch(street);

      if (match != null) {
        area = match.group(1) ?? area;
        dong = match.group(2) ?? '';
      } else {
        dong = p.thoroughfare ?? p.locality ?? '';
      }

      String result =
      [area, dong]
          .where((x) => x.isNotEmpty)
          .join(' ')
          .replaceAll('대한민국', '')
          .trim();
      return result.isEmpty ? '위치 정보 없음' : result;
    }
    return '주소를 찾을 수 없습니다.';
  }

  void showWeatherLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 터치로 닫히지 않음
      builder: (_) =>
          Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('날씨 정보를 불러오는 중입니다...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
    );
  }

  Future<int?> fetchTemperatureFromKMA(DateTime dateTime, int nx,
      int ny) async {
    // GMT 기준 현재 시간
    DateTime now = DateTime.now();
    String date = DateFormat('yyyyMMdd').format(
        now.subtract(Duration(days: 1)));
    String time = DateFormat('HH00').format(dateTime);

    // UTC 기준 시간대로 변경
    DateTime utcTime = now.toUtc();

    // KST 한국 시간대로 변경
    DateTime kstTime = utcTime.add(Duration(hours: 9));
    Timestamp cdatetime = Timestamp.fromDate(kstTime);

    // YYYYMMDD 로 변경
    String formatted = DateFormat('yyyyMMdd').format(kstTime);

    final url = Uri.parse(
      'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
          '?serviceKey=$KMA_API_KEY'
          '&numOfRows=1000&pageNo=1&dataType=JSON'
          '&base_date=$date&base_time=2300'
          '&nx=$nx&ny=$ny',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List items = data['response']['body']['items']['item'];

      for (var item in items) {
        if (item['category'] == 'TMP' &&
            item['fcstDate'] == formatted &&
            item['fcstTime'] == time) {
          return double.tryParse(item['fcstValue'] ?? '')?.round();
        }
      }
    }
    return null;
  }

  void _openDateClockPicker() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        final navigator = Navigator.of(dialogContext); // ✅ 저장
        return AlertDialog(
          content: SizedBox(
            width: 350,
            height: 600,
            child: DateClockPicker(
              onDateTimeSelected: (DateTime dt) async {
                navigator.pop(); // 먼저 닫기

                showWeatherLoadingDialog(dialogContext);

                setState(() {
                  selectedDateTime = dt;
                  selectedTemp = null;
                });

                LocationPermission permission = await Geolocator
                    .checkPermission();
                if (permission == LocationPermission.denied) {
                  permission = await Geolocator.requestPermission();
                  if (permission == LocationPermission.denied) {
                    setState(() {
                      errorMsg = '위치 권한이 필요합니다!';
                    });
                    return;
                  }
                }
                if (permission == LocationPermission.deniedForever) {
                  setState(() {
                    errorMsg = '앱 설정에서 위치 권한을 허용해주세요.';
                  });
                  return;
                }

                Position position = await Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                );
                double lat = position.latitude;
                double lon = position.longitude;

                String locationNameForAPI = await getSidoFromLatLng(position);
                String fullAddress = await getFullAddressFromLatLng(position);

                setState(() {
                  displayLocationName = fullAddress;
                });

                Map<String, int> grid = convertGRID_GPS(lat, lon);
                int? temperature = await fetchTemperatureFromKMA(
                    dt, grid['x']!, grid['y']!);

                setState(() {
                  selectedTemp = temperature;
                });

                navigator.pop(); // ✅ context 없이 pop
              },
            ),
          ),
        );
      },
    );
  }
}


