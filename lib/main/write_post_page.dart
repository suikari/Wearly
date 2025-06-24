import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';

import '../provider/custom_colors.dart';

const String KMA_API_KEY = 'Wjb8zKkrrbUtY2pQXCNNv%2B5M2EqShPVq92B139bdclMwmJDylxQjPYUUF6cobHdRtf9Et%2Bq0MxDFn1Oh4tBLhg%3D%3D';
class WritePostPage extends StatefulWidget {
  final void Function() onUserTap;
  const WritePostPage({super.key, required this.onUserTap});


  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  FirebaseFirestore fs = FirebaseFirestore.instance;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String selectedWeather = '맑음';
  String selectedFeeling = '적당해요';
  bool isPublic = true;
  String? errorMsg;
  Map<String, List<String>> categoryTags = {};
  List<String> selectedTags = [];
  final List<File> selectedImages = [];
  final int maxImageCount = 10;
  int currentPageIndex = 0;
  bool isLoadingTags = true;
  DateTime? selectedDT;
  int? selectedTemp;
  String? userId;
  DateTime now = DateTime.now();
  String? displayLocationName;
  bool isSubmitting = false;


  @override
  void initState() {
    super.initState();
    fetchTagsFromFirestore();
    getUserId();
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
      [area, dong].where((x) => x.isNotEmpty).join(' ').replaceAll('대한민국', '').trim();
      return result.isEmpty ? '위치 정보 없음' : result;
    }
    return '주소를 찾을 수 없습니다.';
  }
  Future<void> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userId');
  }


  Future<void> fetchTagsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('tags').get();
      Map<String, List<String>> temp = {};

      for (var doc in snapshot.docs) {
        final category = doc['category'];
        final content = doc['content'];

        if (!temp.containsKey(category)) {
          temp[category] = [];
        }
        temp[category]!.add(content);
      }

      setState(() {
        categoryTags = temp;
        isLoadingTags = false;
      });
    } catch (e) {
      debugPrint('태그 로딩 중 오류 발생: $e');
      setState(() {
        isLoadingTags = false;
      });
    }
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

  Future<List<String>> uploadImages(List<File> images) async {
    List<String> downloadUrls = [];

    for (var image in images) {
      final fileName = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('feed_images/$fileName.jpg');
      final uploadTask = await ref.putFile(image);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  void resetForm() {
    setState(() {
      titleController.clear();
      contentController.clear();
      selectedTags.clear();
      selectedImages.clear();
      selectedWeather = '맑음';
      isPublic = true;
      currentPageIndex = 0;
    });
  }

  DateTime? selectedDateTime;

  Future<int?> fetchTemperatureFromKMA(DateTime dateTime, int nx, int ny) async {
    // GMT 기준 현재 시간
    DateTime now = DateTime.now();
    String date = DateFormat('yyyyMMdd').format(now.subtract(Duration(days: 1)));
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
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 350,
          height: 600,
          child: DateClockPicker(
            onDateTimeSelected: (DateTime dt) async {
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
                int? temperature = await fetchTemperatureFromKMA(dt, grid['x']!, grid['y']!);
                setState(() {
                  selectedTemp = temperature;
                });
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 바깥 터치로 닫히지 않게
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('등록 중입니다...', style: TextStyle(fontSize: 16)),
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



  @override
  Widget build(BuildContext context) {

    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white;


    final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
    return Scaffold(
      body: isLoadingTags
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(color: mainColor),
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
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox.expand(
                              child: Image.file(selectedImages[index], fit: BoxFit.fill)
                            ),
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
                          color: currentPageIndex == index ? mainColor : Colors.grey,
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
                backgroundColor: mainColor,
                foregroundColor: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: '제목을 입력해주세요...',
                border: OutlineInputBorder(borderSide: BorderSide(color: mainColor)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '내용을 입력해주세요...',
                border: OutlineInputBorder(borderSide: BorderSide(color: mainColor)),
              ),
            ),
            const SizedBox(height: 20),
            for (var category in categoryTags.keys) ...[
              Text('#$category', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryTags[category]!.map((tag) {
                    final isSelected = selectedTags.contains(tag);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('#$tag'),
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
                        selectedColor: mainColor,
                        backgroundColor: Colors.grey.shade200,
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
                            .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                            .toList(),
                          onChanged: (val) => setState(() => selectedWeather = val!),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.wb_sunny_outlined),
                        const SizedBox(width: 8),
                        DropdownButton<String>(
                          value: selectedFeeling,
                          items: ['적당해요', '추웠어요', '더웠어요']
                              .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                              .toList(),
                          onChanged: (val) => setState(() => selectedFeeling = val!),
                        ),
                        const SizedBox(width: 8),
                        const Text('공개 여부: '),
                        Switch(
                          value: isPublic,
                          onChanged: (val) => setState(() => isPublic = val),
                          activeColor: mainColor,
                        ),
                      ]
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _openDateClockPicker,
                          child: selectedDateTime != null
                              ? Text('선택된 시간: ${dateTimeFormat.format(selectedDateTime!)}')
                              : Text('시간 선택'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.thermostat, size : 40),
                          Text(
                            '해당 시간의 기온: ${selectedTemp ?? " "}°C',
                            style: const TextStyle(fontSize: 22, color: Colors.blue),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined),
                        Text("위치 : ${displayLocationName?.isNotEmpty == true ? displayLocationName : ''}")
                      ],
                    )
                  ],
                ),
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
                    foregroundColor: mainColor,
                    side: const BorderSide(color: Colors.pink),
                  ),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (titleController.text.trim().isEmpty &&
                        contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('제목과 내용을 모두 입력해주세요.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }

                    if (selectedImages.isEmpty) {
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

                    List<String> imageUrls = [];
                    if (selectedImages.isNotEmpty) {
                      imageUrls = await uploadImages(selectedImages);
                    }

                    setState(() {
                      isSubmitting = true;
                    });

                    await fs.collection("feeds").add({
                      "title": titleController.text,
                      "content": contentController.text,
                      "cdatetime": Timestamp.now(),
                      "isPublic": isPublic,
                      "temperature": selectedTemp,
                      "feeling": selectedFeeling,
                      "imageUrls": imageUrls,
                      "tags": selectedTags,
                      "weather": selectedWeather,
                      "writeid" : userId,
                      "location" : displayLocationName
                    });



                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('등록되었습니다.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    widget.onUserTap();
                    resetForm();
                    setState(() {
                      isSubmitting = false;
                    });
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

class DateClockPicker extends StatefulWidget {
  final void Function(DateTime selectedDateTime) onDateTimeSelected;

  const DateClockPicker({super.key, required this.onDateTimeSelected});

  @override
  State<DateClockPicker> createState() => _DateClockPickerState();
}

class _DateClockPickerState extends State<DateClockPicker> {
  DateTime selectedDate = DateTime.now();
  int selectedHour = 12;
  bool isPM = false; // ✅ AM/PM 상태 저장

  final dateTimeFormat = DateFormat('yyyy-MM-dd hh:mm a');

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _onTapDown(TapDownDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final touchPoint = details.localPosition;

    final dx = touchPoint.dx - center.dx;
    final dy = touchPoint.dy - center.dy;

    double angle = atan2(dy, dx);
    angle = angle < -pi / 2 ? (2 * pi + angle) : angle;
    double adjustedAngle = angle + pi / 2;
    if (adjustedAngle > 2 * pi) adjustedAngle -= 2 * pi;

    int hour = (adjustedAngle / (2 * pi) * 12).round() % 12;
    if (hour == 0) hour = 12;

    setState(() {
      selectedHour = hour;
    });
  }

  void _onComplete() {
    // ✅ AM/PM 적용된 24시간 변환
    int hour24 = selectedHour % 12 + (isPM ? 12 : 0);
    if (hour24 == 24) hour24 = 0;

    final DateTime combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour24,
      0,
    );

    widget.onDateTimeSelected(combined);
  }

  @override
  Widget build(BuildContext context) {
    final size = 300.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("시간 선택", style: TextStyle(fontSize: 40),),
        const SizedBox(height: 16),
        GestureDetector(
          onTapDown: (details) => _onTapDown(details, Size(size, size)),
          child: CustomPaint(
            size: Size(size, size),
            painter: ClockPainter(selectedHour: selectedHour),
          ),
        ),
        const SizedBox(height: 16),

        // ✅ AM/PM 토글 버튼
        ToggleButtons(
          isSelected: [!isPM, isPM],
          onPressed: (index) {
            setState(() {
              isPM = index == 1;
            });
          },
          children: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('AM'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('PM'),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Text(
          '선택한 시간: ${selectedHour.toString().padLeft(2, '0')}:00 ${isPM ? 'PM' : 'AM'}',
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: (){
            _onComplete();
          },
          child: const Text('완료'),
        ),
      ],
    );
  }
}

class ClockPainter extends CustomPainter {
  final int selectedHour;

  ClockPainter({required this.selectedHour});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paintCircle = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;

    final paintOutline = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final paintHourHand = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final paintCenterDot = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, paintCircle);
    canvas.drawCircle(center, radius, paintOutline);

    double angle = (selectedHour % 12) * (2 * pi / 12) - pi / 2;
    final handLength = radius * 0.5;
    final handEnd = Offset(
      center.dx + handLength * cos(angle),
      center.dy + handLength * sin(angle),
    );

    canvas.drawLine(center, handEnd, paintHourHand);
    canvas.drawCircle(center, 8, paintCenterDot);

    final textPainter = TextPainter(
        textAlign: TextAlign.center,
        textDirection: ui.TextDirection.ltr);

    final numberRadius = radius * 0.8;

    for (int i = 1; i <= 12; i++) {
      final numAngle = (i * 2 * pi / 12) - pi / 2;
      final offset = Offset(
        center.dx + numberRadius * cos(numAngle),
        center.dy + numberRadius * sin(numAngle),
      );

      textPainter.text = TextSpan(
        text: i.toString(),
        style: TextStyle(
          color: i == selectedHour ? Colors.blue : Colors.black54,
          fontSize: i == selectedHour ? 24 : 18,
          fontWeight: i == selectedHour ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
          canvas,
          offset - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant ClockPainter oldDelegate) {
    return oldDelegate.selectedHour != selectedHour;
  }
}
/// ▶ 위도, 경도 → 격자 좌표
Map<String, int> convertGRID_GPS(double lat, double lon) {
  const double RE = 6371.00877, GRID = 5.0,
      SLAT1 = 30.0, SLAT2 = 60.0, OLON = 126.0, OLAT = 38.0,
      XO = 43, YO = 136;
  double DEGRAD = pi / 180.0;
  double re = RE / GRID;
  double slat1 = SLAT1 * DEGRAD;
  double slat2 = SLAT2 * DEGRAD;
  double olon = OLON * DEGRAD;
  double olat = OLAT * DEGRAD;
  double sn = log(cos(slat1) / cos(slat2)) /
      log(tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5));
  double sf = pow(tan(pi * 0.25 + slat1 * 0.5), sn) * cos(slat1) / sn;
  double ro = re * sf / pow(tan(pi * 0.25 + olat * 0.5), sn);
  double ra = re * sf / pow(tan(pi * 0.25 + lat * DEGRAD * 0.5), sn);
  double theta = lon * DEGRAD - olon;
  if (theta > pi) theta -= 2.0 * pi;
  if (theta < -pi) theta += 2.0 * pi;
  theta *= sn;
  int x = (ra * sin(theta) + XO + 0.5).floor();
  int y = (ro - ra * cos(theta) + YO + 0.5).floor();
  return {'x': x, 'y': y};
}