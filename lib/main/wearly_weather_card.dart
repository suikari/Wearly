import 'package:flutter/material.dart';

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

  // ------ 컬러 함수 추가 ------
  Color getTempColor(num? temp) {
    if (temp == null) return Colors.black87;
    if (temp >= 30) return Colors.red[400]!;
    if (temp >= 22) return Colors.orange[400]!;
    if (temp >= 10) return Colors.blue[400]!;
    return Colors.indigo[700]!;
  }

  Color getRainColor(num? rain) {
    if (rain == null) return Colors.black87;
    if (rain >= 70) return Colors.red[400]!;
    if (rain >= 30) return Colors.orange[400]!;
    return Colors.blue[400]!;
  }

  Color getHumidityColor(num? hum) {
    if (hum == null) return Colors.black87;
    if (hum >= 70) return Colors.green[700]!;
    if (hum >= 30) return Colors.blue[400]!;
    return Colors.orange[400]!;
  }

  Color getWindColor(num? wind) {
    if (wind == null) return Colors.black87;
    if (wind >= 10) return Colors.indigo[800]!;
    if (wind >= 5) return Colors.blue[400]!;
    return Colors.lightBlue[200]!;
  }

  Color pm10Color(int value) {
    if (value <= 30) return Colors.green;
    if (value <= 80) return Colors.blue;
    if (value <= 150) return Colors.orange;
    return Colors.red;
  }

  String pm10Grade(int value) {
    if (value <= 30) return "좋음";
    if (value <= 80) return "보통";
    if (value <= 150) return "나쁨";
    return "매우나쁨";
  }

  Color pm25Color(int value) {
    if (value <= 15) return Colors.green;
    if (value <= 35) return Colors.blue;
    if (value <= 75) return Colors.orange;
    return Colors.red;
  }

  String pm25Grade(int value) {
    if (value <= 15) return "좋음";
    if (value <= 35) return "보통";
    if (value <= 75) return "나쁨";
    return "매우나쁨";
  }

  String getWeatherImageFile(String weatherStatus) {
    final hour = DateTime.now().hour;
    final isNight = hour >= 18 || hour < 6;

    if (weatherStatus == '맑음') {
      return isNight
          ? 'assets/weather_moon.gif'
          : 'assets/weather_sun.gif';
    }
    switch (weatherStatus) {
      case '구름':
      case '흐림':
        return 'assets/weather_cloud.gif';
      case '비':
        return 'assets/weather_rain.gif';
      case '눈':
        return 'assets/weather_snow.gif';
      case '소나기':
        return 'assets/weather_shower.gif';
      default:
        return 'assets/weather_sun.gif';
    }
  }

  @override
  Widget build(BuildContext context) {
    int tempDiff = (data['maxTemp'] ?? 0) - (data['minTemp'] ?? 0);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        padding: EdgeInsets.only(
          left: 18, right: 18,
          top: expanded ? 24 : 16,
          bottom: expanded ? 16 : 8,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFDE7D),
                    border: Border.all(width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      getWeatherImageFile(data['weatherStatus'] ?? '맑음'),
                      width: 38, height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("지금 날씨는",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey[700]),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              "${data['location']}",
                              style: TextStyle(color: Colors.grey[700], fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: expanded ? 18 : 10),
            expanded
                ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _centerInfoColumn(
                      "현재 기온",
                      "${data['temp']} ℃",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: getTempColor(data['temp']),
                      ),
                    ),
                    _centerInfoColumn(
                      "일교차",
                      "${tempDiff} ℃",
                      subWidget: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "최고 ${data['maxTemp']}℃   최저 ${data['minTemp']}℃",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                    _centerInfoColumn(
                      "강수 확률",
                      "${data['precipitation']} %",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: getRainColor(data['precipitation']),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _centerInfoColumn(
                      "바람 세기",
                      "${data['wind']} m/s",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: getWindColor(data['wind']),
                      ),
                    ),
                    _centerInfoColumn(
                      "습도",
                      "${data['humidity']} %",
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: getHumidityColor(data['humidity']),
                      ),
                    ),
                    _centerInfoColumn(
                      "미세먼지",
                      pm10Grade(data['fineDust']),
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: pm10Color(data['fineDust']),
                      ),
                      isDust: true,
                      dustValue: data['fineDust'],
                    ),
                    _centerInfoColumn(
                      "초미세먼지",
                      pm25Grade(data['ultraFineDust']),
                      valueStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: pm25Color(data['ultraFineDust']),
                      ),
                      isDust: true,
                      dustValue: data['ultraFineDust'],
                    ),
                  ],
                ),
              ],
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _centerInfoColumn(
                  "현재 기온",
                  "${data['temp']} ℃",
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: getTempColor(data['temp']),
                  ),
                ),
                _centerInfoColumn(
                  "일교차",
                  "${tempDiff} ℃",
                  subWidget: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "최고 ${data['maxTemp']}℃   최저 ${data['minTemp']}℃",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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
                _centerInfoColumn(
                  "강수 확률",
                  "${data['precipitation']} %",
                  valueStyle: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: getRainColor(data['precipitation']),
                  ),
                ),
              ],
            ),
            SizedBox(height: expanded ? 18 : 6),
            Center(
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: expanded ? onFold : onExpand,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Icon(
                      expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _centerInfoColumn(
      String title,
      String value, {
        TextStyle? valueStyle,
        Widget? subWidget,
        bool isDust = false,
        int? dustValue,
      }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 3),
          Text(
            value,
            style: valueStyle ??
                TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 19,
                  color: isDust ? Colors.green : Colors.black87,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isDust && dustValue != null)
            Text(
              '$dustValue㎍/㎥',
              style: TextStyle(
                fontSize: 13,
                color: valueStyle?.color ?? (isDust ? Colors.green : Colors.black87),
                fontWeight: FontWeight.w500,
              ),
            ),
          if (subWidget != null) subWidget,
        ],
      ),
    );
  }
}
