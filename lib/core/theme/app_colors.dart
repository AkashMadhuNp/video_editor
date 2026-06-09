import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF121824);
  static const Color surfaceLight = Color(0xFF1E2638);
  static const Color primary = Color(0xFF8B5CF6); // Violet
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFFEC4899); // Rose Pink
  
  static const Color textPrimary = Color(0xFFF9FAFB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);
  
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // Gradient definitions for a premium look
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0E17), Color(0xFF121824)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
