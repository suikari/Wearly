import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  final Color mainColor;
  final Color pointColor;
  final Color subColor;
  final Color highlightColor;
  final Color textBlack;
  final Color textWhite;
  final Color textGray;

  const CustomColors({
    required this.mainColor,
    required this.pointColor,
    required this.subColor,
    required this.highlightColor,
    required this.textBlack,
    required this.textWhite,
    required this.textGray,
  });

  @override
  CustomColors copyWith({
    Color? mainColor,
    Color? pointColor,
    Color? subColor,
    Color? highlightColor,
    Color? textBlack,
    Color? textWhite,
    Color? textGray,
  }) {
    return CustomColors(
      mainColor: mainColor ?? this.mainColor,
      pointColor: pointColor ?? this.pointColor,
      subColor: subColor ?? this.subColor,
      highlightColor: highlightColor ?? this.highlightColor,
      textBlack: textBlack ?? this.textBlack,
      textWhite: textWhite ?? this.textWhite,
      textGray: textGray ?? this.textGray,
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
      textBlack: Color.lerp(textBlack, other.textBlack, t)!,
      textWhite: Color.lerp(textWhite, other.textWhite, t)!,
      textGray: Color.lerp(textGray, other.textGray, t)!,
    );
  }
}
