import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color mainColor;
  final Color pointColor;
  final Color subColor;
  final Color highlightColor;
  final Color textColor;
  final Color pointTextColor;

  const CustomColors({
    required this.mainColor,
    required this.pointColor,
    required this.subColor,
    required this.highlightColor,
    required this.textColor,
    required this.pointTextColor,
  });

  @override
  CustomColors copyWith({
    Color? mainColor,
    Color? pointColor,
    Color? subColor,
    Color? highlightColor,
    Color? textColor,
    Color? pointTextColor,
  }) {
    return CustomColors(
      mainColor: mainColor ?? this.mainColor,
      pointColor: pointColor ?? this.pointColor,
      subColor: subColor ?? this.subColor,
      highlightColor: highlightColor ?? this.highlightColor,
      textColor: textColor ?? this.textColor,
      pointTextColor: pointTextColor ?? this.pointTextColor,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) return this;
    return CustomColors(
      mainColor: Color.lerp(mainColor, other.mainColor, t)!,
      pointColor: Color.lerp(pointColor, other.pointColor, t)!,
      subColor: Color.lerp(subColor, other.subColor, t)!,
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      pointTextColor: Color.lerp(pointTextColor, other.pointTextColor, t)!,
    );
  }
}
