import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:math';

import 'wearly_weather_card.dart';
import 'feed_widget.dart';

class HomeContent extends StatefulWidget {
  @override
  final Key key;

  const HomeContent({required this.key}) : super(key: key);

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic>? weatherData;
  bool loading = true;
  String? errorMsg;
  bool isWeatherExpanded = true;
  List<String> tagList = [];
  bool showAllTags = false; // ★ 펼치기/접기 상태 변수

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  String convertEngSidoToKor(String sido) {
    final map = {
      'Seoul': '서울', 'Incheon': '인천', '인천광역시' : '인천', 'Busan': '부산', 'Daegu': '대구', 'Daejeon': '대전', 'Gwangju': '광주', 'Ulsan': '울산', 'Sejong': '세종',
      'Gyeonggi-do': '경기', 'Gangwon-do': '강원', 'Chungcheongbuk-do': '충북', 'Chungcheongnam-do': '충남',
      'Jeollabuk-do': '전북', 'Jeollanam-do': '전남', 'Gyeongsangbuk-do': '경북', 'Gyeongsangnam-do': '경남', 'Jeju-do': '제주',
    };
    return map[sido] ?? sido;
  }

  Future<Map<String, dynamic>?> fetchAirQuality(String sido, String sigungu, String airApiKey) async {
    String url =
        'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc/getCtprvnRltmMesureDnsty'
        '?serviceKey=$airApiKey'
        '&returnType=json'
        '&numOfRows=100'
        '&sidoName=$sido'
        '&ver=1.0';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['response']?['body']?['items'] != null) {
        final items = data['response']['body']['items'] as List;
        if (items.isEmpty) return null;
        final found = items.firstWhere(
              (e) =>
          (e['pm10Value'] != null && e['pm10Value'] != "-") &&
              (e['pm25Value'] != null && e['pm25Value'] != "-"),
          orElse: () => items.firstWhere(
                (e) => (e['pm10Value'] != null && e['pm10Value'] != "-"),
            orElse: () => items.first,
          ),
        );
        return {
          'pm10': int.tryParse(found['pm10Value'] ?? '0') ?? 0,
          'pm25': int.tryParse(found['pm25Value'] ?? '0') ?? 0,
        };
      }
    }
    return null;
  }

  // Firestore에서 온도별 추천 태그 가져오기
  Future<void> fetchRecommendTags(int temp) async {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('temperature_tags').get();
    List<String> foundTags = [];
    for (var doc in snapshot.docs) {
      int minT = doc['min_temperature'];
      int maxT = doc['max_temperature'];
      if (temp >= minT && temp <= maxT) {
        List<dynamic> tags = doc['tags'];
        foundTags = tags.map((e) => '#$e').toList();
        break;
      }
    }
    setState(() {
      tagList = foundTags;
    });
  }

  Future<void> fetchWeather() async {
    setState(() {
      loading = true;
      errorMsg = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            loading = false;
            errorMsg = '위치 권한이 필요합니다!';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          loading = false;
          errorMsg = '앱 설정에서 위치 권한을 허용해주세요.';
        });
        return;
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      double lat = position.latitude;
      double lon = position.longitude;

      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      Placemark place = placemarks.first;

      String sidoRaw = place.administrativeArea ?? '서울';
      String sido = RegExp(r'^[a-zA-Z]').hasMatch(sidoRaw) ? convertEngSidoToKor(sidoRaw) : sidoRaw;
      String sigunguRaw = place.locality ?? place.subLocality ?? '강남구';
      String sigungu = sigunguRaw;

      String locationName = [
        sido,
        sigungu,
        place.thoroughfare
      ].where((x) => x != null && x!.isNotEmpty).map((x) => x!).join(' ');
      if (locationName.isEmpty) locationName = "현재 위치";

      Map<String, int> grid = convertGRID_GPS(lat, lon);

      final apiKey = 'Wjb8zKkrrbUtY2pQXCNNv%2B5M2EqShPVq92B139bdclMwmJDylxQjPYUUF6cobHdRtf9Et%2Bq0MxDFn1Oh4tBLhg%3D%3D';
      final nx = grid['x']!;
      final ny = grid['y']!;

      DateTime now = DateTime.now().toUtc().add(Duration(hours: 9));
      String today = "${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      String baseTime = "0500";

      String urlFcst = "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst?"
          "serviceKey=$apiKey"
          "&numOfRows=1000&pageNo=1&dataType=JSON"
          "&base_date=$today&base_time=$baseTime"
          "&nx=$nx&ny=$ny";

      final fcstResponse = await http.get(Uri.parse(urlFcst));
      if (fcstResponse.statusCode != 200) throw Exception('기상청 API 오류');

      final Map<String, dynamic> fcstData = json.decode(fcstResponse.body);
      if (fcstData['response']['header']['resultMsg'] != "NORMAL_SERVICE")
        throw Exception('기상청 서비스 이상');

      final List fcstItems = fcstData['response']['body']['items']['item'];

      final todayTmn = fcstItems.where((e) =>
      e['fcstDate'] == today && e['category'] == 'TMN'
      ).toList();
      final todayTmx = fcstItems.where((e) =>
      e['fcstDate'] == today && e['category'] == 'TMX'
      ).toList();

      int? tmn = todayTmn.isNotEmpty
          ? double.tryParse(
          todayTmn.reduce((a, b) => a['fcstTime'].compareTo(b['fcstTime']) < 0 ? a : b)['fcstValue'] ?? ''
      )?.round()
          : null;

      int? tmx = todayTmx.isNotEmpty
          ? double.tryParse(
          todayTmx.reduce((a, b) => a['fcstTime'].compareTo(b['fcstTime']) > 0 ? a : b)['fcstValue'] ?? ''
      )?.round()
          : null;

      int popMax = 0;
      int? curTemp;
      int? curHumidity;
      double? wind;
      String? baseDate;
      String? baseHour;

      String curHour = now.hour.toString().padLeft(2, '0') + "00";

      for (var item in fcstItems) {
        if (item['fcstDate'] == today) {
          switch (item['category']) {
            case 'POP':
              int pop = int.tryParse(item['fcstValue'] ?? '') ?? 0;
              if (pop > popMax) popMax = pop;
              break;
            case 'TMP':
              if (item['fcstTime'] == curHour) {
                curTemp = double.tryParse(item['fcstValue'] ?? '')?.round();
                baseHour = item['fcstTime'];
                baseDate = item['fcstDate'];
              }
              break;
            case 'REH':
              if (item['fcstTime'] == curHour) {
                curHumidity = int.tryParse(item['fcstValue'] ?? '');
              }
              break;
            case 'WSD':
              if (item['fcstTime'] == curHour) {
                wind = double.tryParse(item['fcstValue'] ?? '');
              }
              break;
          }
        }
      }

      curTemp ??= tmx ?? 0;
      curHumidity ??= 0;
      wind ??= 0;
      tmx ??= curTemp;
      tmn ??= curTemp;

      // Firestore에서 추천 태그 불러오기
      await fetchRecommendTags(curTemp);

      final airApiKey = apiKey;
      final airQuality = await fetchAirQuality(sido, sigungu, airApiKey);

      setState(() {
        weatherData = {
          'location': locationName,
          'temp': curTemp,
          'humidity': curHumidity,
          'wind': wind,
          'minTemp': tmn,
          'maxTemp': tmx,
          'precipitation': popMax,
          'fineDust': airQuality?['pm10'] ?? 0,
          'ultraFineDust': airQuality?['pm25'] ?? 0,
          'baseDate': baseDate ?? today,
          'baseTime': baseHour ?? curHour,
        };
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMsg = '날씨 정보를 불러오지 못했습니다.\n$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    if (loading) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (errorMsg != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
        ),
      );
    } else {
      // 보여줄 태그 개수 제한
      int tagShowLimit = 2;

      children.add(
        WearlyWeatherCard(
          data: weatherData!,
          expanded: isWeatherExpanded,
          onExpand: () => setState(() => isWeatherExpanded = true),
          onFold: () => setState(() => isWeatherExpanded = false),
        ),
      );
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Card(
            color: Color(0xfffdeeee),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ★ 첫 줄: 제목 + 태그 일부 + 버튼
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "오늘의 추천 태그",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 6),
                      ...tagList.take(tagShowLimit).map((tag) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      )),
                      Spacer(), // ★ 이게 있어야 버튼이 항상 오른쪽!
                      if (tagList.length > tagShowLimit)
                        GestureDetector(
                          onTap: () => setState(() => showAllTags = !showAllTags),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.pink[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              showAllTags ? Icons.expand_less_rounded : Icons.add,
                              size: 16,
                              color: Colors.pink[700],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (showAllTags && tagList.length > tagShowLimit)
                    Padding(
                      padding: const EdgeInsets.only(left: 98.0, top: 3), // 적절히 조정
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: tagList.skip(tagShowLimit).map((tag) => Text(
                          tag,
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        )).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      children.add(
        AdBannerSection(),
      );
      children.add(
        WeeklyBestWidget(),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: children,
      ),
    );
  }
}

