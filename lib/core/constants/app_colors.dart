import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Color(0xFFFF4D94);
  static const Color primaryLight = Color(0xFFFF80B3);
  static const Color primaryDark = Color(0xFFE0005C);

  // Secondary
  static const Color secondary = Color(0xFFFF80B3);

  // Background
  static const Color background = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2A2A2A);

  // Status Colors
  static const Color success = Color(0xFF28C76F);
  static const Color warning = Color(0xFFFF9F43);
  static const Color danger = Color(0xFFEA5455);
  static const Color info = Color(0xFF00CFE8);

  // Text
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textHint = Color(0xFFA0AEC0);
  static const Color textDark = Color(0xFFF7FAFC);
  static const Color textSecondaryDark = Color(0xFFCBD5E0);

  // Gradient
  static const List<Color> primaryGradient = [
    Color(0xFFFF4D94),
    Color(0xFFFF80B3),
  ];

  static const List<Color> incomeGradient = [
    Color(0xFF28C76F),
    Color(0xFF48DA89),
  ];

  static const List<Color> expenseGradient = [
    Color(0xFFEA5455),
    Color(0xFFF08182),
  ];

  static const List<Color> savingsGradient = [
    Color(0xFF00CFE8),
    Color(0xFF1CE7FF),
  ];

  // Chart Colors
  static const List<Color> chartColors = [
    Color(0xFFFF4D94),
    Color(0xFF28C76F),
    Color(0xFF00CFE8),
    Color(0xFFFF9F43),
    Color(0xFFEA5455),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF5722),
    Color(0xFF607D8B),
    Color(0xFFE91E63),
    Color(0xFF4CAF50),
  ];

  // Divider
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF2D2D2D);

  // Shadow
  static Color shadowColor = const Color(0xFFFF4D94).withOpacity(0.15);

  // Overlay
  static Color overlay = Colors.black.withOpacity(0.5);
}
