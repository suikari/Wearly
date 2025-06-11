import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiTextGeneratePage extends StatefulWidget {
  const GeminiTextGeneratePage({super.key});

  @override
  State<GeminiTextGeneratePage> createState() => _GeminiTextGeneratePageState();
}

class _GeminiTextGeneratePageState extends State<GeminiTextGeneratePage> {
  final TextEditingController _ctrl = TextEditingController();
  String _resp = '';
  bool _loading = false;
  static const _apiKey = 'AIzaSyDarJg13IYFbGKVtlNjFknEPRRtnOv_QCU';

  Future<void> _genText() async {
    final prompt = _ctrl.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _loading = true);

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: _apiKey,
      );
      final content = [Content.text(prompt)];
      final res = await model.generateContent(content);

      setState(() {
        _resp = res.text ?? '(응답이 없습니다)';
      });
    } catch (e) {
      setState(() => _resp = '에러 발생: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gemini 예제')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                labelText: '프롬프트 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _genText,
              child: Text(_loading ? '생성 중...' : '생성'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_resp, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}