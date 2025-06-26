import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdItemAddPage extends StatefulWidget {
  @override
  State<AdItemAddPage> createState() => _AdItemAddPageState();
}

class _AdItemAddPageState extends State<AdItemAddPage> {
  final _formKey = GlobalKey<FormState>();
  String itemName = '';
  String link = '';
  String tagId = '';
  int price = 0;
  List<XFile> _imageFiles = [];
  bool isLoading = false;

  Future<List<String>> _uploadImages(List<XFile> files) async {
    List<String> urls = [];
    for (var file in files) {
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('adItems/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
        await storageRef.putFile(File(file.path));
        final url = await storageRef.getDownloadURL();
        urls.add(url);
      } catch (e) {
        print('이미지 업로드 실패: $e');
      }
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('모든 필수 항목을 입력하세요')));
      return;
    }
    setState(() => isLoading = true);

    final photoUrls = await _uploadImages(_imageFiles);
    if (photoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드 실패')));
      setState(() => isLoading = false);
      return;
    }

    await FirebaseFirestore.instance.collection('adItems').add({
      'itemName': itemName,
      'link': link,
      'tagId': tagId,
      'price': price,
      'photoUrls': photoUrls,
    });

    setState(() => isLoading = false);
    Navigator.pop(context); // 등록 완료 후 돌아가기
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null && !_imageFiles.any((img) => img.path == pickedFile.path)) {
      setState(() => _imageFiles.add(pickedFile));
    }
  }

  void _removeImage(int idx) {
    setState(() => _imageFiles.removeAt(idx));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('광고 아이템 추가')),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // 여러 이미지 미리보기/삭제 + 추가 버튼
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length + 1,
                  separatorBuilder: (_, __) => SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    if (idx == _imageFiles.length) {
                      return GestureDetector(
                        onTap: () {
                          if (_imageFiles.length < 5) _pickImages();
                        },
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add_a_photo, size: 45, color: Colors.grey),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imageFiles[idx].path),
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: 2, top: 2,
                          child: GestureDetector(
                            onTap: () => _removeImage(idx),
                            child: CircleAvatar(
                              backgroundColor: Colors.black54,
                              radius: 15,
                              child: Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: '광고명'),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
                onChanged: (v) => itemName = v,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: '연결 링크'),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
                onChanged: (v) => link = v,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: '태그 ID'),
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
                onChanged: (v) => tagId = v,
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: '가격'),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? '필수 입력' : null,
                onChanged: (v) => price = int.tryParse(v) ?? 0,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('등록'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
