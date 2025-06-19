import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const String KMA_API_KEY = 'Wjb8zKkrrbUtY2pQXCNNv%2B5M2EqShPVq92B139bdclMwmJDylxQjPYUUF6cobHdRtf9Et%2Bq0MxDFn1Oh4tBLhg%3D%3D';

Future<int?> fetchTemperatureFromKMA(DateTime dateTime, int nx, int ny) async {
  String date = DateFormat('yyyyMMdd').format(dateTime);
  String time = DateFormat('HH00').format(dateTime);
  print("기준 시간:$time");
  String baseTime = _getNearestBaseTime(dateTime);
  print("예보 시간:$baseTime");
  print("기준 날짜:$date");
  final url = Uri.parse(
    'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst'
        '?serviceKey=$KMA_API_KEY'
        '&numOfRows=1000&pageNo=1&dataType=JSON'
        '&base_date=20250618&base_time=2300'
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
  print(baseHour.toString().padLeft(2, '0') + "00");
  return baseHour.toString().padLeft(2, '0') + "00";
}