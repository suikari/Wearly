import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;

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