import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../common/dialog_util.dart';
import '../provider/custom_colors.dart';

class FindAccountPage extends StatelessWidget {
  const FindAccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color Grey = customColors?.textGrey ?? Colors.grey;
    Color White = customColors?.textWhite ?? Colors.white;
    Color Black = customColors?.textBlack ?? Colors.black;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("이메일 / 비밀번호 찾기"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Container(
              color: subColor,
              child: TabBar(
                labelColor: pointColor,
                unselectedLabelColor: Grey,
                dividerColor: mainColor,
                indicatorColor: pointColor,
                tabs: const [Tab(text: '이메일 찾기'), Tab(text: '비밀번호 찾기')],
              ),
            ),
          ),
        ),
        body: const TabBarView(children: [_FindEmailTab(), _FindPasswordTab()]),
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
  String? maskedEmailResult;
  String? socialAccountType;
  bool isSocialLogin = false;

  Future<Map<String, dynamic>?> findEmailByNickname(String nickname) async {
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('nickname', isEqualTo: nickname)
            .limit(1)
            .get();

    if (query.docs.isEmpty) return null;
    return query.docs.first.data();
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email; // 이메일 형식이 아니면 원본 반환

    final username = parts[0];
    final domain = parts[1];

    // 예외 처리: 사용자 ID가 2자 이하일 경우 전체 마스킹
    if (username.length <= 2) {
      return '*' * username.length + '@' + domain;
    }

    // 일반 처리: 앞 2자리 표시 + 나머지는 *
    final visibleLength = 2;
    final visiblePart = username.substring(0, visibleLength);
    final masked = '*' * (username.length - visibleLength);

    return '$visiblePart$masked@$domain';
  }

  void _findEmail() async {
    final nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      await showDialogMessage(context, "닉네임을 입력해주세요.");
      return;
    }

    final userData = await findEmailByNickname(nickname);
    if (userData != null) {
      final email = userData['email'] as String?;
      final social = userData['socialAccount'] as String?;

      final isSocial = (social == 'kakao' || social == 'naver');
      print(isSocial);
      setState(() {
        maskedEmailResult = isSocial ? null : maskEmail(email ?? '');
        socialAccountType = social;
        isSocialLogin = isSocial;
      });
    } else {
      await showDialogMessage(context, "일치하는 이메일을 찾을 수 없습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _SectionWrapper(
        children: [
          const Text(
            "닉네임으로 이메일 찾기",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: nicknameController,
            decoration: themedInputDecoration(context, "닉네임을 입력하세요."),
            onChanged: (value) {
              setState(() {
                isSocialLogin = false;
                maskedEmailResult = null;
                socialAccountType = null;
              });
            },
          ),
          if (isSocialLogin || maskedEmailResult != null) ...[
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  if (isSocialLogin) ...[
                    Text(
                      "해당 닉네임은 '${socialAccountType ?? "알 수 없음"}' 간편로그인으로 가입된 계정입니다.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text("해당 플랫폼의 간편로그인 버튼을 이용해 로그인해주세요."),
                  ] else ...[
                    const Text("해당 닉네임으로 가입된 이메일은"),
                    const SizedBox(height: 20),
                    Text(
                      maskedEmailResult!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text("입니다."),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.grey),
          ],
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _findEmail,
              style: elevatedButtonStyle(context),
              child: const Text(
                "이메일 찾기",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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

  void _sendPasswordResetEmail() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      await showDialogMessage(context, "이메일을 입력해주세요.");
      return;
    }

    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) {
      await showDialogMessage(context, "유효한 이메일 형식을 입력해주세요.");
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      await showDialogMessage(context, "입력한 이메일로 비밀번호 재설정 메일이 전송되었습니다.");
    } on FirebaseAuthException catch (e) {
      await showDialogMessage(context, "오류 발생: ${e.message}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: _SectionWrapper(
        children: [
          const Text(
            "이메일로 비밀번호 찾기",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            "입력하신 이메일로 비밀번호 재설정 메일이 발송됩니다.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: emailController,
            decoration: themedInputDecoration(context, "이메일을 입력해주세요."),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _sendPasswordResetEmail,
              style: elevatedButtonStyle(context),
              child: const Text(
                "전송",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration themedInputDecoration(BuildContext context, String hint) {
  final customColors = Theme.of(context).extension<CustomColors>();
  Color subColor = customColors?.subColor ?? Colors.white;
  Color pointColor = customColors?.pointColor ?? Colors.white70;
  Color Grey = customColors?.textGrey ?? Colors.grey;
  Color White = customColors?.textWhite ?? Colors.white;
  Color Black = customColors?.textBlack ?? Colors.black;

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Grey),
    filled: true,
    fillColor: subColor,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none, // 테두리 없애고 싶으면 추가
    ),
  );
}

ButtonStyle elevatedButtonStyle(BuildContext context) {
  final customColors = Theme.of(context).extension<CustomColors>();
  Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;

  return ElevatedButton.styleFrom(
    backgroundColor: mainColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  );
}

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
