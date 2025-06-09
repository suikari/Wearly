import 'package:flutter/material.dart';

class HomeContent extends StatelessWidget {
  final List<Map<String, dynamic>> feedData = [
    {
      'profileImage':
      'https://randomuser.me/api/portraits/women/79.jpg',
      'username': 'jane_doe',
      'postImage':
      'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
      'description': '여행 너무 좋아요!',
      'likes': 123,
      'postTime': '2시간 전',
    },
    {
      'profileImage':
      'https://randomuser.me/api/portraits/men/32.jpg',
      'username': 'john_smith',
      'postImage':
      'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=800&q=80',
      'description': '오늘 날씨 완전 좋다!',
      'likes': 98,
      'postTime': '30분 전',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          WeatherWidget(
            location: '서울',
            weatherIcon: 'sunny',
            currentTemp: 23,
            minTemp: 16,
            maxTemp: 26,
            precipitation: 10,
            windSpeed: 3.4,
            humidity: 45,
            fineDust: 30,
            ultraFineDust: 15,
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

class WeatherWidget extends StatelessWidget {
  final String location;
  final String weatherIcon;
  final int currentTemp;
  final int minTemp;
  final int maxTemp;
  final int precipitation;
  final double windSpeed;
  final int humidity;
  final int fineDust;
  final int ultraFineDust;

  WeatherWidget({
    required this.location,
    required this.weatherIcon,
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.precipitation,
    required this.windSpeed,
    required this.humidity,
    required this.fineDust,
    required this.ultraFineDust,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_getWeatherIcon(weatherIcon), size: 48, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(location,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      Text('$currentTemp°C',
                          style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              color: Colors.orange)),
                    ],
                  ),
                ),
                Text('최저 $minTemp° / 최고 $maxTemp°',
                    style: TextStyle(color: Colors.grey[700])),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _infoItem(Icons.thermostat, '일교차', '${maxTemp - minTemp}°'),
                _infoItem(Icons.grain, '강수확률', '$precipitation%'),
                _infoItem(Icons.air, '바람', '${windSpeed.toStringAsFixed(1)} m/s'),
                _infoItem(Icons.opacity, '습도', '$humidity%'),
                _infoItem(Icons.cloud, '미세먼지', '$fineDust ㎍/m³'),
                _infoItem(Icons.cloud_queue, '초미세먼지', '$ultraFineDust ㎍/m³'),
              ],
            )
          ],
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String iconName) {
    switch (iconName) {
      case 'sunny':
        return Icons.wb_sunny;
      case 'cloudy':
        return Icons.cloud;
      case 'rain':
        return Icons.grain;
      case 'snow':
        return Icons.ac_unit;
      default:
        return Icons.wb_sunny;
    }
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        SizedBox(width: 4),
        Text('$title: ', style: TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
      ],
    );
  }
}

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
            leading: CircleAvatar(
              backgroundImage: NetworkImage(profileImage),
            ),
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
              borderRadius:
              BorderRadius.vertical(top: Radius.zero, bottom: Radius.circular(12)),
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
                          style:
                          TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
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
