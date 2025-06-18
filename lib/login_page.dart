import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main.dart';
import 'package:w2wproject/provider/custom_colors.dart';
import 'package:w2wproject/provider/theme_provider.dart';
import 'common/terms_page.dart';
import 'page/find_account_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool _isLoading = false;

  void _tryLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      setState(() {
        _isLoading = true;
      });

      try {
        // Firebase 이메일/비밀번호 로그인
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        String? uid = userCredential.user?.uid;

        if (uid != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', uid);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 성공!')),
        );

        // 로그인 성공 → 홈으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = '';

        switch (e.code) {
          case 'user-not-found':
            errorMessage = '등록되지 않은 이메일입니다.';
            break;
          case 'wrong-password':
            errorMessage = '비밀번호가 일치하지 않습니다.';
            break;
          case 'invalid-email':
            errorMessage = '이메일 형식이 올바르지 않습니다.';
            break;
          default:
            errorMessage = '로그인에 실패했습니다. (${e.code})';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        // 로딩 종료
        setState(() {
          _isLoading = false;
        });
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

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // 취소한 경우

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      String? uid = userCredential.user?.uid;

      if (uid != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', uid);
        // ✅ Firestore 유저 문서 확인
        final firestore = FirebaseFirestore.instance;
        final docRef = firestore.collection('users').doc(uid);
        final doc = await docRef.get();

        if (!doc.exists) {
          // ✅ 최초 로그인: Firestore에 유저 정보 저장
          final email = userCredential.user?.email ?? '';
          final displayName = '${userCredential.user?.displayName}_google' ?? '';
          final photoUrl = userCredential.user?.photoURL ?? '';

          await docRef.set({
            'email': email,
            'nickname': displayName,
            'bio': '',
            'agreeTerm': true,
            'allowNotification': true,
            'cdatetime': FieldValue.serverTimestamp(),
            'isPublic': true,
            'socialAccount': 'google',
            'interest': [],
            'follower': [],
            'following': [],
            'location': '',
            'profileImage': photoUrl,
            'mainCoordiId': '',
          });
        }

        // ✅ 홈 화면으로 이동
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }

    } catch (e) {
      print('구글 로그인 에러: $e');
    }
  }

  Future<void> loginWithKakaoAndFirebase() async {
    try {
      bool installed = await isKakaoTalkInstalled();
      OAuthToken kakaoToken = installed
          ? await UserApi.instance.loginWithKakaoTalk()
          : await UserApi.instance.loginWithKakaoAccount();

      final user = await UserApi.instance.me();
      final uid = 'kakao:${user.id}';
      final email = user.kakaoAccount?.email ?? '';
      final nickname = '${user.kakaoAccount?.profile?.nickname}_kakao' ?? '';
      final profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';

      // Firebase Functions에 요청
      final res = await http.post(
        Uri.parse('https://us-central1-wearly-d6a32.cloudfunctions.net/createCustomToken'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': uid,
          'email': email,
          'nickname': nickname,
          'provider': 'kakao',
        }),
      );

      final customToken = json.decode(res.body)['token'];
      final UserCredential userCredential = await _auth.signInWithCustomToken(customToken);

      String? authUid = userCredential.user?.uid;

      if (authUid != null) {
        // Firestore 저장
        final firestore = FirebaseFirestore.instance;
        final doc = await firestore.collection('users').doc(authUid).get();
        if (!doc.exists) {
          // 위에 set 코드 실행
          await firestore.collection('users').doc(authUid).set({
            'email': email,
            'nickname': nickname,
            'bio': '', // 처음 가입 시 bio는 공백으로
            'agreeTerm': true,
            'allowNotification': true,
            'cdatetime': FieldValue.serverTimestamp(),
            'isPublic': true, // 기본 공개 여부, 수정 가능
            'socialAccount': 'kakao',
            'interest': [], // 사용자가 선택한 관심사 리스트
            'follower': '', // 기본값 또는 []
            'following': '',
            'location': '',
            'profileImage': profileImageUrl ?? '',
            'mainCoordiId': '',
          }, SetOptions(merge: true)); // merge: true로 하면 추후 덮어쓰기 방지
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', authUid);

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    } catch (e) {
      print('Kakao Login failed: $e');
    }
  }

  Future<Map<String, dynamic>?> signInWithNaver() async {
    final clientId = 'G0sonEyPthLnRvkvNR7j';
    final redirectUri = 'your.app://callback';
    final state = DateTime.now().millisecondsSinceEpoch.toString();

    final authUrl = Uri.parse(
      'https://nid.naver.com/oauth2.0/authorize'
          '?response_type=code'
          '&client_id=$clientId'
          '&redirect_uri=$redirectUri'
          '&state=$state',
    );

    final result = await FlutterWebAuth2.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: 'your.app',
    );

    final code = Uri.parse(result).queryParameters['code'];
    final receivedState = Uri.parse(result).queryParameters['state'];

    if (code == null || receivedState != state) return null;

    // 토큰 요청
    final tokenRes = await http.post(
      Uri.parse('https://nid.naver.com/oauth2.0/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'client_id': clientId,
        'client_secret': 'YOUR_NAVER_CLIENT_SECRET',
        'code': code,
        'state': state,
      },
    );

    final tokenData = json.decode(tokenRes.body);
    final accessToken = tokenData['access_token'];

    // 사용자 정보 요청
    final userInfoRes = await http.get(
      Uri.parse('https://openapi.naver.com/v1/nid/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final userInfo = json.decode(userInfoRes.body);
    final naverUser = userInfo['response'];

    return {
      'id': naverUser['id'],
      'email': naverUser['email'],
      'nickname': naverUser['nickname'],
    };

  }

  Widget _buildSocialButton(String text, Color bgColor, Color textColor, {
    bool border = false,
    required VoidCallback onPressed,
  }) {
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
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🎨 테마 적용 색상 추출
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;
    Color Grey = customColors?.textGrey ?? Colors.grey;
    Color White = customColors?.textWhite ?? Colors.white;
    Color Black = customColors?.textBlack ?? Colors.black;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isBlackTheme = themeProvider.colorTheme == ColorTheme.blackTheme;
    final bgColor = isBlackTheme ? Color(0xFF333333) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
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
                Container(height: 3, color: bgColor),
                SizedBox(height: 5, child: Center()),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 55, // 높이 조절
          color: mainColor,
          child: Column(
            children: [
              SizedBox(height: 5, child: Center()),        // 고정된 10픽셀 높이 공간
              Container(height: 3, color: bgColor),
              Expanded(flex: 8, child: Center()),
            ],
          ),
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
                      style: TextStyle(color: isBlackTheme ? White : Black),
                      focusNode: _emailFocus,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: '이메일',
                        hintStyle: TextStyle(color: Grey,fontSize: 14),
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
                      onFieldSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_passwordFocus);
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
                      style: TextStyle(color: isBlackTheme ? White : Black),
                      focusNode: _passwordFocus,
                      textInputAction: TextInputAction.done,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        hintStyle: TextStyle(color: Grey,fontSize: 14),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
                        if (value.length < 4) return '비밀번호는 4자리 이상이어야 합니다.';
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        _tryLogin(); // 로그인 실행
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
                      onPressed: _isLoading ? null : _tryLogin,
                      child: _isLoading
                          ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                          : Text('로그인', style: TextStyle(color: White, fontSize: 20, fontWeight: FontWeight.bold),),
                    ),
                  ),
                  SizedBox(height: 30),

                  Divider(height: 1, thickness: 1, color: highlightColor),
                  SizedBox(height: 20),

                  // 소셜 로그인 버튼들
                  _buildSocialButton('구글로 로그인', Colors.white, Colors.black, border: true, onPressed: signInWithGoogle),
                  _buildSocialButton('카카오로 로그인', Colors.yellow[600]!, Colors.black, onPressed:loginWithKakaoAndFirebase),
                  _buildSocialButton('네이버로 로그인', Colors.green, Colors.white, onPressed:(){}),
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
                            style: TextStyle(color: Grey, fontSize: 12),
                          ),
                          SizedBox(height: 5),
                          Text(
                            "이메일/비밀번호를 잊으셨나요?",
                            style: TextStyle(color: Grey, fontSize: 12),
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
