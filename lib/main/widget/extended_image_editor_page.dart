import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:extended_image_library/extended_image_library.dart';


class ExtendedImageEditorPage extends StatefulWidget {
  final Uint8List imageBytes;

  const ExtendedImageEditorPage({Key? key, required this.imageBytes}) : super(key: key);

  @override
  _ExtendedImageEditorPageState createState() => _ExtendedImageEditorPageState();
}

class _ExtendedImageEditorPageState extends State<ExtendedImageEditorPage> {
  final GlobalKey<ExtendedImageEditorState> editorKey = GlobalKey<ExtendedImageEditorState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('이미지 편집'),
        actions: [
          TextButton(
            onPressed: () async {
              final state = editorKey.currentState;
              if (state == null) return;

              // 편집된 이미지 Uint8List로 가져오기 (크롭+회전+편집 포함)
              final Uint8List? editedImage = await editorKey.currentState?.rawImageData;

              if (editedImage != null) {
                Navigator.of(context).pop(editedImage);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('완료', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ExtendedImage.memory(
        widget.imageBytes,
        fit: BoxFit.contain,
        mode: ExtendedImageMode.editor,
        extendedImageEditorKey: editorKey,
        initEditorConfigHandler: (state) {
          return EditorConfig(
            maxScale: 8.0,
            cropRectPadding: const EdgeInsets.all(20.0),
            cropAspectRatio: 3 / 4, // 3:4 비율 고정
            hitTestSize: 20.0,
            cornerSize: const Size(30, 30),
          );
        },
      ),
    );
  }
}
