import 'package:flutter/material.dart';
import 'dart:async';
import '../common/custom_bottom_navbar.dart';

class ClosetPage extends StatefulWidget {
  const ClosetPage({super.key});
  @override
  State<ClosetPage> createState() => _ClosetPageState();
}

class _ClosetPageState extends State<ClosetPage> {
  int _selectedNavIndex = 0;
  Timer? _timer;
  int? currentHour; // null로 시작

  @override
  void initState() {
    super.initState();
    _updateHour();
    _timer = Timer.periodic(Duration(minutes: 1), (_) => _updateHour());
  }

  void _updateHour() {
    final now = DateTime.now();
    setState(() {
      currentHour = now.hour;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<String> getHourLabels() {
    final hour = currentHour ?? DateTime.now().hour; // null이면 무조건 현재 시각
    return List.generate(8, (i) {
      final h = (hour + i) % 24;
      return '${h.toString().padLeft(2, '0')}시';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hourLabels = getHourLabels();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text('', style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ==== 시간별 날씨 ====
            Container(
              color: Color(0xfff7f8fd),
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: SizedBox(
                height: 88,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  itemCount: hourLabels.length,
                  itemBuilder: (context, idx) {
                    return Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(hourLabels[idx], style: TextStyle(fontSize: 12)),
                          SizedBox(height: 2),
                          Icon(Icons.cloud, color: Color(0xff868eb6), size: 22),
                          SizedBox(height: 2),
                          Text('${26 - idx}°', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('0%', style: TextStyle(fontSize: 10, color: Color(0xff6494ca))),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xfffff0f6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text("내 코디",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xffd97ea4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xfffff0f6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text("다른 사람 코디",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xffd97ea4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedNavIndex,
        onTap: (i) {
          setState(() => _selectedNavIndex = i);
        },
      ),
    );
  }
}