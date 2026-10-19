import 'package:flutter/material.dart';

import 'app_colors.dart';

ShapedInputBorder _shapedInputBorder(Color color, double width) =>
    ShapedInputBorder(
      borderSide: BorderSide(color: color, width: width),
      gapPadding: 8,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: width, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(20),
      ),
    );

mixin AppTheme {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: AppColors.paypalBlue,
      onPrimary: Colors.white,
      secondary: AppColors.paypalNavy,
      onSecondary: Colors.white,
      surface: AppColors.lightBackground,
      onSurface: Colors.black,
      surfaceContainer: AppColors.lightContainer,
      surfaceContainerHigh: AppColors.lightContainerHigh,
      inverseSurface: const Color(0xFF1C1C1E),
      onInverseSurface: Colors.white,
      error: AppColors.danger,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.paypalBlue,
        foregroundColor: Colors.white,
        iconColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      floatingLabelAlignment: FloatingLabelAlignment.center,
      hintStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      focusedBorder: _shapedInputBorder(AppColors.paypalBlue, 2.6),
      border: _shapedInputBorder(AppColors.grey, 2.5),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: AppColors.paypalLightBlue,
      onPrimary: Colors.white,
      secondary: AppColors.paypalBlue,
      onSecondary: Colors.white,
      surface: AppColors.darkBackground,
      onSurface: Colors.white,
      surfaceContainer: AppColors.darkContainer,
      surfaceContainerHigh: AppColors.darkContainerHigh,
      inverseSurface: AppColors.inverseDark,
      onInverseSurface: Colors.black,
      error: AppColors.danger,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.paypalBlue,
        foregroundColor: Colors.white,
        iconColor: Colors.white,
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.darkInputFill,
      floatingLabelAlignment: FloatingLabelAlignment.center,
      hintStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      enabledBorder: _shapedInputBorder(AppColors.grey, 2.5),
      border: _shapedInputBorder(AppColors.grey, 2.5),
      focusedBorder: _shapedInputBorder(Colors.white, 5.0),
      errorBorder: _shapedInputBorder(AppColors.danger, 3.0),
      focusedErrorBorder: _shapedInputBorder(AppColors.danger, 5.0),
      errorStyle: const TextStyle(color: AppColors.danger),
    ),
  );
}
