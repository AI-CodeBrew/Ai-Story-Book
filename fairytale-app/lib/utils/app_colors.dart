import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF4A90E2);
  static const Color primaryDark = Color(0xFF357ABD);
  static const Color primaryLight = Color(0xFF7BB3F0);
  
  // Background colors
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Text colors
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textLight = Color(0xFF95A5A6);
  
  // Accent colors
  static const Color accent = Color(0xFFE74C3C);
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  
  // Theme-specific colors
  static const Color adventure = Color(0xFF8E44AD);
  static const Color fantasy = Color(0xFF9B59B6);
  static const Color space = Color(0xFF34495E);
  static const Color nature = Color(0xFF27AE60);
  static const Color friendship = Color(0xFFF39C12);
  static const Color science = Color(0xFF3498DB);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, Color(0xFFE8F4FD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
