import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../login_page.dart';
import '/provider/custom_colors.dart';
import '/common/dialog_util.dart';


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

  bool isPublic = true;
  File? _profileImage;
  Timer? countdownTimer;
  Duration timeLeft = Duration(minutes: 3);
  bool _emailChecked = false;
  bool _emailDuplicate = false;
  bool _nicknameDuplicate = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<bool> isEmailDuplicate(String email) async {
    final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    return signInMethods.isNotEmpty;  // 가입된 이메일이면 true
  }

  Future<bool> isNicknameDuplicate(String nickname) async {
    final query = await firestore.collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    return query.docs.isNotEmpty;  // 중복 있으면 true
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  void checkEmail() async {
    String email = emailController.text.trim();
    if (email.isEmpty) return showDialogMessage(context, '이메일을 입력해주세요.');

    if (!isValidEmail(email)) {
      showDialogMessage(context, '올바른 이메일 형식을 입력해주세요.');
      return;
    }

    bool isDuplicate = await isEmailDuplicate(email);

    if (isDuplicate) {
      setState(() {
        _emailDuplicate = true;
      });
      // final result = await showDialogMessage(context, '이미 가입된 이메일 입니다. 로그인 화면으로 이동하시겠습니까?', confirmCancel: true);
      // if (result == true) {
      //   Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage(),));
      // } else {
      //   // 취소 눌렀을 때 (수정 가능하도록 아무 행동 안 함)
      // }
    } else {
      setState(() {
        _emailDuplicate = false;
        _emailChecked = true;  // 이메일 중복아님
      });
    }
  }

  void checkNickname() async {
    String nickname = nicknameController.text.trim();
    if (nickname.isEmpty) return;

    bool isDuplicate = await isNicknameDuplicate(nickname);

    setState(() {
      _nicknameDuplicate = isDuplicate;
    });

    showDialogMessage(context, "사용 가능한 닉네임입니다.");
  }

  void signUp() async {
    if (!_emailChecked) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("이메일 중복 확인이 필요합니다.")));
      return;
    }
    if (_nicknameDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("닉네임이 중복되었습니다.")));
      return;
    }
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String nickname = nicknameController.text.trim();

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firestore에 추가 정보 저장
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'nickname': nickname,
        'createdAt': FieldValue.serverTimestamp(),
        // 필요시 다른 프로필 필드도 추가
      });

      // 가입 완료 후 원하는 화면으로 이동
      Navigator.of(context).pushReplacementNamed('/home');

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 오류: ${e.message}')));
    }
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
      String hint,
      TextEditingController controller, {
        required Color subColor,
        required Color mainColor,
        bool obscure = false,
        Widget? suffix,
        String? buttonText,
        VoidCallback? onButtonPressed,
      }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(height: 10,),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                    suffixIcon: suffix,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: subColor,
                  ),
                ),
              ),
              if (buttonText != null && onButtonPressed != null) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onButtonPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(buttonText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;


    return Scaffold(
      appBar: AppBar(title: Text('회원가입')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 20,),
              // ✅ 프로필 사진 선택 버튼
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  backgroundColor: subColor,
                  radius: 80,
                  backgroundImage:
                  _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.camera_alt, color: Colors.white, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 30),

              buildTextField(
                '이메일',
                '이메일을 입력하세요',
                emailController,
                subColor: subColor,
                mainColor: mainColor,
                buttonText: '중복확인',
                onButtonPressed: checkEmail
              ),
              const SizedBox(height: 20),
              buildTextField(
                '비밀번호',
                '비밀번호를 입력하세요',
                passwordController,
                subColor: subColor,
                obscure: true,
                mainColor: mainColor,
              ),
              const SizedBox(height: 20),
              buildTextField(
                '비밀번호 확인',
                '비밀번호를 다시 입력하세요',
                confirmPasswordController,
                subColor: subColor,
                obscure: true,
                mainColor: mainColor,
              ),
              const SizedBox(height: 20),
              buildTextField(
                '닉네임',
                '닉네임을 입력하세요',
                nicknameController,
                subColor: subColor,
                mainColor: mainColor,
              ),
              const SizedBox(height: 20),
              buildTextField(
                '자기소개',
                '내용을 입력하세요',
                bioController,
                subColor: subColor,
                mainColor: mainColor,
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: mainColor),
                          const SizedBox(width: 8),
                          const Text("현재 위치", style: TextStyle(fontSize: 16),),
                        ],
                      ),
                      // 현재 위치 선택 버튼
                    ],
                  ),
                  Row(
                    children: [
                      Text("계정 공개", style: TextStyle(fontSize: 16),),
                      SizedBox(width: 10,),
                      Switch(
                        value: isPublic,
                        activeTrackColor: mainColor,
                        activeColor: subColor,
                        onChanged: (val) => setState(() => isPublic = val),
                      ),
                      SizedBox(width: 5,),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

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
                  backgroundColor: mainColor,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: () {
                  // TODO: 회원가입 처리 로직
                },
                child: Text("회원가입", style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
