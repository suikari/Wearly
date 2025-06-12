import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MaterialApp(home: SignupPage()));
}

class SignupPage extends StatefulWidget {
  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final codeController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nicknameController = TextEditingController();
  final bioController = TextEditingController();



  bool showVerificationField = false;
  bool isPublic = true;
  File? _profileImage;

  void showDialogMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            child: Text("확인"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void sendEmail() {
    setState(() {
      showVerificationField = true;
    });
    showDialogMessage(context, "인증번호가 이메일로 전송되었습니다.");
  }

  void verifyCode() {
    showDialogMessage(context, "인증번호가 확인되었습니다.");
  }

  void checkNickname() {
    showDialogMessage(context, "사용 가능한 닉네임입니다.");
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('앨범에서 선택'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _profileImage = File(picked.path));
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('카메라로 촬영'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final picked = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _profileImage = File(picked.path));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildTextField(
      String label,
      TextEditingController controller, {
        bool obscure = false,
        Widget? suffix,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          suffixIcon: suffix,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavTheme = Theme.of(context).bottomNavigationBarTheme;
    final backgroundColor = bottomNavTheme.backgroundColor ?? Theme.of(context).primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;

    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // ✅ 프로필 사진 선택 버튼
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  backgroundColor: backgroundColor,
                  radius: 80,
                  backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt, color: Colors.white, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              buildTextField(
                '이메일을 입력하세요...',
                emailController,
                suffix: TextButton(onPressed: sendEmail, child: Text("전송")),
              ),
              if (showVerificationField)
                buildTextField(
                  '인증번호를 입력하세요...',
                  codeController,
                  suffix: TextButton(onPressed: verifyCode, child: Text("확인")),
                ),
              buildTextField(
                '비밀번호를 입력하세요...',
                passwordController,
                obscure: true,
              ),
              buildTextField(
                '비밀번호를 다시 입력하세요...',
                confirmPasswordController,
                obscure: true,
              ),
              buildTextField(
                '닉네임을 입력하세요...',
                nicknameController,
                suffix: TextButton(
                    onPressed: checkNickname, child: Text("중복 확인")),
              ),
              buildTextField(
                '내용을 입력하세요...',
                bioController,
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.pink),
                      SizedBox(width: 8),
                      Text("현재 위치"),
                    ],
                  ),
                  Row(
                    children: [
                      Text("공개"),
                      Switch(
                        value: isPublic,
                        activeColor: Colors.pink,
                        onChanged: (val) => setState(() => isPublic = val),
                      ),
                      Text("비공개"),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Chip(label: Text("#")),
                  Chip(label: Text("#")),
                  Chip(label: Text("#")),
                ],
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedItemColor,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  // TODO: 회원가입 처리 로직
                },
                child: Text("회원가입", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
