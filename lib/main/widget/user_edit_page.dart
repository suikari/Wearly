import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/location_helper.dart';
import '../../home_page.dart';
import '../../provider/custom_colors.dart';

class UserEditPage extends StatefulWidget {
  final String userId; // Firestore 문서 ID

  const UserEditPage({super.key, required this.userId});

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  final _formKey = GlobalKey<FormState>();

  String? _currentAddress;
  bool _isGettingLocation = false;

  String _nickname = '';
  late String _initialNickname; // 초기 닉네임 저장용
  String _nicknameError = '';
  bool _isCheckingNickname = false;
  bool _nicknameIsValid = true;

  String _introduction = '';
  bool _isPublic = true;
  String _location = '';
  String? _profileImageUrl;
  List<String> _selectedInterests = [];
  late List<String> _allInterests = [];

  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    fetchInterestTags();
  }

  Future<void> _loadUserData() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _initialNickname = data['nickname'] ?? '';
        _nickname = _initialNickname;
        _introduction = data['bio'] ?? '';
        _isPublic = data['isPublic'] ?? true;
        _location = data['location'] ?? '';
        _selectedInterests = List<String>.from(data['interest'] ?? []);
        _profileImageUrl = data['profileImage'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> fetchInterestTags() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('tags')
          .where('category', isEqualTo: '분위기')
          .get();

      List<String> loadedTags = snapshot.docs.map((doc) => doc['content'] as String).toList();

      setState(() {
        _allInterests = loadedTags;
      });
    } catch (e) {
      // 관심 태그 로드 실패시 무시
    }
  }

  Future<bool> _checkNicknameDuplicate(String nickname) async {
    if (nickname.isEmpty) return false;

    setState(() {
      _isCheckingNickname = true;
      _nicknameError = '';
      _nicknameIsValid = true;
    });

    // 초기 닉네임과 같으면 검사 불필요
    if (nickname == _initialNickname) {
      setState(() {
        _isCheckingNickname = false;
        _nicknameIsValid = true;
        _nicknameError = '';
      });
      return true;
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();

    bool isDuplicate = querySnapshot.docs.any((doc) => doc.id != widget.userId);

    setState(() {
      _isCheckingNickname = false;
      _nicknameIsValid = !isDuplicate;
      _nicknameError = isDuplicate ? '이미 사용 중인 닉네임입니다.' : '';
    });

    return !isDuplicate;
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // 닉네임 변경 시에만 중복 체크
      if (_nickname != _initialNickname) {
        bool nicknameOk = await _checkNicknameDuplicate(_nickname);
        if (!nicknameOk) return;
      }

      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'nickname': _nickname,
        'bio': _introduction,
        'isPublic': _isPublic,
        'location': _location,
        'interest': _selectedInterests,
        'profileImage': _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('profileImage', _profileImageUrl ?? '');
      prefs.setString('nickname', _nickname ?? '');

      if (mounted) {

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(initialIndex: 4),
          ),
              (route) => false,
        );

        // Navigator.pop(context, true);
      }
    }
  }

  void _onNicknameChanged(String val) {
    setState(() {
      _nickname = val.trim();
      _nicknameError = '';
      _nicknameIsValid = true;
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (image != null) {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images/${widget.userId}.jpg');
      final uploadTask = await storageRef.putFile(File(image.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      setState(() {
        _profileImageUrl = downloadUrl;
      });
    }
  }

  Future<void> _fetchLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationHelper.getCurrentPosition();
      if (position != null) {
        final address = await LocationHelper.getAddressFromLatLng(position);
        setState(() {
          _currentAddress = address;
          _location = address;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('위치 가져오기 실패: $e')),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('프로필 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickImage,
                        child: const CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 닉네임 입력 + 중복확인 버튼
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _nickname,
                      decoration: InputDecoration(
                        labelText: '닉네임',
                        errorText: _nicknameError.isNotEmpty ? _nicknameError : null,
                      ),
                      maxLength: 20,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return '닉네임을 입력해주세요.';
                        if (!_nicknameIsValid) return _nicknameError;
                        if (val.trim().length < 2) return '닉네임은 최소 2글자 이상이어야 합니다.';
                        return null;
                      },
                      onChanged: _onNicknameChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isCheckingNickname
                        ? null
                        : () async {
                      FocusScope.of(context).unfocus();
                      if (_nickname.isEmpty) {
                        setState(() {
                          _nicknameError = '닉네임을 입력해주세요.';
                          _nicknameIsValid = false;
                        });
                        return;
                      }
                      await _checkNicknameDuplicate(_nickname);
                    },
                    child: _isCheckingNickname
                        ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text('중복 확인'),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              TextFormField(
                initialValue: _introduction,
                maxLines: 3,
                decoration: const InputDecoration(labelText: '자기소개'),
                onChanged: (val) => _introduction = val,
              ),
              SwitchListTile(
                title: const Text('공개 여부'),
                value: _isPublic,
                onChanged: (val) => setState(() => _isPublic = val),
              ),

              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    initialValue: _location,
                    decoration: const InputDecoration(
                      labelText: '현재 위치',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => _location = val,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: mainColor),
                      const SizedBox(width: 8),
                      const Text("현재 위치 자동 입력", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isGettingLocation ? null : _fetchLocation,
                      icon: const Icon(Icons.my_location, color: Colors.white),
                      label: Text(
                        _isGettingLocation
                            ? '위치 가져오는 중...'
                            : (_currentAddress ?? '현재 위치 가져오기'),
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              const Text('관심사', style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 8.0,
                children: _allInterests.map((interest) {
                  final selected = _selectedInterests.contains(interest);
                  return FilterChip(
                    label: Text(interest),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          if (_selectedInterests.length < 3) {
                            _selectedInterests.add(interest);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('관심사는 최대 3개까지만 선택할 수 있어요.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saveChanges,
                child: const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
