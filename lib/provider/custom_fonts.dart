import 'package:flutter/material.dart';

@immutable
class CustomFonts extends ThemeExtension<CustomFonts> {
  final String bodyFont;
  final String titleFont;
  final String labelFont;

  const CustomFonts({
    required this.bodyFont,
    required this.titleFont,
    required this.labelFont,
  });

  @override
  CustomFonts copyWith({
    String? bodyFont,
    String? titleFont,
    String? labelFont,
  }) {
    return CustomFonts(
      bodyFont: bodyFont ?? this.bodyFont,
      titleFont: titleFont ?? this.titleFont,
      labelFont: labelFont ?? this.labelFont,
    );
  }

  @override
  CustomFonts lerp(ThemeExtension<CustomFonts>? other, double t) {
    if (other is! CustomFonts) return this;
    return this;
  }
}
