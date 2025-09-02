import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color primaryBlueDark = Color(0xFF1565C0);
  static const Color primaryBlueLight = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color lightBlue = Color(0xFF64B5F6);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF8FBFF);
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight = Color(0xFFF5F5F5);

  // Blue Tinted Colors
  static const Color blueTinted = Color(0xFFE3F2FD);
  static const Color blueAccent = Color(0xFFE1F5FE);
  static const Color blueText = Color(0xFF0277BD);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;

  // Status Colors
  static const Color error = Color(0xFFE53935);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accentBlue, lightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF42A5F5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Shadow Colors
  static Color shadowBlue = primaryBlue.withOpacity(0.1);
  static Color shadowBlueMedium = primaryBlue.withOpacity(0.2);
  static Color shadowBlueStrong = primaryBlue.withOpacity(0.3);
  static Color shadowBlueFAB = primaryBlue.withOpacity(0.4);
}
