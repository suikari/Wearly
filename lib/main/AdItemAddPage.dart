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
  XFile? _imageFile;
  bool isLoading = false;

  Future<String?> _uploadImage(XFile file) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('adItems/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
      await storageRef.putFile(File(file.path));
      return await storageRef.getDownloadURL();
    } catch (e) {
      print('이미지 업로드 실패: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('모든 필수 항목을 입력하세요')));
      return;
    }
    setState(() => isLoading = true);

    final photoUrl = await _uploadImage(_imageFile!);
    if (photoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 업로드 실패')));
      setState(() => isLoading = false);
      return;
    }

    await FirebaseFirestore.instance.collection('adItems').add({
      'itemName': itemName,
      'link': link,
      'tagId': tagId,
      'price': price,
      'photoUrl': photoUrl,
    });

    setState(() => isLoading = false);
    Navigator.pop(context); // 등록 완료 후 돌아가기
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _imageFile = pickedFile);
    }
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
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile == null
                    ? Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: Icon(Icons.add_a_photo, size: 60, color: Colors.grey),
                )
                    : Image.file(File(_imageFile!.path), height: 160, fit: BoxFit.cover),
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
