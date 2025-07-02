import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../common/location_helper.dart';
import '../login_page.dart';
import '../provider/custom_fonts.dart';
import '../provider/theme_provider.dart';
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
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final nicknameController = TextEditingController();
  final bioController = TextEditingController();

  List<String> interestTags = [];
  Set<String> selectedInterestTags = {};

  bool _isLoadingTags = true;
  bool isPublic = true;
  File? _profileImage;
  bool _emailChecked = false;
  bool _emailDuplicate = false;
  bool _nicknameChecked = false;
  bool _nicknameDuplicate = false;
  bool _isValidPassword = false;
  bool _isPasswordMatched = false;
  String? _currentAddress; // 현재 위치 문자열
  bool _isGettingLocation = false; // 로딩 상태

  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  Future<void> _fetchLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position != null) {
        final address = await LocationHelper.getAddressFromLatLng(position);
        setState(() {
          _currentAddress = address;
        });
      } else {
        throw Exception('위치 정보를 가져오지 못했습니다.');
      }
    } catch (e) {
      print('위치 가져오기 오류: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 가져오기 실패: $e')),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<bool> isEmailDuplicate(String email) async {
    final snapshot = await firestore.collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<bool> isNicknameDuplicate(String nickname) async {
    final query = await firestore.collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    return query.docs.isNotEmpty;  // 중복 있으면 true
  }

  bool isValidPassword(String password) {
    // 8자 이상, 영문/숫자/특수문자 포함
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidNickname(String nickname) {
    final nicknameRegex = RegExp(r'^[a-zA-Z0-9\uac00-\ud7a3._-]{1,12}$');
    return nicknameRegex.hasMatch(nickname);
  }

  void checkEmail() async {
    String email = emailController.text.trim();

    if (email.isEmpty) {
      await showDialogMessage(context, '이메일을 입력해주세요.');
      return;
    }

    if (!isValidEmail(email)) {
      await showDialogMessage(context, '올바른 이메일 형식을 입력해주세요.');
      return;
    }

    bool isDuplicate = await isEmailDuplicate(email);

    if (isDuplicate) {
      setState(() {
        _emailDuplicate = true;
      });

      final result = await showDialogMessage(
        context,
        '이미 사용 중인 이메일 입니다. 로그인 화면으로 이동하시겠습니까?',
        confirmCancel: true,
      );

      if (result == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } else {
      setState(() {
        _emailDuplicate = false;
        _emailChecked = true;
      });
      showDialogMessage(context, "사용 가능한 이메일 입니다.");
    }
  }

  void checkNickname() async {
    String nickname = nicknameController.text.trim();
    if (nickname.isEmpty) {
      await showDialogMessage(context, '닉네임을 입력해주세요.');
      return;
    }

    if (!isValidNickname(nickname)) {
      showDialogMessage(context, "닉네임은 최대 12자 이내의 영문, 한글, 숫자, 특수문자(._-)만 사용 가능합니다.");
      setState(() {
        _nicknameDuplicate = true;
        _nicknameChecked = false;
      });
      return;
    }

    bool isDuplicate = await isNicknameDuplicate(nickname);



    if (isDuplicate) {
      setState(() {
        _nicknameDuplicate = true;
      });
      showDialogMessage(context, "이미 사용 중인 닉네임입니다.");
    } else {
      setState(() {
        _nicknameDuplicate = false;
        _nicknameChecked = true;
      });
      showDialogMessage(context, "사용 가능한 닉네임입니다.");
    }
  }

  Future<void> fetchInterestTags() async {
    final querySnapshot = await firestore
        .collection('tags')
        .where('category', isEqualTo: '분위기')
        .get();

    setState(() {
      interestTags = querySnapshot.docs
          .map((doc) => doc['content'] as String)
          .toList();
      _isLoadingTags = false;
    });
  }

  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(userId)
          .child(fileName);

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      return downloadUrl; // 이 URL을 Firestore에 저장
    } catch (e) {
      print('🔥 이미지 업로드 실패: $e');
      return null;
    }
  }

  Future<void> registerUser({
    required BuildContext context,
    required String email,
    required String password,
    required String nickname,
    required String bio,
    required List<String> interests,
  }) async {
    try {
      // 이메일 중복 체크가 되지 않았거나 중복인 경우
      if (!_emailChecked || _emailDuplicate) {
        await showDialogMessage(context, '이메일 중복 확인을 완료해주세요.');
        return;
      }

      if (!_isValidPassword) {
        await showDialogMessage(context, '비밀번호는 8자 이상, 영문/숫자/특수문자를 포함해야 합니다.');
        return;
      }

      if (!_isPasswordMatched) {
        await showDialogMessage(context, '비밀번호가 일치하지 않습니다.');
        return;
      }

      // 닉네임이 중복이면
      if (!_nicknameChecked || _nicknameDuplicate) {
        await showDialogMessage(context, '닉네임 중복 확인을 완료해주세요.');
        return;
      }

      if (_isGettingLocation) {
        final proceed = await showDialogMessage(
          context,
          '위치 정보가 아직 로딩 중입니다.\n위치 정보 없이 회원가입을 진행하시겠습니까?',
          confirmCancel: true,
        );

        if (proceed != true) {
          // 취소 눌렀으면 회원가입 중단
          return;
        }
      }

      // 2. Firebase Auth 등록
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );

      final user = credential.user;
      if (user == null) {
        throw Exception("유저 생성 실패");
      }

      // 이메일 인증 메일 발송
      await user.sendEmailVerification();

      // 이메일 인증 안내
      await showDialogMessage(
        context,
        '이메일 인증 메일을 전송했습니다.\n인증을 완료한 후 확인 버튼을 눌러주세요.',
      );

      // 이메일 인증 확인 루프
      bool isVerified = false;
      while (!isVerified) {
        await Future.delayed(const Duration(seconds: 2));
        await user.reload();
        isVerified = auth.currentUser?.emailVerified ?? false;

        if (!isVerified) {
          final retry = await showDialogMessage(
            context,
            '이메일 인증이 아직 완료되지 않았습니다.\n인증을 완료하셨나요?\n\n※ 취소를 누르시면 회원가입이 취소됩니다.',
            confirmCancel: true,
          );
          if (retry != true) {
            await user.delete(); // 가입 취소 (선택 사항)
            return;
          }
        }
      }

      String? profileImageUrl;

      if (_profileImage != null) {
        profileImageUrl = await uploadProfileImage(_profileImage!, user.uid);
      }

      // 3. Firestore에 사용자 정보 저장 (패스워드는 저장 안함!)
      await firestore.collection('users').doc(user.uid).set({
        'email': email,
        'nickname': nickname,
        'bio': bio,
        'agreeTerm': true,
        'allowNotification': true,
        'cdatetime': FieldValue.serverTimestamp(),
        'isPublic': isPublic,
        'socialAccount': '',
        'interest': interests,
        'follower': [],
        'following': [],
        'location': _currentAddress ?? '',
        'profileImage': profileImageUrl ?? '',
        'mainCoordiId': '',
      });
      // 가입 완료 메시지
      await showDialogMessage(context, '회원가입이 완료되었습니다.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false, // 이전 페이지 모두 제거
      );
    } catch (e) {
      await showDialogMessage(context, '회원가입 중 오류가 발생했습니다.\n${e.toString()}');
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
        required Color textColor,
        required Color Grey,
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
                color: textColor,
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
  void initState() {
    super.initState();

    emailController.addListener(() {
      setState(() {
        _emailChecked = false;
        _emailDuplicate = false;
      });
    });

    nicknameController.addListener(() {
      setState(() {
        _nicknameDuplicate = false;
        _nicknameChecked = false;
      });
    });

    passwordController.addListener(() {
      final password = passwordController.text;
      final confirm = confirmPasswordController.text;

      setState(() {
        _isValidPassword = isValidPassword(password);
        _isPasswordMatched = password == confirm;
      });
    });

    confirmPasswordController.addListener(() {
      final password = passwordController.text;
      final confirm = confirmPasswordController.text;

      setState(() {
        _isPasswordMatched = password == confirm;
      });
    });

    fetchInterestTags(); // 관심사 태그 불러오기
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    nicknameController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
    final textColor = isBlackTheme ? White : Black;
    final fonts = Theme.of(context).extension<CustomFonts>()!;

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
              const SizedBox(height: 10),
              Text("프로필 이미지", style: TextStyle(color: textColor,fontSize: 16),),
              const SizedBox(height: 30),
              Text("* 표시는 필수 입력 항목입니다.", style: TextStyle(fontFamily: fonts.labelFont, fontSize: 12, color: Grey)),
              buildTextField(
                '이메일 *',
                '이메일을 입력하세요',
                emailController,
                subColor: subColor,
                mainColor: mainColor,
                textColor: textColor,
                Grey: Grey,
                buttonText: '중복확인',
                onButtonPressed: checkEmail,
              ),
              const SizedBox(height: 20),
              buildTextField(
                '비밀번호 *',
                '비밀번호를 입력하세요',
                passwordController,
                subColor: subColor,
                obscure: true,
                mainColor: mainColor,
                textColor: textColor,
                Grey: Grey,
              ),
              if (!_isValidPassword && passwordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '8자 이상, 영문/숫자/특수문자를 포함해야 합니다.',
                    style: TextStyle(fontFamily: fonts.labelFont, color: pointColor, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              buildTextField(
                '비밀번호 확인 *',
                '비밀번호를 다시 입력하세요',
                confirmPasswordController,
                subColor: subColor,
                obscure: true,
                mainColor: mainColor,
                textColor: textColor,
                Grey: Grey,
              ),
              if (!_isPasswordMatched && confirmPasswordController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '비밀번호가 일치하지 않습니다.',
                    style: TextStyle(fontFamily: fonts.labelFont, color: pointColor, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              buildTextField(
                '닉네임 *',
                '닉네임을 입력하세요',
                nicknameController,
                subColor: subColor,
                mainColor: mainColor,
                textColor: textColor,
                Grey: Grey,
                buttonText: "중복확인",
                onButtonPressed: checkNickname,
              ),
              const SizedBox(height: 20),
              buildTextField(
                '자기소개',
                '내용을 입력하세요',
                bioController,
                subColor: subColor,
                mainColor: mainColor,
                textColor: textColor,
                Grey: Grey,
              ),
              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("공개 계정으로 설정", style: TextStyle(color: textColor,fontSize: 16)),
                      Switch(
                        value: isPublic,
                        activeTrackColor: mainColor,
                        activeColor: isBlackTheme ? pointColor : subColor,
                        onChanged: (val) => setState(() => isPublic = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: isBlackTheme ? pointColor : mainColor),
                          const SizedBox(width: 8),
                          Text("현재 위치", style: TextStyle(color: textColor,fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.8, // 버튼 너비 제한
                          child: ElevatedButton.icon(
                            onPressed: _isGettingLocation ? null : _fetchLocation,
                            icon: const Icon(Icons.my_location, color: Colors.white),
                            label: Text(
                              _isGettingLocation
                                  ? '위치 가져오는 중...'
                                  : (_currentAddress ?? '현재 위치 가져오기'),
                              style: const TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis, // 말줄임 처리
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text("관심사", style: TextStyle(color: textColor,fontSize: 16),),
                          SizedBox(width: 10,),
                          Text("선택 없음 ~ 최대 3개 까지 선택 가능", style: TextStyle(fontFamily: fonts.labelFont, fontSize: 12, color: Grey,)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _isLoadingTags
                        ? CircularProgressIndicator()
                        : Center(
                        child: SingleChildScrollView(
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              canvasColor: subColor,
                              splashFactory: NoSplash.splashFactory,
                            ),
                            child: Wrap(
                              spacing: 8,
                              children: interestTags.map((tag) {
                                final isSelected = selectedInterestTags.contains(tag);
                                return Material(
                                  type: MaterialType.transparency,
                                  child: RawChip(
                                    label: Text("#$tag",
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                    selected: isSelected,
                                    backgroundColor: subColor,
                                    selectedColor: mainColor,
                                    showCheckmark: false,  // 체크 아이콘 숨김
                                    shape: StadiumBorder(
                                      side: BorderSide(color: subColor),
                                    ),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          if (selectedInterestTags.length < 3) {
                                            selectedInterestTags.add(tag);
                                          }
                                        } else {
                                          selectedInterestTags.remove(tag);
                                        }
                                      });
                                    },
                                  )
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  registerUser(
                    context: context,
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                    nickname: nicknameController.text.trim(),
                    bio: bioController.text,
                    interests: selectedInterestTags.toList(),
                  );
                },
                child: Text("회원가입", style: TextStyle(fontFamily: fonts.titleFont, fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
