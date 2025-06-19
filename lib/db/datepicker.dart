import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui' as ui;

// ✅ 기상청 API 키 입력 (URL 인코딩된 키여야 함)
const String KMA_API_KEY = 'Wjb8zKkrrbUtY2pQXCNNv%2B5M2EqShPVq92B139bdclMwmJDylxQjPYUUF6cobHdRtf9Et%2Bq0MxDFn1Oh4tBLhg%3D%3D';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AM/PM 시간 + 기온',
      theme: ThemeData(useMaterial3: true),
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? selectedDateTime;
  int? selectedTemperature;

  void _openDateClockPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: SizedBox(
          width: 350,
          height: 520,
          child: DateClockPicker(
            onDateTimeSelected: (DateTime dt) async {
              setState(() {
                selectedDateTime = dt;
                selectedTemperature = null;
              });

              final grid = convertGRID_GPS(37.5665, 126.9780); // 서울
              int? temp = await fetchTemperatureFromKMA(dt, grid['x']!, grid['y']!);

              setState(() {
                selectedTemperature = temp;
              });

              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateTimeFormat = DateFormat('yyyy-MM-dd a hh:mm', 'ko');
    return Scaffold(
      appBar: AppBar(title: const Text('날짜/시간 & 온도 선택기')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: _openDateClockPicker,
              child: const Text('날짜 및 시간 선택'),
            ),
            const SizedBox(height: 20),
            if (selectedDateTime != null) ...[
              Text(
                '선택된 시간: ${dateTimeFormat.format(selectedDateTime!)}',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 8),
            ],
            if (selectedTemperature != null)
              Text(
                '해당 시간의 기온: ${selectedTemperature}°C',
                style: const TextStyle(fontSize: 22, color: Colors.blue),
              )
          ],
        ),
      ),
    );
  }
}

/// ▶ 기상청 API에서 TMP(기온)만 가져오기
Future<int?> fetchTemperatureFromKMA(DateTime dateTime, int nx, int ny) async {
  String date = DateFormat('yyyyMMdd').format(dateTime);
  String time = DateFormat('HH00').format(dateTime);
  String baseTime = _getNearestBaseTime(dateTime);

  final url = Uri.parse(
    'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
        '?serviceKey=$KMA_API_KEY'
        '&numOfRows=1000&pageNo=1&dataType=JSON'
        '&base_date=$date&base_time=$baseTime'
        '&nx=$nx&ny=$ny',
  );

  final response = await http.get(url);
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List items = data['response']['body']['items']['item'];
    for (var item in items) {
      if (item['category'] == 'TMP' &&
          item['fcstDate'] == date &&
          item['fcstTime'] == time) {
        return double.tryParse(item['fcstValue'] ?? '')?.round();
      }
    }
  }
  return null;
}

String _getNearestBaseTime(DateTime dt) {
  final times = [2, 5, 8, 11, 14, 17, 20, 23];
  int hour = dt.hour;
  int baseHour = times.lastWhere((t) => hour >= t, orElse: () => 23);
  return baseHour.toString().padLeft(2, '0') + "00";
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

// ▶ 날짜 + 시계 위젯
class DateClockPicker extends StatefulWidget {
  final void Function(DateTime selectedDateTime) onDateTimeSelected;
  const DateClockPicker({super.key, required this.onDateTimeSelected});
  @override
  State<DateClockPicker> createState() => _DateClockPickerState();
}

class _DateClockPickerState extends State<DateClockPicker> {
  DateTime selectedDate = DateTime.now();
  int selectedHour = 12;
  bool isPM = false;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _onTapDown(TapDownDetails details, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    double angle = atan2(dy, dx);
    angle = angle < -pi / 2 ? 2 * pi + angle : angle;
    double adj = angle + pi / 2;
    if (adj > 2 * pi) adj -= 2 * pi;
    int hour = (adj / (2 * pi) * 12).round() % 12;
    if (hour == 0) hour = 12;
    setState(() => selectedHour = hour);
  }

  void _onComplete() {
    int hour = selectedHour % 12;
    if (isPM) hour += 12;
    final dt = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      0,
    );
    widget.onDateTimeSelected(dt);
  }

  @override
  Widget build(BuildContext context) {
    const double size = 300;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ElevatedButton(
        onPressed: () => _pickDate(context),
        child: Text('날짜 선택: ${DateFormat('yyyy-MM-dd').format(selectedDate)}'),
      ),
      const SizedBox(height: 16),
      GestureDetector(
        onTapDown: (d) => _onTapDown(d, const Size(size, size)),
        child: CustomPaint(
          size: const Size(size, size),
          painter: ClockPainter(selectedHour: selectedHour),
        ),
      ),
      const SizedBox(height: 16),
      ToggleButtons(
        isSelected: [!isPM, isPM],
        onPressed: (index) {
          setState(() {
            isPM = index == 1;
          });
        },
        children: const [Padding(padding: EdgeInsets.all(8), child: Text('AM')), Padding(padding: EdgeInsets.all(8), child: Text('PM'))],
      ),
      const SizedBox(height: 16),
      Text(
        '선택한 시간: ${isPM ? '오후' : '오전'} ${selectedHour.toString().padLeft(2, '0')}:00',
        style: const TextStyle(fontSize: 24),
      ),
      const SizedBox(height: 16),
      Expanded(child: ElevatedButton(onPressed: _onComplete, child: const Text('완료')),)

    ]);
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
    final handEnd = Offset(
      center.dx + radius * 0.5 * cos(angle),
      center.dy + radius * 0.5 * sin(angle),
    );
    canvas.drawLine(center, handEnd, paintHourHand);
    canvas.drawCircle(center, 8, paintCenterDot);

    final tp = TextPainter(
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    for (int i = 1; i <= 12; i++) {
      double ang = (i * 2 * pi / 12) - pi / 2;
      final off = Offset(
        center.dx + radius * 0.8 * cos(ang),
        center.dy + radius * 0.8 * sin(ang),
      );
      tp.text = TextSpan(
        text: i.toString(),
        style: TextStyle(
          color: i == selectedHour ? Colors.blue : Colors.black54,
          fontSize: i == selectedHour ? 24 : 18,
          fontWeight: i == selectedHour ? FontWeight.bold : FontWeight.normal,
        ),
      );
      tp.layout();
      tp.paint(canvas, off - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant ClockPainter old) => old.selectedHour != selectedHour;
}
