import 'package:flutter/material.dart';

class DetailPage extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onBack;

  const DetailPage({Key? key, required this.imagePath, this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: onBack ?? () => Navigator.pop(context),
            ),
            Text("상세 페이지", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Expanded(
          child: Center(
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
      ],
    );
  }
}
