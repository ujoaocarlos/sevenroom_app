import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // Brand Colors — Royal Blue and Sky Blue inspired by 7me
  static const Color primaryColor   = AppColors.primaryBlue; // Deep Royal Blue
  static const Color secondaryColor = AppColors.skyBlue; // Vibrant Sky Blue
  static const Color accentColor    = AppColors.skyBlue; // Sky Blue accent
  static const Color successColor   = AppColors.success;
  static const Color errorColor     = AppColors.error;
  static const Color warningColor   = AppColors.warning;

  // Neutral palette
  static const Color neutral50  = Color(0xFFF4F6F9); // Modern slate white
  static const Color neutral100 = Color(0xFFEAEFF5);
  static const Color neutral200 = Color(0xFFD4DEEC);
  static const Color neutral400 = Color(0xFF8C9DB5);
  static const Color neutral700 = Color(0xFF3E4E68);
  static const Color neutral900 = Color(0xFF1E2838);

  // ================= LIGHT THEME =================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: neutral50,
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFDDE6F5),
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0F4FF),
      surface: Colors.white,
      onSurface: neutral900,
      error: errorColor,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryColor,
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      shadowColor: Color(0x14000000),
    ),
    fontFamily: 'Montserrat',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
          color: neutral900, fontWeight: FontWeight.w800, fontFamily: 'Montserrat'),
      displayMedium: TextStyle(
          color: neutral900, fontWeight: FontWeight.w700, fontFamily: 'Montserrat'),
      titleLarge: TextStyle(
          color: neutral900, fontWeight: FontWeight.w700, fontFamily: 'Montserrat'),
      titleMedium: TextStyle(
          color: neutral900, fontWeight: FontWeight.w600, fontFamily: 'Montserrat'),
      bodyLarge: TextStyle(color: neutral900, fontFamily: 'Montserrat'),
      bodyMedium: TextStyle(color: neutral700, fontFamily: 'Montserrat'),
      labelLarge: TextStyle(
          color: neutral900, fontWeight: FontWeight.w600, fontFamily: 'Montserrat'),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(color: neutral400, fontFamily: 'Montserrat'),
      labelStyle: const TextStyle(color: neutral700, fontFamily: 'Montserrat'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neutral200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neutral200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
            fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: primaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(
            fontFamily: 'Montserrat', fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    dividerColor: neutral200,
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x0F000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: neutral200, width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: neutral100,
      selectedColor: primaryColor,
      labelStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: neutral400,
      indicatorColor: primaryColor,
      labelStyle: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: 'Montserrat'),
    ),
  );

  // ================= DARK THEME =================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: secondaryColor,
    scaffoldBackgroundColor: AppColors.darkBg,
    cardColor: AppColors.darkSurface,
    colorScheme: const ColorScheme.dark(
      primary: secondaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColor,
      secondary: secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.darkBorder,
      surface: AppColors.darkSurface,
      onSurface: Color(0xFFE2E0EC),
      error: errorColor,
      onError: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkSurface,
      foregroundColor: Color(0xFFE2E0EC),
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    fontFamily: 'Montserrat',
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Color(0xFFE2E0EC), fontWeight: FontWeight.w800),
      displayMedium: TextStyle(color: Color(0xFFE2E0EC), fontWeight: FontWeight.w700),
      titleLarge: TextStyle(color: Color(0xFFE2E0EC), fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: Color(0xFFE2E0EC), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFFE2E0EC)),
      bodyMedium: TextStyle(color: Color(0xFF9E99B5)),
      labelLarge: TextStyle(color: Color(0xFFE2E0EC), fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkSurface,
      hintStyle: const TextStyle(color: Color(0xFF6B6680), fontFamily: 'Montserrat'),
      labelStyle: const TextStyle(color: Color(0xFF9E99B5), fontFamily: 'Montserrat'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryColor, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(
            fontFamily: 'Montserrat', fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    dividerColor: AppColors.darkBorder,
    cardTheme: CardThemeData(
      color: AppColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.darkBorder, width: 1),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.darkBorder,
      selectedColor: secondaryColor,
      labelStyle: const TextStyle(fontFamily: 'Montserrat', fontSize: 13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: secondaryColor,
      unselectedLabelColor: Color(0xFF6B6680),
      indicatorColor: secondaryColor,
      labelStyle: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: 'Montserrat'),
    ),
  );
}
