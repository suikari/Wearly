import 'package:flutter/material.dart';

class WeatherTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('날씨 탭'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurrentWeatherWidget(),
            ClothingSuggestionWidget(),
            WeeklyForecastWidget(),
            OutfitHistoryTimeline(),
            Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton.icon(
                icon: Icon(Icons.add),
                label: Text('오늘 입은 옷 기록하기'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('기록하기 버튼 클릭됨')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurrentWeatherWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wb_sunny, size: 40, color: Colors.orange),
                SizedBox(width: 10),
                Text('서울시 강남구', style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 8),
            Text('현재 기온: 24°C, 체감 온도: 26°C'),
            Text('일교차: 10°C, 강수확률: 20%'),
            Text('바람: 3.2m/s, 습도: 68%'),
            Text('미세먼지: 좋음, 초미세먼지: 보통'),
          ],
        ),
      ),
    );
  }
}

class ClothingSuggestionWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16),
      color: Colors.lightBlue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.checkroom, size: 40),
            SizedBox(width: 10),
            Expanded(
              child: Text('오늘 같은 날씨엔 얇은 셔츠와 청바지를 추천해요!', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class WeeklyForecastWidget extends StatelessWidget {
  final List<Map<String, String>> weeklyForecast = [
    {'day': '월', 'high': '27°C', 'low': '19°C', 'icon': '☀️'},
    {'day': '화', 'high': '25°C', 'low': '18°C', 'icon': '🌤️'},
    {'day': '수', 'high': '22°C', 'low': '17°C', 'icon': '🌧️'},
    {'day': '목', 'high': '24°C', 'low': '16°C', 'icon': '⛅'},
    {'day': '금', 'high': '26°C', 'low': '18°C', 'icon': '☀️'},
    {'day': '토', 'high': '28°C', 'low': '20°C', 'icon': '🌤️'},
    {'day': '일', 'high': '23°C', 'low': '19°C', 'icon': '🌧️'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('주간 날씨 예보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weeklyForecast.length,
            itemBuilder: (context, index) {
              final dayData = weeklyForecast[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  width: 80,
                  padding: EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(dayData['day']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(dayData['icon']!, style: TextStyle(fontSize: 28)),
                      Text('최고: ${dayData['high']}'),
                      Text('최저: ${dayData['low']}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class OutfitHistoryTimeline extends StatelessWidget {
  final List<Map<String, String>> historySamples = List.generate(
    3,
        (i) => {
      'date': '6월 ${8 - i}일',
      'desc': '셔츠 + 청바지',
    },
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text('최근 코디 기록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Column(
          children: historySamples.map((entry) {
            return ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('${entry['date']}'),
              subtitle: Text('${entry['desc']}'),
            );
          }).toList(),
        ),
      ],
    );
  }
}
