import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary emerald palette
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF1B7A4E);
  static const emerald800 = Color(0xFF065F46);
  static const emerald900 = Color(0xFF064E3B);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const grey25 = Color(0xFFF9FAFB); // Very light grey for slight contrast
  static const grey50 = Color(0xFFF3F4F6);
  static const grey100 = Color(0xFFF3F4F6); // Lighter for subtle borders
  static const grey200 = Color(0xFFE5E7EB);
  static const grey300 = Color(0xFFD1D5DB);
  static const grey400 = Color(0xFF9CA3AF);
  static const grey500 = Color(0xFF6B7280);
  static const grey600 = Color(0xFF4B5563);
  static const grey700 = Color(0xFF374151);
  static const grey800 = Color(0xFF1F2937);
  static const grey900 = Color(0xFF111827);

  // Score badge colors
  static const eagle = Color(0xFFF59E0B);     // Amber/gold
  static const birdie = Color(0xFF3B82F6);    // Blue
  static const par = Color(0xFF10B981);       // Emerald
  static const bogey = Color(0xFFF97316);     // Orange
  static const doubleBogey = Color(0xFFEF4444); // Red
  static const worse = Color(0xFF991B1B);     // Dark red
  
  // Fancy accents
  static const Color golfLime = Color(0xFFA3E635); // Vibrant Golf Lime (Lime 400)
  static const golfBrown = Color(0xFF8B5E3C); // Brown for activity/course
  static const golfSand = Color(0xFFC2B280);  // Sand for views/visibility
  static const golfSky = Color(0xFF0EA5E9);   // Sky Blue for contacts
  static const golfPurple = Color(0xFFA855F7); // Purple for conversion
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue900 = Color(0xFF1E3A8A);
  
  static const purple50 = Color(0xFFFAF5FF);
  static const purple100 = Color(0xFFF3E8FF);
  static const purple600 = Color(0xFF9333EA);
  static const purple700 = Color(0xFF7E22CE);
  static const purple900 = Color(0xFF581C87);
  
  static const orange50 = Color(0xFFFFF7ED);
  static const scaffoldBackground = Color(0xFFFFFFFF); // Pure white as requested
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.interTextTheme();
    final Color bgColor = isDark ? AppColors.grey900 : AppColors.scaffoldBackground;
    final Color surfaceColor = isDark ? AppColors.grey800 : AppColors.white;
    final Color textColor = isDark ? AppColors.white : AppColors.grey900;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bgColor,
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.grey800 : AppColors.grey100,
        thickness: 1,
        space: 1,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.emerald700,
        primary: AppColors.emerald700,
        onPrimary: AppColors.white,
        secondary: AppColors.golfLime,
        onSecondary: AppColors.grey900,
        surface: isDark ? AppColors.grey800 : AppColors.white,
        onSurface: isDark ? AppColors.white : AppColors.grey900,
        error: AppColors.doubleBogey,
        onError: AppColors.white,
        brightness: brightness,
      ),
      textTheme: textTheme.apply(
        bodyColor: isDark ? AppColors.grey100 : AppColors.grey900,
        displayColor: isDark ? AppColors.white : AppColors.grey900,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: textColor,
          fontSize: 18,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? AppColors.grey800 : AppColors.grey100, width: 1),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.grey800 : AppColors.white,
        selectedItemColor: AppColors.emerald700,
        unselectedItemColor: AppColors.grey500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald700,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: isDark ? AppColors.grey800 : AppColors.grey100,
          disabledForegroundColor: isDark ? AppColors.grey400 : AppColors.grey500,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.emerald700,
          side: const BorderSide(color: AppColors.emerald700, width: 2),
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.golfLime : AppColors.emerald700,
          disabledForegroundColor: AppColors.grey500,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
