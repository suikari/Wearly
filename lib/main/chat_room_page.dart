import 'package:flutter/material.dart';
import '../common/custom_app_bar.dart';

class ChatRoomPage extends StatelessWidget {
  final String userName;
  final String imagePath;

  const ChatRoomPage({
    super.key,
    required this.userName,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> messages = ["하이", "방가", "님?", "대답"];
    final today = DateTime.now();

    return Scaffold(
      appBar: CustomAppBar(title: '$userName 님'),
      body: Column(
        children: [
          // 상대방 정보 (상단)
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(imagePath),
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '$userName 님',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1, color: Colors.pinkAccent),

          // 메시지 영역
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                // 예시 메시지 반복
                for (var msg in messages)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundImage: AssetImage(imagePath),
                          radius: 18,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(msg),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // 날짜 구분선
                Center(
                  child: Column(
                    children: [
                      const DottedLine(),
                      const SizedBox(height: 4),
                      Text(
                        "${today.year}년 ${today.month}월 ${today.day}일",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const DottedLine(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 첨부파일 박스
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.pink[200],
                      border: Border.all(color: Colors.black26),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '첨부된사진.jpg ▶',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 입력창
          // const DottedLine(),
          Container(
          height: 2,              // 흰색 선 높이
          width: double.infinity,
          color:  Color.fromRGBO(255, 111, 97, 1.0),    // 흰색 선
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo, color: Colors.pink),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
                      hintText: "메시지 보내기...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.pink[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 점선 구분선 위젯
class DottedLine extends StatelessWidget {
  const DottedLine({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        final dashCount = (constraints.maxWidth / (dashWidth * 2)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.pinkAccent),
              ),
            );
          }),
        );
      },
    );
  }
}
