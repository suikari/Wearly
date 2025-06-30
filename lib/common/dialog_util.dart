import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/theme_provider.dart';
import '/provider/custom_colors.dart';

Future<bool?> showDialogMessage(
    BuildContext context,
    String message, {
      bool confirmCancel = false,
      VoidCallback? onConfirm,
      VoidCallback? onCancel,
    }) async {
  final customColors = Theme.of(context).extension<CustomColors>();
  final pointColor = customColors?.pointColor ?? Colors.black;
  final subColor = customColors?.subColor ?? Colors.white;
  final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  final isBlackTheme = themeProvider.colorTheme == ColorTheme.blackTheme;
  final bgColor = isBlackTheme ? Color(0xFF333333) : Colors.white;
  final textColor = isBlackTheme ? Colors.white : Colors.black;

  return showDialog<bool>(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: IntrinsicHeight(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: bgColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 좌측 포인트 라인
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  child: Container(
                    width: 8,
                    color: pointColor,
                  ),
                ),

                // 내용 영역
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250, minHeight: 150),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          message,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: confirmCancel
                                ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                    if (onCancel != null) onCancel();
                                  },
                                  child: const Text("취소", style: TextStyle(color: Colors.grey),),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                    if (onConfirm != null) onConfirm();
                                  },
                                  child: Text("확인", style: TextStyle(color: textColor),),
                                ),
                              ],
                            )
                                : TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(true);
                                if (onConfirm != null) onConfirm();
                              },
                              child: const Text("확인", style: TextStyle(color: Colors.grey),),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}