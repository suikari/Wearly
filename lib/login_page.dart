import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:naver_login_sdk/naver_login_sdk.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:w2wproject/main.dart';
import 'package:w2wproject/provider/custom_colors.dart';
import 'package:w2wproject/provider/custom_fonts.dart';
import 'package:w2wproject/provider/theme_provider.dart';
import 'common/dialog_util.dart';
import 'common/terms_page.dart';
import 'page/find_account_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String logoimg = 'assets/logo/plogo.png';
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  bool _isLoading = false;

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(); // 다이얼로그 닫기
    }
  }

  void _tryLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      _showLoadingDialog();

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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 성공!')));

        _hideLoadingDialog();

        // 로그인 성공 → 홈으로 이동
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      } on FirebaseAuthException catch (e) {
        _hideLoadingDialog();

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

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }  catch (e) {
        _hideLoadingDialog(); // 예외 발생 시에도 꼭 닫아야 함
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('알 수 없는 오류가 발생했습니다.')),
        );
      }
    }
  }

  void _goToSignup() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TermsPage()));
  }

  void _goToFindidpass() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => FindAccountPage()));
  }

  Future<bool> isNicknameTaken(String nickname) async {
    final result =
        await FirebaseFirestore.instance
            .collection('users')
            .where('nickname', isEqualTo: nickname)
            .get();

    return result.docs.isNotEmpty;
  }

  String generateSocialNickname({
    required String baseNickname,
    required String provider, // 'google', 'kakao', 'naver' 등
  }) {
    final now = DateTime.now();
    final timestamp =
        '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    return '${baseNickname}_$provider$timestamp';
  }

  Future<void> signInWithGoogle() async {
    _showLoadingDialog();
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _hideLoadingDialog();
        return;
      } // 취소한 경우

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

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
          final photoUrl = userCredential.user?.photoURL ?? '';
          String displayName = userCredential.user?.displayName.toString() ?? '';

          bool taken = await isNicknameTaken(displayName);
          if (taken || displayName.trim().isEmpty) {
            displayName = generateSocialNickname(
              baseNickname: displayName,
              provider: 'google',
            );
            await showDialogMessage(
              context,
              "이미 사용 중인 닉네임으로 확인되어 임시 닉네임으로 변경됩니다. \n프로필 설정에서 닉네임을 수정해주세요.",
            );
          }

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
        _hideLoadingDialog();
        // ✅ 홈 화면으로 이동
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        _hideLoadingDialog();
      }
    } catch (e) {
      print('구글 로그인 에러: $e');
      _hideLoadingDialog();
    }
  }

  Future<void> loginWithKakao() async {
    _showLoadingDialog();
    try {
      bool installed = await isKakaoTalkInstalled();
      OAuthToken kakaoToken =
          installed
              ? await UserApi.instance.loginWithKakaoTalk()
              : await UserApi.instance.loginWithKakaoAccount();

      final user = await UserApi.instance.me();
      final uid = 'kakao_${user.id}';
      final email = user.id.toString() ?? '';
      final profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl ?? '';
      String nickname = user.kakaoAccount?.profile?.nickname.toString() ?? '';

      // Firebase Functions에 요청
      final res = await http.post(
        Uri.parse(
          'https://us-central1-wearly-d6a32.cloudfunctions.net/createCustomToken',
        ),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'uid': uid,
          'nickname': nickname,
          'provider': 'kakao',
        }),
      );

      final customToken = json.decode(res.body)['token'];
      final UserCredential userCredential = await _auth.signInWithCustomToken(
        customToken,
      );

      String? authUid = userCredential.user?.uid;

      if (authUid != null) {
        // Firestore 저장
        final firestore = FirebaseFirestore.instance;
        final doc = await firestore.collection('users').doc(authUid).get();
        if (!doc.exists) {
          // 닉네임 중복 검사
          final taken = await isNicknameTaken(nickname);
          if (taken || nickname.trim().isEmpty) {
            nickname = generateSocialNickname(
              baseNickname: nickname,
              provider: 'kakao',
            );
            await showDialogMessage(
              context,
              "이미 사용 중인 닉네임으로 확인되어 임시 닉네임으로 변경됩니다. \n프로필 설정에서 닉네임을 수정해주세요.",
            );
          }
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
            'follower': [], // 기본값 또는 []
            'following': [],
            'location': '',
            'profileImage': profileImageUrl ?? '',
            'mainCoordiId': '',
          }, SetOptions(merge: true)); // merge: true로 하면 추후 덮어쓰기 방지
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', authUid);

        _hideLoadingDialog();
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
      } else {
        _hideLoadingDialog();
      }
    } catch (e) {
      _hideLoadingDialog();
      if (e is PlatformException && e.code == 'CANCELED') {
        print('사용자가 로그인 취소함');
      } else {
        print('로그인 실패: $e');
      }
    }
  }

  Future<void> signInWithNaver() async {
    _showLoadingDialog();
    try {
      await NaverLoginSDK.authenticate();

      NaverLoginSDK.profile(
        callback: ProfileCallback(
          onSuccess: (
            String resultCode,
            String message,
            dynamic response,
          ) async {
            String responseJson;
            if (response is String) {
              responseJson = response;
            } else if (response is Map) {
              responseJson = jsonEncode(response);
            } else {
              print("Unknown response type: ${response.runtimeType}");
              return;
            }

            // fromJson 함수는 String JSON을 받는다고 가정
            final profile = NaverLoginProfile.fromJson(response: responseJson);

            final String uid = 'naver:${profile.id ?? ''}';
            final String email = profile.id ?? '';
            final String? nickname = profile.nickName ?? profile.name;
            final String profileImage = profile.profileImage ?? '';

            // 👉 Firebase 커스텀 토큰 발급 요청 후 로그인
            final res = await http.post(
              Uri.parse(
                'https://us-central1-wearly-d6a32.cloudfunctions.net/createCustomToken',
              ),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'uid': uid,
                'nickname': nickname,
                'provider': 'naver',
              }),
            );

            final token = jsonDecode(res.body)['token'];
            final credential = await _auth.signInWithCustomToken(token);
            final String? authUid = credential.user?.uid;

            if (authUid != null) {
              final firestore = FirebaseFirestore.instance;
              final docRef = firestore.collection('users').doc(authUid);
              final doc = await docRef.get();

              // 최초 로그인 시 유저 정보 저장
              if (!doc.exists) {
                // 닉네임 중복 검사
                String? finalNickname = nickname;
                final taken = await isNicknameTaken(nickname!);
                if (taken || nickname.trim().isEmpty) {
                  finalNickname = generateSocialNickname(
                    baseNickname: nickname,
                    provider: 'naver',
                  );
                  await showDialogMessage(
                    context,
                    "이미 사용 중인 닉네임으로 확인되어 임시 닉네임으로 변경됩니다. \n프로필 설정에서 닉네임을 수정해주세요.",
                  );
                }

                await docRef.set({
                  'email': email,
                  'nickname': finalNickname,
                  'bio': '',
                  'agreeTerm': true,
                  'allowNotification': true,
                  'cdatetime': FieldValue.serverTimestamp(),
                  'isPublic': true,
                  'socialAccount': 'naver',
                  'interest': [],
                  'follower': [],
                  'following': [],
                  'location': '',
                  'profileImage': profileImage,
                  'mainCoordiId': '',
                }, SetOptions(merge: true));
              }

              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userId', authUid);

              _hideLoadingDialog();
              Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
            }
          },
          onFailure: (int httpStatus, String message) {
            _hideLoadingDialog();
            print("❌ profile failure: $httpStatus, message: $message");
          },
          onError: (int errorCode, String message) {
            _hideLoadingDialog();
            print("❌ profile error: $errorCode, message: $message");
          },
        ),
      );
    } catch (e) {
      _hideLoadingDialog();
      print('Naver login failed: $e');
    }
  }

  Widget _buildSocialButton({
    required String assetPath,
    required VoidCallback onTap,
    double width = 300,
    double height = 45,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        alignment: Alignment.center,
        child: Image.asset(
          assetPath,
          width: 200,
          fit: BoxFit.contain,
        ),
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
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString("colorTheme");

    setState(() {
      if (theme == 'ColorTheme.blackTheme') {
        logoimg = 'assets/logo/wlogo.png';
      } else if (theme == 'ColorTheme.blueTheme') {
        logoimg = 'assets/logo/logo.png';
      } else {
        logoimg = 'assets/logo/plogo.png';
      }
    });
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
    final fonts = Theme.of(context).extension<CustomFonts>()!;

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
              SizedBox(height: 5, child: Center()), // 고정된 10픽셀 높이 공간
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
                  SizedBox(height: 30),
                  // Logo
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ✅ 로고 이미지 표시
                      Image.asset(logoimg, width: 150, height: 150),
                    ],
                  ),
                  SizedBox(height: 40),

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
                        hintStyle: TextStyle(color: Grey, fontSize: 14),
                        border: InputBorder.none,
                        errorStyle: TextStyle(fontFamily: fonts.labelFont),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return '이메일을 입력해주세요.';
                        if (!RegExp(
                          r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
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
                        hintStyle: TextStyle(color: Grey, fontSize: 14),
                        border: InputBorder.none,
                        errorStyle: TextStyle(fontFamily: fonts.labelFont),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return '비밀번호를 입력해주세요.';
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
                      child:
                          _isLoading
                              ? CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              )
                              : Text(
                                '로그인',
                                style: TextStyle(
                                  fontFamily: fonts.titleFont,
                                  color: White,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  SizedBox(height: 30),

                  Divider(height: 1, thickness: 1, color: highlightColor),
                  SizedBox(height: 20),

                  // 소셜 로그인 버튼들
                  _buildSocialButton(
                    assetPath: 'assets/logo/android_light_sq_SI@3x.png',
                    onTap: signInWithGoogle,
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    assetPath: 'assets/logo/kakao_login_large_narrow.png',
                    onTap: loginWithKakao,
                  ),
                  const SizedBox(height: 12),
                  _buildSocialButton(
                    assetPath: 'assets/logo/btnG_official.png',
                    onTap: signInWithNaver,
                  ),
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
                            style: TextStyle(
                              fontFamily: fonts.labelFont,
                              color: Grey,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "이메일/비밀번호를 잊으셨나요?",
                            style: TextStyle(
                              fontFamily: fonts.labelFont,
                              color: Grey,
                              fontSize: 14,
                            ),
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
                              style: TextStyle(
                                color: pointColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          GestureDetector(
                            onTap: _goToFindidpass,
                            child: Text(
                              "이메일/비밀번호 찾기",
                              style: TextStyle(
                                color: pointColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
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
