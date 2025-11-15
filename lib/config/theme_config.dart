import 'package:flutter/material.dart';

class AppTheme {
  // ========= Color palette (from bird logo) =========
  // Core brand blues
  static const Color _brandBlue =
      Color(0xFF1F498E); // primary (deep medium blue)
  static const Color _brandBlueLight =
      Color(0xFF4A7FD4); // lighter tint for gradients/hover
  static const Color _brandBlueDark =
      Color(0xFF123069); // dark anchor for hero/depth

  // Softer base text and surfaces
  static const Color _ink = Color(0xFF1E293B); // dark navy-gray text
  static const Color _inkMuted = Color(0xFF64748B); // neutral gray for subtext
  static const Color _bg = Color(0xFFF8FAFC); // soft background
  static const Color _surface = Colors.white;
  static const Color _card = Colors.white;

  // Borders and dividers
  static const Color _outline = Color(0xFFE2E8F0);
  static const Color _divider = Color(0xFFF1F5F9);

  // Status and utility colors
  static const Color _success = Color(0xFF10B981);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _error = Color(0xFFEF4444);

  // Rewards colors
  static const Color _rewardPurple =
      Color(0xFF6366F1); // Indigo for redeem button (Material Design)
  static const Color _rewardTeal =
      Color(0xFF14B8A6); // Teal for give rewards button (vibrant, positive)

  // Gradients (brand blues)
  static const LinearGradient _brandBlueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_brandBlueLight, _brandBlue],
  );

  static const LinearGradient _heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_brandBlueDark, _brandBlue], // subtle depth across cards/hero
  );

  // ========= Aliases / legacy compatibility =========
  static const Color primaryColor = _brandBlue;
  static const Color secondaryColor = _success;
  static const Color accentColor = _ink;

  static const Color primaryTextColor = _ink;
  static const Color secondaryTextColor = _inkMuted;
  static const Color captionTextColor = Color(0xFF94A3B8);

  static const Color yellowButtonColor =
      _brandBlue; // legacy name kept; mapped to brand blue
  static const Color backgroundColor = _bg;
  static const Color surfaceColor = _surface;
  static const Color cardColor = _card;
  static const Color borderColor = _outline;
  static const Color dividerColor = _divider;

  static const Color likeColor = Color(0xFFED4956);
  static const Color successColor = _success;
  static const Color warningColor = _warning;
  static const Color errorColor = _error;

  // Rewards specific colors
  static const Color redeemButtonColor = _rewardPurple;
  static const Color giveRewardsButtonColor = _rewardTeal;

  static const LinearGradient primaryGradient = _heroGradient;
  static const LinearGradient buttonGradient = _brandBlueGradient;
  static const LinearGradient storyGradient = _heroGradient;

  // ========= ThemeData =========
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: primaryTextColor,
        background: backgroundColor,
        onBackground: primaryTextColor,
        error: errorColor,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: primaryTextColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: primaryTextColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: primaryTextColor),
      ),
      cardTheme: const CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTextColor,
          side: const BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            color: primaryTextColor, fontSize: 32, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(
            color: primaryTextColor, fontSize: 28, fontWeight: FontWeight.w800),
        displaySmall: TextStyle(
            color: primaryTextColor, fontSize: 24, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(
            color: primaryTextColor, fontSize: 22, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(
            color: primaryTextColor, fontSize: 20, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(
            color: primaryTextColor, fontSize: 18, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(
            color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
            color: primaryTextColor, fontSize: 14, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            color: primaryTextColor, fontSize: 12, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: primaryTextColor, fontSize: 16),
        bodyMedium: TextStyle(color: primaryTextColor, fontSize: 14),
        bodySmall: TextStyle(color: secondaryTextColor, fontSize: 12),
        labelLarge: TextStyle(
            color: primaryTextColor, fontSize: 14, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(
            color: secondaryTextColor,
            fontSize: 12,
            fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: captionTextColor, fontSize: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        hintStyle: const TextStyle(color: captionTextColor),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: errorColor),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: secondaryTextColor,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerColor: dividerColor,
      iconTheme: const IconThemeData(color: primaryTextColor),
    );
  }

  // ========= Helpers =========
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get gradientCardDecoration => BoxDecoration(
        gradient: primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get buttonDecoration => BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      );

  static const TextStyle buttonTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle captionStyle = TextStyle(
    color: secondaryTextColor,
    fontSize: 12,
  );

  static const TextStyle linkStyle = TextStyle(
    color: primaryColor,
    decoration: TextDecoration.underline,
    fontWeight: FontWeight.w600,
  );

  static InputDecoration getInputDecoration(String label,
      {String? hint, Widget? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
    );
  }
}
