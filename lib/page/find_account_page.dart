import 'package:flutter/material.dart';

class FindAccountPage extends StatelessWidget {
  const FindAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("이메일 / 비밀번호 찾기"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: '이메일 찾기'),
              Tab(text: '비밀번호 찾기'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _FindEmailTab(),
            _FindPasswordTab(),
          ],
        ),
      ),
    );
  }
}

// 이메일 찾기 탭
class _FindEmailTab extends StatefulWidget {
  const _FindEmailTab();

  @override
  State<_FindEmailTab> createState() => _FindEmailTabState();
}

class _FindEmailTabState extends State<_FindEmailTab> {
  final nicknameController = TextEditingController();

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("확인")),
        ],
      ),
    );
  }

  void _findEmail() {
    if (nicknameController.text.trim().isEmpty) {
      _showDialog("닉네임을 입력해주세요.");
    } else {
      _showDialog("입력하신 닉네임으로 이메일을 찾는 요청이 전송되었습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionWrapper(
      children: [
        const Text("닉네임", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: nicknameController,
          decoration: _inputDecoration("닉네임을 입력하세요..."),
        ),
        const SizedBox(height: 20),
        Center(
          child: OutlinedButton(
            onPressed: _findEmail,
            style: _buttonStyle(),
            child: const Text("이메일 찾기"),
          ),
        ),
      ],
    );
  }
}

// 비밀번호 찾기 탭
class _FindPasswordTab extends StatefulWidget {
  const _FindPasswordTab({super.key});

  @override
  State<_FindPasswordTab> createState() => _FindPasswordTabState();
}

class _FindPasswordTabState extends State<_FindPasswordTab> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool showCodeInput = false;
  bool showPasswordFields = false;

  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("확인")),
        ],
      ),
    );
  }

  void _sendCode() {
    if (emailController.text.isEmpty) {
      _showDialog("이메일을 입력해주세요.");
      return;
    }
    setState(() {
      showCodeInput = true;
    });
    _showDialog("인증번호가 전송되었습니다.");
  }

  void _verifyCode() {
    if (codeController.text.isEmpty) {
      _showDialog("인증번호를 입력해주세요.");
      return;
    }
    setState(() {
      showPasswordFields = true;
    });
    _showDialog("인증되었습니다. 비밀번호를 변경해주세요.");
  }

  void _changePassword() {
    final newPw = newPasswordController.text;
    final confirmPw = confirmPasswordController.text;

    if (newPw.isEmpty || confirmPw.isEmpty) {
      _showDialog("모든 비밀번호 필드를 입력해주세요.");
    } else if (newPw != confirmPw) {
      _showDialog("비밀번호가 일치하지 않습니다.");
    } else {
      _showDialog("비밀번호가 성공적으로 변경되었습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text("가입하신 이메일을 입력해주세요."),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: "이메일",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _sendCode,
                child: const Text("전송"),
              ),
            ],
          ),
          if (showCodeInput) ...[
            const SizedBox(height: 24),
            const Text("이메일로 받은 인증번호를 입력해주세요."),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      hintText: "인증번호",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _verifyCode,
                  child: const Text("확인"),
                ),
              ],
            ),
          ],
          if (showPasswordFields) ...[
            const SizedBox(height: 24),
            const Text("새 비밀번호를 입력해주세요."),
            const SizedBox(height: 8),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "새 비밀번호",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "비밀번호 확인",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _changePassword,
              child: const Text("변경"),
            ),
          ],
        ],
      ),
    );
  }
}

// 공통 위젯들
InputDecoration _inputDecoration(String hint) => InputDecoration(
  hintText: hint,
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.red.shade200),
  ),
  focusedBorder: const OutlineInputBorder(
    borderSide: BorderSide(color: Colors.pink),
  ),
  hintStyle: const TextStyle(color: Colors.grey),
);

ButtonStyle _buttonStyle() => OutlinedButton.styleFrom(
  side: BorderSide(color: Colors.pink.shade200),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
);

class _SectionWrapper extends StatelessWidget {
  final List<Widget> children;
  const _SectionWrapper({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
