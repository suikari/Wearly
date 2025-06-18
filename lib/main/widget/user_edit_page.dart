import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../common/location_helper.dart';
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

  String _introduction = '';
  bool _isPublic = true;
  String _location = '';
  String? _profileImageUrl;
  List<String> _selectedInterests = [];
  late List<String> _allInterests = [];

  bool _loading = true;
  final ImagePicker _picker = ImagePicker();

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
      print('관심 태그 불러오기 오류: $e');
    }
  }

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
        _introduction = data['bio'] ?? '';
        _isPublic = data['isPublic'] ?? true;
        _location = data['location'] ?? '';
        _selectedInterests = List<String>.from(data['interest'] ?? []);
        _profileImageUrl = data['profileImageUrl'] ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('users').doc(widget.userId).update({
        'introduction': _introduction,
        'isPublic': _isPublic,
        'location': _location,
        'interests': _selectedInterests,
        'profileImageUrl': _profileImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
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
      final position = await LocationHelper.getCurrentPosition(); // 위치 좌표 요청
      if (position != null) {
        final address = await LocationHelper.getAddressFromLatLng(position); // 주소 변환
        setState(() {
          _currentAddress = address;
          _location = address; // ❗ DB 저장용 값도 같이 업데이트하세요
        });
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

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<CustomColors>();
    Color mainColor = customColors?.mainColor ?? Theme.of(context).primaryColor;
    Color subColor = customColors?.subColor ?? Colors.white;
    Color pointColor = customColors?.pointColor ?? Colors.white70;
    Color highlightColor = customColors?.highlightColor ?? Colors.orange;

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
                          : null,  // 이미지 표시 안함 (빈 배경색)
                      child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                          ? const Icon(Icons.person, size: 50, color: Colors.grey) // 기본 아이콘 표시
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
