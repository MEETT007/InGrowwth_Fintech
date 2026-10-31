import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    focusColor: AppColors.lightBlue,
    hoverColor: AppColors.lightBlue,
    highlightColor: AppColors.lightBlue,
    splashColor: AppColors.transparent,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.sky,
      onPrimary: AppColors.navy,
      secondary: AppColors.deepBlue,
      onSecondary: AppColors.white,
      surface: AppColors.white,
      onSurface: AppColors.navy,
      onSurfaceVariant: AppColors.secondary,
      primaryContainer: AppColors.lightBlue,
      onPrimaryContainer: AppColors.navy,
      error: AppColors.error,
      outline: AppColors.secondary,
      outlineVariant: AppColors.border,
    ),
    textTheme: const TextTheme(
      headlineMedium: AppTextStyles.heading,
      headlineLarge: AppTextStyles.amount,
      titleLarge: AppTextStyles.title,
      titleMedium: AppTextStyles.body,
      bodyLarge: AppTextStyles.body,
      bodyMedium: AppTextStyles.body,
      bodySmall: AppTextStyles.caption,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.transparent,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radius),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      errorMaxLines: 10,
      filled: true,
      fillColor: const WidgetStateColor.fromMap({
        WidgetState.any: AppColors.white,
      }),
      hoverColor: AppColors.transparent,
      focusColor: AppColors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      labelStyle: AppTextStyles.caption,
      floatingLabelStyle: AppTextStyles.caption.copyWith(
        color: AppColors.navy,
        fontWeight: FontWeight.w600,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.secondary, width: 1.3),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.navy,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: AppColors.black,
        textStyle: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.deepBlue,
        minimumSize: const Size(48, 48),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.deepBlue,
        minimumSize: const Size(48, 48),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.transparent,
    ),
    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(AppColors.white),
        surfaceTintColor: WidgetStatePropertyAll(AppColors.transparent),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.deepBlue,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.white
              : AppColors.secondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTextStyles.caption.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.deepBlue
              : AppColors.secondary,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.deepBlue,
      selectedIconTheme: IconThemeData(color: AppColors.white),
      unselectedIconTheme: IconThemeData(color: AppColors.secondary),
      selectedLabelTextStyle: TextStyle(
        color: AppColors.deepBlue,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelTextStyle: TextStyle(color: AppColors.secondary),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.border, space: 28),
  );
}
