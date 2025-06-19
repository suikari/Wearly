import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'clock_painter.dart';

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
        children: const [
          Padding(padding: EdgeInsets.all(8), child: Text('AM')),
          Padding(padding: EdgeInsets.all(8), child: Text('PM'))
        ],
      ),
      const SizedBox(height: 16),
      Text(
        '선택한 시간: ${isPM ? '오후' : '오전'} ${selectedHour.toString().padLeft(2, '0')}:00',
        style: const TextStyle(fontSize: 24),
      ),
      const SizedBox(height: 16),
      Expanded(child: ElevatedButton(onPressed: _onComplete, child: const Text('완료'))),
    ]);
  }
}
