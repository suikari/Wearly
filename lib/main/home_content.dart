import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'dart:math';

class HomeContent extends StatefulWidget {
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  Map<String, dynamic>? weatherData;
  bool loading = true;
  String? errorMsg;
  bool isWeatherExpanded = true;

  final List<Map<String, dynamic>> feedData = [
    {
      'profileImage': 'https://randomuser.me/api/portraits/women/79.jpg',
      'username': 'jane_doe',
      'postImage': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      'description': '여행 너무 좋아요!',
      'likes': 123,
      'postTime': '2시간 전',
    },
    {
      'profileImage': 'https://randomuser.me/api/portraits/men/32.jpg',
      'username': 'john_smith',
      'postImage': 'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=800&q=80',
      'description': '오늘 날씨 완전 좋다!',
      'likes': 98,
      'postTime': '30분 전',
    },
  ];

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<Map<String, dynamic>?> fetchAirQuality(String sido, String sigungu, String airApiKey) async {
    String url =
        'https://apis.data.go.kr/B552584/ArpltnInforInqireSvc'
        '/getCtprvnRltmMesureDnsty'
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
              (e) => (e['cityName'] ?? e['countyName'] ?? e['stationName'] ?? '').contains(sigungu),
          orElse: () => items.first,
        );
        return {
          'pm10': int.tryParse(found['pm10Value'] ?? '0') ?? 0,
          'pm25': int.tryParse(found['pm25Value'] ?? '0') ?? 0,
        };
      }
    }
    return null;
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
      String locationName = [
        place.administrativeArea,
        place.locality,
        place.subLocality
      ].where((x) => x != null && x!.isNotEmpty).map((x) => x!).join(' ');
      if (locationName.isEmpty) locationName = "현재 위치";

      String sido = place.administrativeArea ?? '서울';
      String sigungu = place.locality ?? place.subLocality ?? '강남구';

      Map<String, int> grid = convertGRID_GPS(lat, lon);

      final apiKey = 'Wjb8zKkrrbUtY2pQXCNNv%2B5M2EqShPVq92B139bdclMwmJDylxQjPYUUF6cobHdRtf9Et%2Bq0MxDFn1Oh4tBLhg%3D%3D';
      final nx = grid['x']!;
      final ny = grid['y']!;

      // 1. 초단기관측 (실시간 온도/습도/풍속)
      DateTime now = DateTime.now().toUtc().add(Duration(hours: 9));
      Map<String, dynamic>? items;
      for (int minus = 0; minus <= 6; minus++) {
        DateTime checkTime = now.subtract(Duration(minutes: 10 * minus));
        String baseDate = "${checkTime.year.toString().padLeft(4, '0')}${checkTime.month.toString().padLeft(2, '0')}${checkTime.day.toString().padLeft(2, '0')}";
        int minute = (checkTime.minute ~/ 10) * 10;
        String baseTime = "${checkTime.hour.toString().padLeft(2, '0')}${minute.toString().padLeft(2, '0')}";
        String url =
            "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getUltraSrtNcst?"
            "serviceKey=$apiKey"
            "&numOfRows=60&pageNo=1&dataType=JSON"
            "&base_date=$baseDate&base_time=$baseTime"
            "&nx=$nx&ny=$ny";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final Map<String, dynamic> result = json.decode(response.body);
          final msg = result['response']['header']['resultMsg'];
          if (msg == "NORMAL_SERVICE" &&
              result['response']['body']?['items']?['item'] != null &&
              (result['response']['body']['items']['item'] as List).isNotEmpty) {
            items = <String, dynamic>{
              'item': result['response']['body']['items']['item'],
              'baseDate': baseDate,
              'baseTime': baseTime,
            };
            break;
          }
        }
      }
      if (items == null) throw Exception('기상청 초단기관측 데이터 없음');

      int temp = 0, humidity = 0, minTemp = 0, maxTemp = 0, precipitation = 0;
      double wind = 0;
      for (var item in items['item']) {
        switch (item['category']) {
          case 'T1H':
            temp = double.parse(item['obsrValue'].toString()).round();
            break;
          case 'REH':
            humidity = double.parse(item['obsrValue'].toString()).round();
            break;
          case 'WSD':
            wind = double.parse(item['obsrValue'].toString());
            break;
        }
      }
      String baseDate = items['baseDate'];
      String baseTime = items['baseTime'];

      // 2. 단기예보(최고/최저/강수확률)
      String today = "${now.year.toString().padLeft(4, '0')}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      String morningBaseTime = "0200"; // 오전 2시 예보가 가장 정보 많음
      String urlFcst = "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst?"
          "serviceKey=$apiKey"
          "&numOfRows=1000&pageNo=1&dataType=JSON"
          "&base_date=$today&base_time=$morningBaseTime"
          "&nx=$nx&ny=$ny";

      // 단기예보(최고/최저/강수확률)
      final fcstResponse = await http.get(Uri.parse(urlFcst));
      if (fcstResponse.statusCode == 200) {
        final Map<String, dynamic> fcstData = json.decode(fcstResponse.body);
        if (fcstData['response']['header']['resultMsg'] == "NORMAL_SERVICE") {
          List fcstItems = fcstData['response']['body']['items']['item'];

          int? todayTmx;
          int? todayTmn;
          int popMax = 0;
          String today = "${now.year.toString().padLeft(4, '0')}"
              "${now.month.toString().padLeft(2, '0')}"
              "${now.day.toString().padLeft(2, '0')}";

          // 오늘 날짜의 TMX, TMN, POP 추출
          for (var item in fcstItems) {
            if (item['fcstDate'] == today) {
              if (item['category'] == 'TMX' && todayTmx == null) {
                todayTmx = int.tryParse(item['fcstValue']);
              }
              if (item['category'] == 'TMN' && todayTmn == null) {
                todayTmn = int.tryParse(item['fcstValue']);
              }
              if (item['category'] == 'POP') {
                int pop = int.tryParse(item['fcstValue']) ?? 0;
                if (pop > popMax) popMax = pop;
              }
            }
          }

          int tempDiff = 0;
          if (todayTmx != null && todayTmn != null) {
            tempDiff = todayTmx - todayTmn;
          }

          // 결과값은 이렇게 사용
          maxTemp = todayTmx ?? temp;
          minTemp = todayTmn ?? temp;
          precipitation = popMax;
          // tempDiff = 일교차(최고-최저)
        }
      }

      // 미세먼지
      final airApiKey = 'Wjb8zKkrrbUtY2pQXCNNv%2B5M2EqShPVq92B139bdclMwmJDylxQjPYUUF6cobHdRtf9Et%2Bq0MxDFn1Oh4tBLhg%3D%3D';
      final airQuality = await fetchAirQuality(sido, sigungu, airApiKey);

      setState(() {
        weatherData = {
          'location': locationName,
          'temp': temp,
          'humidity': humidity,
          'wind': wind,
          'minTemp': minTemp,
          'maxTemp': maxTemp,
          'precipitation': precipitation,
          'fineDust': airQuality?['pm10'] ?? 0,
          'ultraFineDust': airQuality?['pm25'] ?? 0,
          'baseDate': baseDate,
          'baseTime': baseTime,
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
    return SingleChildScrollView(
      child: Column(
        children: [
          loading
              ? Padding(
            padding: const EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          )
              : errorMsg != null
              ? Padding(
            padding: const EdgeInsets.all(32.0),
            child: Text(errorMsg!, style: TextStyle(color: Colors.red)),
          )
              : WearlyWeatherCard(
            data: weatherData!,
            expanded: isWeatherExpanded,
            onExpand: () => setState(() => isWeatherExpanded = true),
            onFold: () => setState(() => isWeatherExpanded = false),
          ),
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: feedData.length,
            itemBuilder: (context, index) {
              final feed = feedData[index];
              return FeedWidget(
                profileImage: feed['profileImage'],
                username: feed['username'],
                postImage: feed['postImage'],
                description: feed['description'],
                likes: feed['likes'],
                postTime: feed['postTime'],
              );
            },
          ),
        ],
      ),
    );
  }
}

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

class WearlyWeatherCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool expanded;
  final VoidCallback onExpand;
  final VoidCallback onFold;

  const WearlyWeatherCard({
    required this.data,
    required this.expanded,
    required this.onExpand,
    required this.onFold,
    super.key,
  });

  Color dustColor(int value) {
    if (value <= 30) return Colors.green;
    if (value <= 80) return Colors.orange;
    return Colors.red;
  }

  String dustGrade(int value) {
    if (value <= 30) return "좋음";
    if (value <= 80) return "보통";
    return "나쁨";
  }

  @override
  Widget build(BuildContext context) {
    int tempDiff = (data['maxTemp'] ?? 0) - (data['minTemp'] ?? 0);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: Color(0xFFFFF3F6),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: expanded ? 24 : 14),
        child: expanded
            ? Column(
          children: [
            // 상단 중앙정렬
            Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFDE7D),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/weather_sun.gif',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  "지금 날씨는",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                    SizedBox(width: 2),
                    Text(
                      "${data['location']}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            // 3칸 정보 (완전 동적)
            Row(
              children: [
                _centerInfoColumn(
                  "현재 기온",
                  "${data['temp']} ℃",
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                ),
                Expanded(child: Container()),
                _centerInfoColumn(
                  "일교차",
                  "$tempDiff ℃",
                  // ↓ 한 줄, 줄바꿈 방지, 작게/컬러처리
                  subWidget: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "최고 ${data['maxTemp']}℃   최저 ${data['minTemp']}℃",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Expanded(child: Container()),
                _centerInfoColumn(
                  "강수 확률",
                  "${data['precipitation']} %",
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 18),
            // 4칸 정보
            Row(
              children: [
                _centerInfoColumn(
                  "바람",
                  "${data['wind']} m/s",
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Expanded(child: Container()),
                _centerInfoColumn(
                  "습도",
                  "${data['humidity']} %",
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Expanded(child: Container()),
                _centerInfoColumn(
                  "미세먼지",
                  dustGrade(data['fineDust']),
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: dustColor(data['fineDust']),
                  ),
                  isDust: true,
                ),
                Expanded(child: Container()),
                _centerInfoColumn(
                  "초미세먼지",
                  dustGrade(data['ultraFineDust']),
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: dustColor(data['ultraFineDust']),
                  ),
                  isDust: true,
                ),
              ],
            ),
            SizedBox(height: 14),
            Center(
              child: OutlinedButton(
                onPressed: onFold,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.deepOrange,
                  side: BorderSide(color: Colors.deepOrange),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                ),
                child: Text("▼", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        )
            : InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onExpand,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFDE7D),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/weather_sun.gif',
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${data['location']}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text("현재 ", style: TextStyle(color: Colors.black87, fontSize: 14)),
                        Text("${data['temp']}℃", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                        Text("  |  ", style: TextStyle(color: Colors.grey)),
                        Text("강수 ${data['precipitation']}%", style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _centerInfoColumn(String title, String value,
      {TextStyle? valueStyle, Widget? subWidget, bool isDust = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center),
          SizedBox(height: 3),
          Text(value,
              style: valueStyle ??
                  TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: isDust ? Colors.green : Colors.black87,
                  ),
              textAlign: TextAlign.center),
          if (subWidget != null) subWidget,
        ],
      ),
    );
  }
}

// 피드 카드 (동일)
class FeedWidget extends StatelessWidget {
  final String profileImage;
  final String username;
  final String postImage;
  final String description;
  final int likes;
  final String postTime;

  FeedWidget({
    required this.profileImage,
    required this.username,
    required this.postImage,
    required this.description,
    required this.likes,
    required this.postTime,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(backgroundImage: NetworkImage(profileImage)),
            title: Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Icon(Icons.more_vert),
          ),
          Container(
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(postImage),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.zero, bottom: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border),
                    SizedBox(width: 16),
                    Icon(Icons.comment_outlined),
                    SizedBox(width: 16),
                    Icon(Icons.send),
                  ],
                ),
                SizedBox(height: 8),
                Text('$likes명이 좋아합니다', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: username,
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                      TextSpan(text: '  $description', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(postTime, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
