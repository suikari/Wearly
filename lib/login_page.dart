import 'package:flutter/material.dart';
import 'package:w2wproject/main.dart';
import 'package:w2wproject/provider/custom_colors.dart';
import 'common/terms_page.dart';
import 'page/find_account_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';

  void _tryLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      if (email == "test@test.com" && password == "1234") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이메일 또는 비밀번호가 올바르지 않습니다.')),
        );
      }
    }
  }

  void _goToSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TermsPage()),
    );
  }

  void _goToFindidpass() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => FindAccountPage()),
    );
  }

  Widget _buildSocialButton(String text, Color bgColor, Color textColor, {bool border = false}) {
    return Container(
      width: double.infinity,
      height: 45,
      margin: EdgeInsets.only(top: 10),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: border ? BorderSide(color: textColor) : BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {},
        child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 테마 적용 색상 추출
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;
    Color Gray = customColors?.textGray ?? Colors.grey;
    Color White = customColors?.textWhite ?? Colors.white;
    Color Black = customColors?.textBlack ?? Colors.black;

    return Scaffold(
      backgroundColor: White,
      appBar: AppBar(
        backgroundColor: mainColor,
        elevation: 0,
        toolbarHeight: 30, // 높이 30으로 유지
        flexibleSpace: SafeArea(
          bottom: false,
          child: Container(
            color: mainColor,
            child: Column(
              children: [
                Expanded(flex: 8, child: Center()),
                Container(height: 3, color: White),
                SizedBox(height: 5, child: Center()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 55, // 높이 조절
        color: mainColor,
        child: Column(
          children: [
            SizedBox(height: 5, child: Center()),        // 고정된 10픽셀 높이 공간
            Container(height: 3, color: White),
            Expanded(flex: 8, child: Center()),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 40),
                  // Logo
                  Column(
                    children: [
                      Text(
                        'w',
                        style: TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: pointColor,
                        ),
                      ),
                      Text(
                        'wearly',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: pointColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),

                  // Email
                  Container(
                    decoration: BoxDecoration(
                      color: subColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      style: TextStyle(color: Black),
                      decoration: InputDecoration(
                        hintText: '이메일',
                        hintStyle: TextStyle(color: Gray,fontSize: 14),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '이메일을 입력해주세요.';
                        if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return '올바른 이메일 형식이 아닙니다.';
                        }
                        return null;
                      },
                      onSaved: (newValue) => email = newValue ?? '',
                    ),
                  ),
                  SizedBox(height: 10),

                  // Password
                  Container(
                    decoration: BoxDecoration(
                      color: subColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: TextFormField(
                      style: TextStyle(color: subColor),
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        hintStyle: TextStyle(color: Gray,fontSize: 14),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
                        if (value.length < 4) return '비밀번호는 4자리 이상이어야 합니다.';
                        return null;
                      },
                      onSaved: (newValue) => password = newValue ?? '',
                    ),
                  ),
                  SizedBox(height: 20),

                  // 로그인 버튼
                  Container(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _tryLogin,
                      child: Text('로그인', style: TextStyle(color: White, fontSize: 20, fontWeight: FontWeight.bold),),
                    ),
                  ),
                  SizedBox(height: 30),

                  Divider(height: 1, thickness: 1, color: highlightColor),
                  SizedBox(height: 20),

                  // 소셜 로그인 버튼들
                  _buildSocialButton('카카오로 로그인', Colors.yellow[600]!, Colors.black),
                  _buildSocialButton('구글로 로그인', Colors.white, Colors.black, border: true),
                  _buildSocialButton('네이버로 로그인', Colors.green, Colors.white),
                  SizedBox(height: 30),

                  // 하단 링크
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 왼쪽 텍스트들
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "아직 wearly 회원이 아니신가요?",
                            style: TextStyle(color: Gray, fontSize: 12),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "이메일/비밀번호를 잊으셨나요?",
                            style: TextStyle(color: Gray, fontSize: 12),
                          ),
                        ],
                      ),

                      // 오른쪽 텍스트들
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _goToSignup,
                            child: Text(
                              "회원가입하기",
                              style: TextStyle(color: pointColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(height: 5),
                          GestureDetector(
                            onTap: _goToFindidpass,
                            child: Text(
                              "이메일/비밀번호 찾기",
                              style: TextStyle(color: pointColor, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