// 위경도 → 격자 변환
Map<String, int> convertGRID_GPS(double lat, double lng) {
  const double RE = 6371.00877, GRID = 5.0, SLAT1 = 30.0, SLAT2 = 60.0, OLON = 126.0, OLAT = 38.0, XO = 43, YO = 136;
  double DEGRAD = pi / 180.0;
  double re = RE / GRID;
  double slat1 = SLAT1 * DEGRAD;
  double slat2 = SLAT2 * DEGRAD;
  double olon = OLON * DEGRAD;
  double olat = OLAT * DEGRAD;
  double sn = tan(pi * 0.25 + slat2 * 0.5) / tan(pi * 0.25 + slat1 * 0.5);
  sn = log(cos(slat1) / cos(slat2)) / log(sn);
  double sf = tan(pi * 0.25 + slat1 * 0.5);
  sf = pow(sf, sn) * cos(slat1) / sn;
  double ro = tan(pi * 0.25 + olat * 0.5);
  ro = re * sf / pow(ro, sn);
  double ra = tan(pi * 0.25 + lat * DEGRAD * 0.5);
  ra = re * sf / pow(ra, sn);
  double theta = lng * DEGRAD - olon;
  if (theta > pi) theta -= 2.0 * pi;
  if (theta < -pi) theta += 2.0 * pi;
  theta *= sn;
  int x = (ra * sin(theta) + XO + 0.5).floor();
  int y = (ro - ra * cos(theta) + YO + 0.5).floor();
  return {'x': x, 'y': y};
}
