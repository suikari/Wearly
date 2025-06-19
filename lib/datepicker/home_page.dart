import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'date_clock_picker.dart';
import 'weather_service.dart';
import 'grid_converter.dart';

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
                print("$selectedDateTime 의 온도는 ");
                selectedTemperature = null;
              });

              final grid = convertGRID_GPS(37.5665, 126.9780);
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
