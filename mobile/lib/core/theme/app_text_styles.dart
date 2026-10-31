import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const heading = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    color: AppColors.navy,
  );
  static const title = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );
  static const body = TextStyle(
    fontSize: 15,
    height: 1.5,
    color: AppColors.navy,
  );
  static const caption = TextStyle(
    fontSize: 13,
    height: 1.5,
    color: AppColors.secondary,
  );
  static const amount = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -1,
    color: AppColors.deepBlue,
  );
  static const metric = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w700,
    color: AppColors.navy,
  );

  /// Compact visual hierarchy on phones; OS accessibility scaling is preserved.
  static TextStyle responsive(BuildContext context, TextStyle style) {
    if (MediaQuery.sizeOf(context).width >= 600) return style;
    final size = switch (style.fontSize) {
      36 => 28.0,
      30 => 24.0,
      23 => 20.0,
      19 => 17.0,
      13 => 14.0,
      _ => style.fontSize,
    };
    return style.copyWith(
      fontSize: size,
      height: 1.35,
      letterSpacing: (style.letterSpacing ?? 0) < 0 ? -.4 : style.letterSpacing,
    );
  }
}
